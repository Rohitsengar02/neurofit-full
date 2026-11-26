// Helpers around the generic `docs` table.
const crypto = require('crypto');
const { query, one } = require('../db');
const cache = require('./cache');

const newId = (prefix = 'id') => `${prefix}_${Date.now().toString(36)}${crypto.randomBytes(4).toString('hex')}`;

// Fields the server owns; never stored inside `data`.
const META = new Set(['_id', 'createdAt', 'updatedAt']);

const safeKey = (k) => String(k).replace(/[^a-zA-Z0-9_]/g, '');

function toItem(row, idField = 'id') {
  if (!row) return null;
  const d = row.data || {};
  const out = { ...d };
  out[idField] = row.id;
  if (out.id === undefined || out.id === null || out.id === '') out.id = row.id;
  out._id = row.id;
  if (out.sortOrder === undefined) out.sortOrder = row.sort_order;
  if (out.displayOrder === undefined) out.displayOrder = row.sort_order;
  out.createdAt = row.created_at instanceof Date ? row.created_at.toISOString() : row.created_at;
  out.updatedAt = row.updated_at instanceof Date ? row.updated_at.toISOString() : row.updated_at;
  if (row.owner_id && out.ownerId === undefined) out.ownerId = row.owner_id;
  return out;
}

function clean(body) {
  const data = {};
  for (const [k, v] of Object.entries(body || {})) if (!META.has(k)) data[k] = v;
  return data;
}

function sortValue(body, fallback) {
  const v = body.sortOrder ?? body.displayOrder ?? body.order ?? body.position;
  const n = Number(v);
  return v !== undefined && v !== null && v !== '' && Number.isFinite(n) ? n : fallback;
}

/**
 * List items with optional exact-match filters on data fields.
 */
async function list(collection, { filters = {}, ownerId, search, searchFields = ['name', 'title'], order = 'sort', limit = 1000, offset = 0 } = {}) {
  const where = ['collection = $1'];
  const params = [collection];
  if (ownerId !== undefined) {
    params.push(ownerId);
    where.push(`owner_id = $${params.length}`);
  }
  for (const [k, v] of Object.entries(filters)) {
    if (v === undefined || v === null || v === '') continue;
    params.push(String(v));
    where.push(`data->>'${safeKey(k)}' = $${params.length}`);
  }
  if (search) {
    params.push(`%${String(search).toLowerCase()}%`);
    const p = `$${params.length}`;
    where.push('(' + searchFields.map((f) => `lower(data->>'${safeKey(f)}') LIKE ${p}`).join(' OR ') + ')');
  }
  const orderBy = order === 'new' ? 'created_at DESC' : order === 'updated' ? 'updated_at DESC' : 'sort_order ASC, created_at ASC';
  params.push(Math.min(Number(limit) || 1000, 5000));
  params.push(Number(offset) || 0);
  const sql = `SELECT * FROM docs WHERE ${where.join(' AND ')} ORDER BY ${orderBy} LIMIT $${params.length - 1} OFFSET $${params.length}`;
  return (await query(sql, params)).rows;
}

async function get(collection, id) {
  return one('SELECT * FROM docs WHERE collection = $1 AND id = $2', [collection, String(id)]);
}

/** Find by the row id, or by one of the id-like fields inside data. */
async function find(collection, id, fields = ['id', 'sectionId', 'bannerId', 'categoryId', 'orderId', 'discountId', 'planId', 'itemId', 'exerciseId']) {
  const direct = await get(collection, id);
  if (direct) return direct;
  const ors = fields.map((f) => `data->>'${safeKey(f)}' = $2`).join(' OR ');
  return one(`SELECT * FROM docs WHERE collection = $1 AND (${ors}) LIMIT 1`, [collection, String(id)]);
}

async function upsert(collection, id, body, { ownerId = null, merge = true } = {}) {
  const data = clean(body);
  const existing = await get(collection, id);
  let row;
  if (existing) {
    const next = merge ? { ...existing.data, ...data } : data;
    row = await one(
      `UPDATE docs SET data = $3, sort_order = $4, updated_at = now(), rev = nextval('rev_seq'),
         owner_id = COALESCE(owner_id, $5)
       WHERE collection = $1 AND id = $2 RETURNING *`,
      [collection, String(id), next, sortValue(body, existing.sort_order), ownerId]
    );
  } else {
    let sort = sortValue(body, null);
    if (sort === null) {
      const m = await one('SELECT COALESCE(MAX(sort_order), 0) + 1 AS n FROM docs WHERE collection = $1', [collection]);
      sort = m.n;
    }
    row = await one(
      `INSERT INTO docs (collection, id, owner_id, data, sort_order) VALUES ($1, $2, $3, $4, $5)
       ON CONFLICT (collection, id) DO UPDATE SET data = docs.data || EXCLUDED.data, updated_at = now(), rev = nextval('rev_seq')
       RETURNING *`,
      [collection, String(id), ownerId, data, sort]
    );
  }
  await cache.bump(collection);
  return row;
}

async function remove(collection, id) {
  const r = await query('DELETE FROM docs WHERE collection = $1 AND id = $2', [collection, String(id)]);
  // Firestore-style sub-collections are stored as "<collection>/<id>/<sub>".
  await query('DELETE FROM docs WHERE collection LIKE $1', [`${collection}/${id}/%`]);
  await cache.bump(collection);
  return r.rowCount;
}

async function setSort(collection, pairs) {
  for (const { id, sort } of pairs) {
    await query(
      `UPDATE docs SET sort_order = $3, data = data || jsonb_build_object('sortOrder', $3::float8, 'displayOrder', $3::float8),
         updated_at = now(), rev = nextval('rev_seq')
       WHERE collection = $1 AND (id = $2 OR data->>'id' = $2 OR data->>'sectionId' = $2 OR data->>'bannerId' = $2)`,
      [collection, String(id), Number(sort)]
    );
  }
  await cache.bump(collection);
}

module.exports = { newId, toItem, clean, list, get, find, upsert, remove, setSort, safeKey };
