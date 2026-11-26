// Offline sync for everything the phone stores in SQLite.
//
// The phone keeps an outbox of changed records. When online it:
//   POST /api/sync/push  { changes: [{ collection, id, data, deleted, updatedAt }] }
//   GET  /api/sync/pull?since=<cursor>
// Conflicts: last write wins, by the time the change was made on the device.
// The cursor is a server-side revision number, so nothing is missed even if
// device clocks are wrong.
const express = require('express');
const { query, one } = require('../db');
const { requireAuth } = require('../lib/auth');

const router = express.Router();

const MAX_BATCH = 500;
const MAX_RECORD_BYTES = 256 * 1024;
const COLLECTION_RE = /^[a-z0-9_.-]{1,64}$/i;

router.post('/push', requireAuth, async (req, res) => {
  const changes = Array.isArray(req.body.changes) ? req.body.changes.slice(0, MAX_BATCH) : [];
  const accepted = [];
  const rejected = [];
  const cols = [], ids = [], datas = [], dels = [], times = [];
  for (const c of changes) {
    const collection = String(c.collection || '');
    const id = String(c.id || '');
    if (!COLLECTION_RE.test(collection) || !id || id.length > 200) { rejected.push({ collection, id, reason: 'invalid' }); continue; }
    const data = c.data && typeof c.data === 'object' ? c.data : {};
    if (JSON.stringify(data).length > MAX_RECORD_BYTES) { rejected.push({ collection, id, reason: 'too_large' }); continue; }
    const t = new Date(c.updatedAt || Date.now());
    cols.push(collection); ids.push(id); datas.push(JSON.stringify(data)); dels.push(!!c.deleted);
    times.push(Number.isNaN(t.getTime()) ? new Date().toISOString() : new Date(Math.min(t.getTime(), Date.now() + 60_000)).toISOString());
    accepted.push({ collection, id });
  }
  if (cols.length) {
    await query(
      `INSERT INTO user_records (user_id, collection, id, data, deleted, client_updated_at)
       SELECT $1, c, i, d::jsonb, del, t::timestamptz
       FROM unnest($2::text[], $3::text[], $4::text[], $5::bool[], $6::text[]) AS x(c, i, d, del, t)
       ON CONFLICT (user_id, collection, id) DO UPDATE
         SET data = EXCLUDED.data, deleted = EXCLUDED.deleted,
             client_updated_at = EXCLUDED.client_updated_at, rev = nextval('rev_seq')
         WHERE user_records.client_updated_at <= EXCLUDED.client_updated_at`,
      [req.user.id, cols, ids, datas, dels, times]
    );
  }
  const cur = await one('SELECT COALESCE(MAX(rev), 0) AS rev FROM user_records WHERE user_id = $1', [req.user.id]);
  res.json({ success: true, accepted: accepted.length, rejected, cursor: cur.rev });
});

router.get('/pull', requireAuth, async (req, res) => {
  const since = Number(req.query.since) || 0;
  const limit = Math.min(Number(req.query.limit) || 1000, 2000);
  const params = [req.user.id, since, limit + 1];
  let filter = '';
  if (req.query.collections) {
    params.push(String(req.query.collections).split(',').filter(Boolean));
    filter = `AND collection = ANY($${params.length}::text[])`;
  }
  const { rows } = await query(
    `SELECT collection, id, data, deleted, client_updated_at, rev FROM user_records
     WHERE user_id = $1 AND rev > $2 ${filter} ORDER BY rev ASC LIMIT $3`,
    params
  );
  const hasMore = rows.length > limit;
  const page = hasMore ? rows.slice(0, limit) : rows;
  res.json({
    success: true,
    changes: page.map((r) => ({ collection: r.collection, id: r.id, data: r.data, deleted: r.deleted, updatedAt: r.client_updated_at.toISOString(), rev: r.rev })),
    cursor: page.length ? page[page.length - 1].rev : since,
    hasMore,
  });
});

// Read one collection of the signed-in user (handy for the web build).
router.get('/records/:collection', requireAuth, async (req, res) => {
  const { rows } = await query(
    `SELECT id, data, client_updated_at FROM user_records WHERE user_id = $1 AND collection = $2 AND NOT deleted ORDER BY client_updated_at DESC LIMIT 2000`,
    [req.user.id, req.params.collection]
  );
  res.json({ success: true, data: rows.map((r) => ({ id: r.id, ...r.data, updatedAt: r.client_updated_at })) });
});

module.exports = { router };
