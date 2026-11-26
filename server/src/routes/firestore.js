// Firestore REST compatibility layer.
// Older screens in both apps still call firestore.googleapis.com directly.
// The apps now send those calls here (/fs/v1/...), and they read and write the
// same Postgres `docs` rows as the REST API, so there is one source of truth.
const express = require('express');
const docs = require('../lib/docs');
const { query } = require('../db');
const { isAdmin } = require('../lib/auth');

const router = express.Router();

const DOUBLE_FIELDS = new Set(['price', 'regularPrice', 'salePrice', 'monthlyPrice', 'yearlyPrice', 'rating', 'value', 'minOrderValue', 'maxDiscount', 'discountValue', 'amount', 'totalAmount', 'subtotal']);
// Firestore collection name -> docs collection (when the REST API uses another name)
const ALIAS = {};
const USER_WRITABLE = new Set(['orders']);
const PRIVATE = new Set(['users', 'orders', 'messages', 'trainer_subscriptions', 'checkins', 'bookings', 'notifications']);

function fromFs(v) {
  if (!v || typeof v !== 'object') return null;
  if ('stringValue' in v) return v.stringValue;
  if ('integerValue' in v) return Number(v.integerValue);
  if ('doubleValue' in v) return Number(v.doubleValue);
  if ('booleanValue' in v) return !!v.booleanValue;
  if ('nullValue' in v) return null;
  if ('timestampValue' in v) return v.timestampValue;
  if ('referenceValue' in v) return v.referenceValue;
  if ('geoPointValue' in v) return v.geoPointValue;
  if ('arrayValue' in v) return ((v.arrayValue && v.arrayValue.values) || []).map(fromFs);
  if ('mapValue' in v) return fieldsToPlain((v.mapValue && v.mapValue.fields) || {});
  return null;
}
const fieldsToPlain = (f) => Object.fromEntries(Object.entries(f || {}).map(([k, v]) => [k, fromFs(v)]));

function toFs(key, v) {
  if (v === null || v === undefined) return { nullValue: null };
  if (typeof v === 'boolean') return { booleanValue: v };
  if (typeof v === 'number') return DOUBLE_FIELDS.has(key) || !Number.isInteger(v) ? { doubleValue: v } : { integerValue: String(v) };
  if (Array.isArray(v)) return { arrayValue: { values: v.map((x) => toFs(key, x)) } };
  if (typeof v === 'object') return { mapValue: { fields: plainToFields(v) } };
  return { stringValue: String(v) };
}
const plainToFields = (o) => Object.fromEntries(Object.entries(o || {}).filter(([k]) => k !== '_id').map(([k, v]) => [k, toFs(k, v)]));

function fsDoc(collection, row, project) {
  const plain = { ...row.data };
  return {
    name: `projects/${project}/databases/(default)/documents/${collection}/${row.id}`,
    fields: plainToFields(plain),
    createTime: row.created_at.toISOString(),
    updateTime: row.updated_at.toISOString(),
  };
}

function split(path) {
  const parts = path.split('/').filter(Boolean).map(decodeURIComponent);
  const isCollection = parts.length % 2 === 1;
  const collection = (isCollection ? parts : parts.slice(0, -1)).join('/');
  const top = parts[0];
  return { parts, isCollection, collection: ALIAS[collection] || collection, top, id: isCollection ? null : parts[parts.length - 1] };
}

const canRead = (req, top) => !PRIVATE.has(top) || isAdmin(req);
const canWrite = (req, top) => isAdmin(req) || (req.user && USER_WRITABLE.has(top));

async function runQuery(req, res, parentPath) {
  const sq = (req.body && req.body.structuredQuery) || {};
  const from = (sq.from && sq.from[0] && sq.from[0].collectionId) || '';
  const collection = [parentPath, from].filter(Boolean).join('/');
  const top = collection.split('/')[0];
  const filters = [];
  const collect = (w) => {
    if (!w) return;
    if (w.fieldFilter) filters.push(w.fieldFilter);
    if (w.compositeFilter) (w.compositeFilter.filters || []).forEach(collect);
  };
  collect(sq.where);
  const params = [collection];
  const where = ['collection = $1'];
  for (const f of filters) {
    const path = docs.safeKey(f.field && f.field.fieldPath);
    const val = fromFs(f.value);
    if (f.op === 'EQUAL') { params.push(String(val)); where.push(`data->>'${path}' = $${params.length}`); }
    else if (f.op === 'ARRAY_CONTAINS') { params.push(JSON.stringify({ [path]: [val] })); where.push(`data @> $${params.length}::jsonb`); }
  }
  // Non-admins only see their own private rows (e.g. their orders).
  if (PRIVATE.has(top) && !isAdmin(req)) {
    if (!req.user) return res.json([]);
    params.push(req.user.id);
    where.push(`owner_id = $${params.length}`);
  }
  const limit = Math.min(Number(sq.limit && (sq.limit.value || sq.limit)) || 500, 2000);
  const desc = sq.orderBy && sq.orderBy[0] && sq.orderBy[0].direction === 'DESCENDING';
  const { rows } = await query(`SELECT * FROM docs WHERE ${where.join(' AND ')} ORDER BY created_at ${desc ? 'DESC' : 'ASC'} LIMIT ${limit}`, params);
  if (!rows.length) return res.json([{ readTime: new Date().toISOString() }]);
  res.json(rows.map((r) => ({ document: fsDoc(collection, r, req.params.project), readTime: new Date().toISOString() })));
}

router.all(/^\/v1\/projects\/([^/]+)\/databases\/[^/]+\/documents(.*)$/, async (req, res) => {
  req.params.project = req.params[0];
  let path = req.params[1] || '';
  if (path.endsWith(':runQuery')) return runQuery(req, res, path.slice(0, -':runQuery'.length).replace(/^\/+/, ''));
  path = path.replace(/^\/+/, '');
  if (!path) return res.status(404).json({ error: { code: 404, message: 'Not found' } });
  const { isCollection, collection, top, id } = split(path);
  const project = req.params.project;
  const body = req.body || {};
  const fields = body.fields ? fieldsToPlain(body.fields) : {};

  if (isCollection) {
    if (req.method === 'GET') {
      if (!canRead(req, top)) return res.json({});
      const limit = Math.min(Number(req.query.pageSize) || 1000, 2000);
      const rows = await docs.list(collection, { limit, ownerId: PRIVATE.has(top) && !isAdmin(req) ? req.user && req.user.id : undefined });
      return res.json(rows.length ? { documents: rows.map((r) => fsDoc(collection, r, project)) } : {});
    }
    if (req.method === 'POST') {
      if (!canWrite(req, top)) return res.status(403).json({ error: { code: 403, message: 'Permission denied' } });
      const newId = String(req.query.documentId || docs.newId('doc'));
      const row = await docs.upsert(collection, newId, fields, { ownerId: isAdmin(req) ? null : req.user.id, merge: false });
      return res.json(fsDoc(collection, row, project));
    }
    return res.status(405).json({ error: { code: 405, message: 'Method not allowed' } });
  }

  if (req.method === 'GET') {
    const row = canRead(req, top) ? await docs.get(collection, id) : null;
    if (!row || (PRIVATE.has(top) && !isAdmin(req) && row.owner_id !== (req.user && req.user.id))) {
      return res.status(404).json({ error: { code: 404, message: 'Document not found', status: 'NOT_FOUND' } });
    }
    return res.json(fsDoc(collection, row, project));
  }
  if (req.method === 'PATCH') {
    if (!canWrite(req, top)) return res.status(403).json({ error: { code: 403, message: 'Permission denied' } });
    const masks = [].concat(req.query['updateMask.fieldPaths'] || []);
    const existing = await docs.get(collection, id);
    if (existing && !isAdmin(req) && existing.owner_id !== req.user.id) return res.status(403).json({ error: { code: 403, message: 'Permission denied' } });
    let next;
    if (masks.length && existing) {
      next = { ...existing.data };
      for (const m of masks) { if (m in fields) next[m] = fields[m]; else delete next[m]; }
    } else {
      next = fields;
    }
    const row = await docs.upsert(collection, id, next, { ownerId: isAdmin(req) ? null : req.user.id, merge: false });
    return res.json(fsDoc(collection, row, project));
  }
  if (req.method === 'DELETE') {
    if (!isAdmin(req)) return res.status(403).json({ error: { code: 403, message: 'Permission denied' } });
    await docs.remove(collection, id);
    return res.json({});
  }
  return res.status(405).json({ error: { code: 405, message: 'Method not allowed' } });
});

module.exports = { router, fieldsToPlain, plainToFields };
