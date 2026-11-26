// In-app notifications. Rows live in docs('notifications').
// owner_id = user id for personal ones; NULL + audience 'all' | 'admins' for broadcasts.
const express = require('express');
const docs = require('../lib/docs');
const { query } = require('../db');
const { requireAuth, requireAdmin, isAdmin } = require('../lib/auth');

async function notify({ userId = null, audience = 'user', title, body, type = 'info', refId = null, imageUrl = null }) {
  const id = docs.newId('ntf');
  const row = await docs.upsert('notifications', id, {
    notificationId: id, title, body, message: body, type, refId, imageUrl,
    audience: userId ? 'user' : audience, isRead: false,
  }, { ownerId: userId });
  // Live push to the open app (chat replies, live sessions, plan updates...).
  try {
    const rt = require('../lib/realtime');
    const payload = { id, title, body, type, refId };
    if (userId) rt.toUser(userId, 'notification:new', payload);
    else if (audience === 'admins') rt.toAdmins('notification:new', payload);
  } catch (_) {}
  return row;
}

const router = express.Router();

router.get('/', requireAuth, async (req, res) => {
  const { rows } = await query(
    `SELECT d.*, (r.user_id IS NOT NULL) AS read_by_me FROM docs d
       LEFT JOIN reactions r ON r.target_id = 'ntf:' || d.id AND r.user_id = $1 AND r.kind = 'read'
     WHERE d.collection = 'notifications' AND (d.owner_id = $1 OR (d.owner_id IS NULL AND d.data->>'audience' = 'all'))
     ORDER BY d.created_at DESC LIMIT 100`,
    [req.user.id]
  );
  const data = rows.map((r) => ({ ...docs.toItem(r, 'notificationId'), isRead: r.read_by_me || r.data.isRead === true }));
  res.json({ success: true, count: data.length, unread: data.filter((n) => !n.isRead).length, data });
});

router.get('/admin', requireAdmin, async (_req, res) => {
  const { rows } = await query(
    `SELECT * FROM docs WHERE collection = 'notifications' AND (data->>'audience' IN ('admins','all'))
     ORDER BY created_at DESC LIMIT 200`
  );
  res.json({ success: true, data: rows.map((r) => docs.toItem(r, 'notificationId')) });
});

router.post('/:id/read', requireAuth, async (req, res) => {
  await query(
    `INSERT INTO reactions (target_id, user_id, kind) VALUES ($1, $2, 'read') ON CONFLICT DO NOTHING`,
    [`ntf:${req.params.id}`, req.user.id]
  );
  res.json({ success: true });
});

router.post('/read-all', requireAuth, async (req, res) => {
  await query(
    `INSERT INTO reactions (target_id, user_id, kind)
       SELECT 'ntf:' || id, $1, 'read' FROM docs
       WHERE collection = 'notifications' AND (owner_id = $1 OR (owner_id IS NULL AND data->>'audience' = 'all'))
     ON CONFLICT DO NOTHING`,
    [req.user.id]
  );
  res.json({ success: true });
});

// Admin: send to everyone, or to one user ({ userId }).
router.post('/', requireAdmin, async (req, res) => {
  const b = req.body || {};
  if (!b.title) return res.status(400).json({ success: false, message: 'Title is required' });
  const row = await notify({ userId: b.userId || b.uid || null, audience: b.audience || 'all', title: b.title, body: b.body || b.message || '', type: b.type || 'announcement', imageUrl: b.imageUrl || null });
  res.status(201).json({ success: true, data: docs.toItem(row, 'notificationId') });
});

router.delete('/:id', requireAdmin, async (req, res) => {
  await docs.remove('notifications', req.params.id);
  res.json({ success: true });
});

// The app registers its push token; kept for when push is switched on.
router.post('/register-token', requireAuth, async (req, res) => {
  const token = req.body.token || req.body.fcmToken;
  if (token) await query('UPDATE users SET fcm_token = $2 WHERE id = $1', [req.user.id, String(token)]);
  res.json({ success: true });
});

module.exports = { router, notify, isAdmin };
