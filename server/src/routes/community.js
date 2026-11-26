// Community feed: posts (photo, before/after, workout, poll, text), likes,
// saves, poll votes, comments, reports. Admin can moderate.
const express = require('express');
const { notify } = require('./notifications');
const { query, one } = require('../db');
const docs = require('../lib/docs');
const { requireAuth, requireAdmin, isAdmin, optionalAuth } = require('../lib/auth');
const cache = require('../lib/cache');

const router = express.Router();
const KINDS = ['photo', 'beforeAfter', 'workout', 'poll', 'text'];

async function decorate(rows, meId) {
  if (!rows.length) return [];
  const ids = rows.map((r) => r.id);
  const targets = ids.map((i) => `post:${i}`);
  const [counts, mine, comments] = await Promise.all([
    query(`SELECT target_id, kind, count(*)::int AS n FROM reactions WHERE target_id = ANY($1) GROUP BY target_id, kind`, [targets]),
    meId ? query(`SELECT target_id, kind FROM reactions WHERE target_id = ANY($1) AND user_id = $2`, [targets, meId]) : { rows: [] },
    query(`SELECT data->>'postId' AS pid, count(*)::int AS n FROM docs WHERE collection = 'comments' AND data->>'postId' = ANY($1) GROUP BY 1`, [ids]),
  ]);
  const c = {}; for (const r of counts.rows) (c[r.target_id] ||= {})[r.kind] = r.n;
  const m = {}; for (const r of mine.rows) (m[r.target_id] ||= new Set()).add(r.kind);
  const cc = {}; for (const r of comments.rows) cc[r.pid] = r.n;
  return rows.map((row) => {
    const p = docs.toItem(row);
    const t = `post:${row.id}`;
    const my = m[t] || new Set();
    const options = Array.isArray(p.options) ? p.options : [];
    const votes = options.map((_, i) => (c[t] || {})[`vote:${i}`] || 0);
    let myVote = null;
    options.forEach((_, i) => { if (my.has(`vote:${i}`)) myVote = i; });
    return {
      ...p, id: row.id, authorId: row.owner_id,
      mine: !!meId && row.owner_id === meId,
      likes: (c[t] || {}).like || 0, liked: my.has('like'), saved: my.has('save'), tried: my.has('try'), reported: my.has('report'),
      reports: (c[t] || {}).report || 0,
      votes, myVote, commentsCount: cc[row.id] || 0,
    };
  });
}

router.get('/posts', optionalAuth, async (req, res) => {
  const limit = Math.min(Number(req.query.limit) || 20, 50);
  const params = [limit];
  const where = [`collection = 'posts'`, `COALESCE(data->>'hidden','false') <> 'true'`];
  if (req.query.before) { params.push(req.query.before); where.push(`created_at < $${params.length}::timestamptz`); }
  if (req.query.kind && KINDS.includes(req.query.kind)) { params.push(req.query.kind); where.push(`data->>'kind' = $${params.length}`); }
  if (req.query.tag) { params.push(JSON.stringify({ tags: [req.query.tag] })); where.push(`data @> $${params.length}::jsonb`); }
  if (req.query.author) { params.push(req.query.author); where.push(`owner_id = $${params.length}`); }
  if (req.query.filter === 'mine' && req.user) { params.push(req.user.id); where.push(`owner_id = $${params.length}`); }
  if (req.query.filter === 'saved' && req.user) { params.push(req.user.id); where.push(`'post:' || id IN (SELECT target_id FROM reactions WHERE user_id = $${params.length} AND kind = 'save')`); }
  const { rows } = await query(`SELECT * FROM docs WHERE ${where.join(' AND ')} ORDER BY created_at DESC LIMIT $1`, params);
  const data = await decorate(rows, req.user && req.user.id);
  res.json({ success: true, data, next: rows.length === limit ? rows[rows.length - 1].created_at : null });
});

router.post('/posts', requireAuth, async (req, res) => {
  const b = req.body || {};
  const me = await one('SELECT name, photo_url, role FROM users WHERE id = $1', [req.user.id]);
  if (!me) return res.status(401).json({ success: false, message: 'Sign in again' });
  const kind = KINDS.includes(b.kind) ? b.kind : 'text';
  const text = String(b.text || '').slice(0, 5000);
  const pics = (Array.isArray(b.pics) ? b.pics : []).map(String).filter((u) => /^https?:\/\//.test(u)).slice(0, 4);
  if (!text && !pics.length && kind !== 'poll') return res.status(400).json({ success: false, message: 'Post is empty' });
  const id = String(b.id || docs.newId('post'));
  const existing = await docs.get('posts', id);
  if (existing && existing.owner_id !== req.user.id) return res.status(409).json({ success: false, message: 'Post id clash' });
  const handle = '@' + (me.name || 'athlete').toLowerCase().replace(/[^a-z0-9]+/g, '').slice(0, 20);
  const row = await docs.upsert('posts', id, {
    kind, text, pics, name: me.name, handle, avatarUrl: me.photo_url, coach: me.role === 'trainer',
    stat: b.stat || null, workoutTitle: b.workoutTitle || null, exercises: Array.isArray(b.exercises) ? b.exercises.slice(0, 20) : [],
    options: kind === 'poll' ? (Array.isArray(b.options) ? b.options.map(String).slice(0, 6) : []) : [],
    tags: Array.isArray(b.tags) ? b.tags.map(String).slice(0, 10) : [],
  }, { ownerId: req.user.id });
  res.status(201).json({ success: true, data: (await decorate([row], req.user.id))[0] });
});

router.delete('/posts/:id', requireAuth, async (req, res) => {
  const row = await docs.get('posts', req.params.id);
  if (!row) return res.json({ success: true });
  if (row.owner_id !== req.user.id && !isAdmin(req)) return res.status(403).json({ success: false, message: 'Not allowed' });
  await docs.remove('posts', row.id);
  await query(`DELETE FROM docs WHERE collection = 'comments' AND data->>'postId' = $1`, [row.id]);
  await query(`DELETE FROM reactions WHERE target_id = $1`, [`post:${row.id}`]);
  res.json({ success: true });
});

async function toggle(req, res, kind) {
  const target = `post:${req.params.id}`;
  const del = await query(`DELETE FROM reactions WHERE target_id = $1 AND user_id = $2 AND kind = $3`, [target, req.user.id, kind]);
  // explicit state from offline replays: { on: true|false }
  const want = req.body && req.body.on !== undefined ? !!req.body.on : !del.rowCount;
  if (want) await query(`INSERT INTO reactions (target_id, user_id, kind) VALUES ($1, $2, $3) ON CONFLICT DO NOTHING`, [target, req.user.id, kind]);
  const n = await one(`SELECT count(*)::int AS n FROM reactions WHERE target_id = $1 AND kind = $2`, [target, kind]);
  res.json({ success: true, on: want, count: n.n });
}
router.post('/posts/:id/like', requireAuth, (req, res) => toggle(req, res, 'like'));
router.post('/posts/:id/save', requireAuth, (req, res) => toggle(req, res, 'save'));
router.post('/posts/:id/try', requireAuth, (req, res) => toggle(req, res, 'try'));
router.post('/posts/:id/report', requireAuth, async (req, res) => {
  await query(`INSERT INTO reactions (target_id, user_id, kind) VALUES ($1, $2, 'report') ON CONFLICT DO NOTHING`, [`post:${req.params.id}`, req.user.id]);
  const n = await one(`SELECT count(*)::int AS n FROM reactions WHERE target_id = $1 AND kind = 'report'`, [`post:${req.params.id}`]);
  if (n.n >= 5) await docs.upsert('posts', req.params.id, { hidden: true, hiddenReason: 'reports' });
  const post = await docs.get('posts', req.params.id);
  const me = await one('SELECT name FROM users WHERE id = $1', [req.user.id]);
  // one open case per post; each new report bumps its count
  const caseId = `rep_post_${req.params.id}`;
  const existing = await docs.get('reports', caseId);
  await docs.upsert('reports', caseId, {
    category: 'Community Post', targetType: 'post', targetId: req.params.id,
    title: (req.body && req.body.reason) || (existing && existing.data.title) || 'Reported community post',
    description: post ? String(post.data.text || post.data.caption || '').slice(0, 300) : '',
    reported: post ? `${post.data.authorName || 'User'} (post)` : 'Deleted post', reportedId: post ? post.owner_id : null,
    reporter: existing ? existing.data.reporter : (me ? me.name : 'User'), reporterId: existing ? existing.data.reporterId : req.user.id,
    count: n.n, status: existing && existing.data.status === 'resolved' && n.n <= (existing.data.count || 0) ? 'resolved' : 'open',
    autoHidden: n.n >= 5,
  });
  await cache.bump('reports');
  res.json({ success: true });
});

// Any other complaint from the app (a coach, an order, a user).
router.post('/reports', requireAuth, async (req, res) => {
  const b = req.body || {};
  const me = await one('SELECT name FROM users WHERE id = $1', [req.user.id]);
  const row = await docs.upsert('reports', b.id || docs.newId('rep'), {
    category: String(b.category || 'General').slice(0, 60), title: String(b.title || 'Report').slice(0, 140), description: String(b.description || '').slice(0, 2000),
    targetType: b.targetType || null, targetId: b.targetId || null, reported: String(b.reported || '').slice(0, 120),
    reporter: me ? me.name : 'User', reporterId: req.user.id, count: 1, status: 'open', evidence: Array.isArray(b.evidence) ? b.evidence.slice(0, 10) : [],
  }, { ownerId: req.user.id });
  await cache.bump('reports');
  notify({ audience: 'admins', title: 'New report', body: row.data.title, type: 'report', refId: row.id }).catch(() => {});
  res.status(201).json({ success: true, data: docs.toItem(row) });
});

router.post('/posts/:id/vote', requireAuth, async (req, res) => {
  const row = await docs.get('posts', req.params.id);
  if (!row || row.data.kind !== 'poll') return res.status(404).json({ success: false, message: 'Poll not found' });
  const i = Number(req.body.option);
  if (!Number.isInteger(i) || i < 0 || i >= (row.data.options || []).length) return res.status(400).json({ success: false, message: 'Bad option' });
  const target = `post:${row.id}`;
  await query(`DELETE FROM reactions WHERE target_id = $1 AND user_id = $2 AND kind LIKE 'vote:%'`, [target, req.user.id]);
  await query(`INSERT INTO reactions (target_id, user_id, kind) VALUES ($1, $2, $3)`, [target, req.user.id, `vote:${i}`]);
  res.json({ success: true, data: (await decorate([row], req.user.id))[0] });
});

router.get('/posts/:id/comments', optionalAuth, async (req, res) => {
  const { rows } = await query(`SELECT * FROM docs WHERE collection = 'comments' AND data->>'postId' = $1 ORDER BY created_at ASC LIMIT 300`, [req.params.id]);
  const ids = rows.map((r) => `comment:${r.id}`);
  const likes = ids.length ? (await query(`SELECT target_id, count(*)::int AS n, bool_or(user_id = $2) AS mine FROM reactions WHERE target_id = ANY($1) AND kind = 'like' GROUP BY target_id`, [ids, req.user ? req.user.id : ''])).rows : [];
  const L = Object.fromEntries(likes.map((l) => [l.target_id, l]));
  res.json({ success: true, data: rows.map((r) => ({ ...docs.toItem(r), mine: !!req.user && r.owner_id === req.user.id, likes: (L[`comment:${r.id}`] || {}).n || 0, liked: !!(L[`comment:${r.id}`] || {}).mine })) });
});

router.post('/posts/:id/comments', requireAuth, async (req, res) => {
  const text = String(req.body.text || '').trim().slice(0, 2000);
  if (!text) return res.status(400).json({ success: false, message: 'Empty comment' });
  const me = await one('SELECT name, photo_url FROM users WHERE id = $1', [req.user.id]);
  const row = await docs.upsert('comments', String(req.body.id || docs.newId('cmt')), { postId: req.params.id, text, name: me ? me.name : 'Member', avatarUrl: me ? me.photo_url : '' }, { ownerId: req.user.id });
  res.status(201).json({ success: true, data: { ...docs.toItem(row), mine: true, likes: 0, liked: false } });
});

router.post('/comments/:id/like', requireAuth, async (req, res) => {
  const target = `comment:${req.params.id}`;
  const del = await query(`DELETE FROM reactions WHERE target_id = $1 AND user_id = $2 AND kind = 'like'`, [target, req.user.id]);
  if (!del.rowCount) await query(`INSERT INTO reactions (target_id, user_id, kind) VALUES ($1, $2, 'like') ON CONFLICT DO NOTHING`, [target, req.user.id]);
  res.json({ success: true, on: !del.rowCount });
});

router.delete('/comments/:id', requireAuth, async (req, res) => {
  const row = await docs.get('comments', req.params.id);
  if (row && (row.owner_id === req.user.id || isAdmin(req))) await docs.remove('comments', row.id);
  res.json({ success: true });
});

// ---------- admin moderation ----------
router.get('/admin/reported', requireAdmin, async (_req, res) => {
  const { rows } = await query(
    `SELECT d.* FROM docs d JOIN (SELECT target_id, count(*) AS n FROM reactions WHERE kind = 'report' GROUP BY target_id) r ON r.target_id = 'post:' || d.id
     WHERE d.collection = 'posts' ORDER BY r.n DESC LIMIT 200`);
  res.json({ success: true, data: await decorate(rows, null) });
});

router.get('/admin/reports', requireAdmin, async (_req, res) => {
  const rows = await docs.list('reports', { order: 'new', limit: 500 });
  res.json({ success: true, data: rows.map((r) => docs.toItem(r)) });
});

router.patch('/admin/reports/:id', requireAdmin, async (req, res) => {
  const row = await docs.get('reports', req.params.id);
  if (!row) return res.status(404).json({ success: false, message: 'Report not found' });
  const status = ['open', 'review', 'resolved'].includes(req.body.status) ? req.body.status : 'resolved';
  const patch = { status, note: req.body.note || row.data.note || null };
  if (status === 'resolved') patch.resolvedAt = new Date().toISOString();
  const updated = await docs.upsert('reports', row.id, patch);
  if (req.body.hidePost && row.data.targetType === 'post') await docs.upsert('posts', row.data.targetId, { hidden: true, hiddenReason: 'admin' });
  await cache.bump('reports', 'posts');
  res.json({ success: true, data: docs.toItem(updated) });
});

router.post('/admin/posts/:id/hide', requireAdmin, async (req, res) => {
  const row = await docs.upsert('posts', req.params.id, { hidden: req.body.hidden !== false });
  await cache.bump('posts');
  res.json({ success: true, data: docs.toItem(row) });
});

module.exports = { router };
