// Live sessions with LiveKit (free cloud plan). The server only hands out
// short-lived join tokens; video never passes through this server.
const express = require('express');
const crypto = require('crypto');
const { AccessToken, RoomServiceClient } = require('livekit-server-sdk');
const config = require('../config');
const { query, one } = require('../db');
const docs = require('../lib/docs');
const cache = require('../lib/cache');
const { requireAuth, isAdmin } = require('../lib/auth');
const { notify } = require('./notifications');

const router = express.Router();
const configured = () => !!(config.livekit.url && config.livekit.apiKey && config.livekit.apiSecret);

async function token(identity, name, room, canPublish) {
  const at = new AccessToken(config.livekit.apiKey, config.livekit.apiSecret, { identity, name, ttl: '4h' });
  at.addGrant({ room, roomJoin: true, canPublish, canSubscribe: true, canPublishData: true });
  return at.toJwt();
}

function notConfigured(res) {
  return res.status(503).json({ success: false, code: 'livekit_not_configured', message: 'Live video is not set up on the server yet (LiveKit keys missing).' });
}

router.get('/sessions', cache.cached(['live_sessions'], 15), async (req, res) => {
  const status = req.query.status || 'live';
  const params = [];
  let where = `collection = 'live_sessions'`;
  if (status === 'upcoming') where += ` AND data->>'status' = 'scheduled' AND (data->>'startsAt')::timestamptz > now() - interval '30 minutes'`;
  else if (status !== 'all') { params.push(status); where += ` AND data->>'status' = $1`; }
  if (req.query.trainerId) { params.push(req.query.trainerId); where += ` AND owner_id = $${params.length}`; }
  const { rows } = await query(`SELECT * FROM docs WHERE ${where} ORDER BY COALESCE(data->>'startsAt', created_at::text) LIMIT 100`, params);
  res.json({ success: true, data: rows.map((r) => docs.toItem(r)) });
});

// Trainer schedules or starts a session. { title, startsAt?, goLive?: true, subscribersOnly? }
router.post('/sessions', requireAuth, async (req, res) => {
  const trainer = await docs.get('trainers', req.user.id);
  if (!isAdmin(req) && (!trainer || trainer.data.status !== 'approved')) return res.status(403).json({ success: false, message: 'Only approved coaches can go live.' });
  const b = req.body || {};
  const id = String(b.id || docs.newId('live'));
  const goLive = b.goLive !== false && !b.startsAt;
  const row = await docs.upsert('live_sessions', id, {
    title: String(b.title || 'Live workout').slice(0, 120), type: b.type || 'Live class', durationMin: Number(b.durationMin || 45),
    trainerId: req.user.id, trainerName: trainer ? trainer.data.name : 'NeuroFit', trainerPhoto: trainer ? trainer.data.photo : '',
    room: `nf_${id}`, status: goLive ? 'live' : 'scheduled', startsAt: b.startsAt || new Date().toISOString(),
    startedAt: goLive ? new Date().toISOString() : null, subscribersOnly: !!b.subscribersOnly, viewers: 0,
  }, { ownerId: req.user.id });
  if (goLive) {
    // tell subscribers
    const { rows } = await query(`SELECT DISTINCT owner_id FROM docs WHERE collection = 'trainer_subscriptions' AND data->>'trainerId' = $1 AND (data->>'until')::timestamptz > now() LIMIT 5000`, [req.user.id]);
    for (const r of rows) notify({ userId: r.owner_id, title: `${row.data.trainerName} is live now`, body: row.data.title, type: 'live', refId: id }).catch(() => {});
  }
  const out = { success: true, data: docs.toItem(row) };
  if (goLive && configured()) {
    out.token = await token(req.user.id, row.data.trainerName, row.data.room, true);
    out.url = config.livekit.url;
  }
  res.status(201).json(out);
});

// Host (re)starts a scheduled session
router.post('/sessions/:id/start', requireAuth, async (req, res) => {
  if (!configured()) return notConfigured(res);
  const row = await docs.get('live_sessions', req.params.id);
  if (!row || (row.owner_id !== req.user.id && !isAdmin(req))) return res.status(404).json({ success: false, message: 'Session not found' });
  const upd = await docs.upsert('live_sessions', row.id, { status: 'live', startedAt: new Date().toISOString() });
  res.json({ success: true, data: docs.toItem(upd), token: await token(req.user.id, row.data.trainerName, row.data.room, true), url: config.livekit.url });
});

router.post('/sessions/:id/join', requireAuth, async (req, res) => {
  if (!configured()) return notConfigured(res);
  const row = await docs.get('live_sessions', req.params.id);
  if (!row || row.data.status !== 'live') return res.status(404).json({ success: false, message: 'This session is not live.' });
  const host = row.owner_id === req.user.id;
  if (!host && row.data.subscribersOnly && !isAdmin(req)) {
    const sub = await one(`SELECT 1 FROM docs WHERE collection = 'trainer_subscriptions' AND owner_id = $1 AND data->>'trainerId' = $2 AND (data->>'until')::timestamptz > now()`, [req.user.id, row.owner_id]);
    if (!sub) return res.status(403).json({ success: false, code: 'subscribers_only', message: 'Subscribe to this coach to join the live session.' });
  }
  const me = await one('SELECT name FROM users WHERE id = $1', [req.user.id]);
  await query(`UPDATE docs SET data = jsonb_set(data, '{viewers}', to_jsonb(COALESCE((data->>'viewers')::int, 0) + 1)) WHERE collection = 'live_sessions' AND id = $1`, [row.id]);
  res.json({ success: true, data: docs.toItem(row), token: await token(host ? req.user.id : `${req.user.id}_${crypto.randomBytes(2).toString('hex')}`, me ? me.name : 'Member', row.data.room, host), url: config.livekit.url });
});

router.post('/sessions/:id/end', requireAuth, async (req, res) => {
  const row = await docs.get('live_sessions', req.params.id);
  if (!row || (row.owner_id !== req.user.id && !isAdmin(req))) return res.status(404).json({ success: false, message: 'Session not found' });
  const upd = await docs.upsert('live_sessions', row.id, { status: 'ended', endedAt: new Date().toISOString() });
  if (configured()) {
    try { await new RoomServiceClient(config.livekit.url.replace(/^wss?:/, 'https:'), config.livekit.apiKey, config.livekit.apiSecret).deleteRoom(row.data.room); } catch (_) {}
  }
  res.json({ success: true, data: docs.toItem(upd) });
});

router.delete('/sessions/:id', requireAuth, async (req, res) => {
  const row = await docs.get('live_sessions', req.params.id);
  if (!row || (row.owner_id !== req.user.id && !isAdmin(req))) return res.status(404).json({ success: false, message: 'Session not found' });
  await docs.remove('live_sessions', row.id);
  res.json({ success: true });
});

// Generic token (e.g. 1:1 call with a client). Room name must include the caller's id.
router.post('/token', requireAuth, async (req, res) => {
  if (!configured()) return notConfigured(res);
  const room = String(req.body.room || '');
  if (!room || (!room.includes(req.user.id) && !isAdmin(req))) return res.status(403).json({ success: false, message: 'Not allowed for this room' });
  const me = await one('SELECT name FROM users WHERE id = $1', [req.user.id]);
  res.json({ success: true, token: await token(req.user.id, me ? me.name : 'Member', room, true), url: config.livekit.url });
});

router.get('/status', (_req, res) => res.json({ success: true, configured: configured() }));

module.exports = { router };
