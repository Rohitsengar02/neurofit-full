// Trainers marketplace (user side), the trainer panel (coach side) and
// trainer approval (admin side).
//
// docs('trainers', <userId>)              trainer profile; status pending|approved|rejected|suspended
// docs('trainer_subscriptions', <id>)     owner = subscriber; data.trainerId
// docs('messages', <id>)                  data.thread = '<trainerId>|<userId>'
// docs('checkins' | 'bookings', <id>)     owner = subscriber; data.trainerId
// docs('reviews', <id>)                   owner = reviewer; data.trainerId
// docs('trainer_workouts' | 'trainer_diets', <id>)  owner = trainer
const express = require('express');
const { query, one } = require('../db');
const docs = require('../lib/docs');
const cache = require('../lib/cache');
const { cached } = require('../lib/cache');
const { requireAuth, requireAdmin } = require('../lib/auth');
const { notify } = require('./notifications');

const DEFAULT_PLANS = (price) => [
  { name: 'Monthly', months: 1, price, perks: ['Personal workout plan', 'Weekly check-ins', 'Chat with your coach', '2 live sessions'], active: true },
  { name: 'Quarterly', months: 3, price: Math.round(price * 2.6), perks: ['Everything in Monthly', 'Custom diet plan', '6 live sessions', 'Form checks on video'], active: true },
  { name: 'Yearly', months: 12, price: Math.round(price * 9), perks: ['Everything in Quarterly', 'Unlimited live sessions', 'Priority replies'], active: true },
];

async function trainerJson(row, meId) {
  if (!row) return null;
  const t = docs.toItem(row);
  const [stats, follow] = await Promise.all([
    one(`SELECT
           (SELECT count(*)::int FROM docs WHERE collection = 'trainer_subscriptions' AND data->>'trainerId' = $1 AND (data->>'until')::timestamptz > now()) AS clients,
           (SELECT count(*)::int FROM docs WHERE collection = 'reviews' AND data->>'trainerId' = $1) AS reviews,
           (SELECT COALESCE(avg((data->>'stars')::float), 0) FROM docs WHERE collection = 'reviews' AND data->>'trainerId' = $1) AS rating,
           (SELECT count(*)::int FROM reactions WHERE target_id = 'trainer:' || $1 AND kind = 'follow') AS followers,
           (SELECT count(*)::int FROM docs WHERE collection = 'live_sessions' AND owner_id = $1 AND data->>'status' = 'live') AS live`, [row.id]),
    meId ? one(`SELECT 1 AS f FROM reactions WHERE target_id = $1 AND user_id = $2 AND kind = 'follow'`, [`trainer:${row.id}`, meId]) : null,
  ]);
  return {
    ...t,
    id: row.id,
    userId: row.id,
    clients: stats.clients + Number(t.clientsBefore || 0),
    reviews: stats.reviews,
    rating: stats.reviews ? +stats.rating.toFixed(1) : Number(t.rating || 0),
    followers: stats.followers,
    live: stats.live > 0,
    following: !!follow,
    plans: Array.isArray(t.plans) && t.plans.length ? t.plans : DEFAULT_PLANS(Number(t.price) || 999),
  };
}

// ============================ user side ============================
const router = express.Router();

router.get('/', cached(['trainers', 'reviews', 'live_sessions', 'trainer_subscriptions'], 120), async (req, res) => {
  const filters = { status: 'approved' };
  if (req.query.cat || req.query.category) filters.cat = req.query.cat || req.query.category;
  const rows = await docs.list('trainers', { filters, search: req.query.q, searchFields: ['name', 'role', 'cat', 'city'], limit: Number(req.query.limit) || 200 });
  const data = await Promise.all(rows.map((r) => trainerJson(r)));
  data.sort((a, b) => (b.live - a.live) || (b.top === true) - (a.top === true) || b.rating - a.rating);
  res.json({ success: true, count: data.length, data });
});

router.get('/me/subscription', requireAuth, async (req, res) => {
  const sub = await one(
    `SELECT * FROM docs WHERE collection = 'trainer_subscriptions' AND owner_id = $1 AND (data->>'until')::timestamptz > now() AND data->>'status' <> 'cancelled'
     ORDER BY created_at DESC LIMIT 1`, [req.user.id]);
  if (!sub) return res.json({ success: true, data: null });
  const trainer = await trainerJson(await docs.get('trainers', sub.data.trainerId), req.user.id);
  const plan = await one(
    `SELECT * FROM docs WHERE collection = 'trainer_workouts' AND owner_id = $1 AND (data->>'clientId' = $2 OR data->>'clientId' IS NULL) AND COALESCE(data->>'isActive','true') <> 'false'
     ORDER BY (data->>'clientId' = $2) DESC NULLS LAST, updated_at DESC LIMIT 1`, [sub.data.trainerId, req.user.id]);
  const diet = await one(
    `SELECT * FROM docs WHERE collection = 'trainer_diets' AND owner_id = $1 AND (data->'assignedTo' @> to_jsonb($2::text) OR data->>'clientId' = $2) ORDER BY updated_at DESC LIMIT 1`,
    [sub.data.trainerId, req.user.id]);
  res.json({ success: true, data: { ...docs.toItem(sub), trainer, workout: plan ? docs.toItem(plan) : null, diet: diet ? docs.toItem(diet) : null } });
});

router.get('/me/following', requireAuth, async (req, res) => {
  const { rows } = await query(`SELECT substring(target_id from 9) AS id FROM reactions WHERE user_id = $1 AND kind = 'follow' AND target_id LIKE 'trainer:%'`, [req.user.id]);
  res.json({ success: true, data: rows.map((r) => r.id) });
});

router.get('/me/checkins', requireAuth, async (req, res) => {
  const rows = await docs.list('checkins', { ownerId: req.user.id, order: 'new', limit: 100 });
  res.json({ success: true, data: rows.map((r) => docs.toItem(r)) });
});

router.get('/me/bookings', requireAuth, async (req, res) => {
  const rows = await docs.list('bookings', { ownerId: req.user.id, order: 'new', limit: 100 });
  res.json({ success: true, data: rows.map((r) => docs.toItem(r)) });
});

router.delete('/me/bookings/:id', requireAuth, async (req, res) => {
  const b = await docs.get('bookings', req.params.id);
  if (!b || b.owner_id !== req.user.id) return res.status(404).json({ success: false, message: 'Not found' });
  await docs.remove('bookings', b.id);
  res.json({ success: true });
});

router.delete('/me/subscription', requireAuth, async (req, res) => {
  await query(`UPDATE docs SET data = data || '{"status":"cancelled"}'::jsonb, updated_at = now() WHERE collection = 'trainer_subscriptions' AND owner_id = $1 AND data->>'status' <> 'cancelled'`, [req.user.id]);
  await cache.bump('trainer_subscriptions');
  res.json({ success: true });
});

router.get('/:id', cached(['trainers', 'reviews', 'live_sessions', 'trainer_subscriptions'], 120), async (req, res) => {
  const row = await docs.get('trainers', req.params.id);
  if (!row || row.data.status !== 'approved') return res.status(404).json({ success: false, message: 'Trainer not found' });
  const t = await trainerJson(row);
  const [workouts, sessions, reviews] = await Promise.all([
    docs.list('trainer_workouts', { ownerId: row.id, order: 'new', limit: 20 }),
    query(`SELECT * FROM docs WHERE collection = 'live_sessions' AND owner_id = $1 AND (data->>'status' = 'live' OR (data->>'startsAt')::timestamptz > now() - interval '1 hour') ORDER BY data->>'startsAt' LIMIT 10`, [row.id]),
    docs.list('reviews', { filters: { trainerId: row.id }, order: 'new', limit: 20 }),
  ]);
  res.json({ success: true, data: { ...t,
    workouts: workouts.map((r) => docs.toItem(r)).filter((w) => w.isActive !== false && !w.clientId),
    sessions: sessions.rows.map((r) => docs.toItem(r)),
    reviewList: reviews.map((r) => docs.toItem(r)) } });
});

router.post('/:id/follow', requireAuth, async (req, res) => {
  const target = `trainer:${req.params.id}`;
  const del = await query(`DELETE FROM reactions WHERE target_id = $1 AND user_id = $2 AND kind = 'follow'`, [target, req.user.id]);
  if (!del.rowCount) await query(`INSERT INTO reactions (target_id, user_id, kind) VALUES ($1, $2, 'follow') ON CONFLICT DO NOTHING`, [target, req.user.id]);
  await cache.bump('trainers');
  res.json({ success: true, following: !del.rowCount });
});

async function startSubscription(row, userId, planName, { id, paymentId, complimentary } = {}) {
  const t = await trainerJson(row);
  const plan = t.plans.find((p) => p.name === planName) || t.plans[0];
  // one active subscription at a time
  await query(`UPDATE docs SET data = data || '{"status":"cancelled"}'::jsonb WHERE collection = 'trainer_subscriptions' AND owner_id = $1 AND data->>'status' = 'active'`, [userId]);
  const me = await one('SELECT name, photo_url FROM users WHERE id = $1', [userId]);
  const subId = id || docs.newId('tsub');
  const since = new Date();
  const until = new Date(since.getTime() + 30 * 864e5 * Number(plan.months || 1));
  const sub = await docs.upsert('trainer_subscriptions', subId, {
    trainerId: row.id, trainerName: t.name, userId, userName: me ? me.name : '', userPhoto: me ? me.photo_url : '',
    planName: plan.name, months: plan.months, amount: complimentary ? 0 : plan.price, since: since.toISOString(), until: until.toISOString(),
    status: 'active', paymentStatus: complimentary ? 'complimentary' : (paymentId ? 'paid' : 'pending'), paymentId: paymentId || null,
  }, { ownerId: userId });
  await docs.upsert('messages', docs.newId('msg'), { thread: `${row.id}|${userId}`, fromId: row.id, text: `Hey ${me ? me.name.split(' ')[0] : 'there'}! Welcome aboard 🎉 Tell me your main goal for the next 12 weeks?`, readByUser: false, readByTrainer: true });
  notify({ userId: row.id, title: 'New client', body: `${me ? me.name : 'Someone'} subscribed to your ${plan.name} plan`, type: 'trainer', refId: subId }).catch(() => {});
  notify({ userId, title: `Welcome to ${t.name}'s team`, body: `Your ${plan.name.toLowerCase()} plan is active.`, type: 'plan', refId: subId }).catch(() => {});
  return { ...docs.toItem(sub), trainer: t };
}

router.post('/:id/subscribe', requireAuth, async (req, res) => {
  const row = await docs.get('trainers', req.params.id);
  if (!row || row.data.status !== 'approved') return res.status(404).json({ success: false, message: 'Trainer not found' });
  if (row.data.accepting === false) return res.status(409).json({ success: false, message: 'This coach is not taking new clients right now.' });
  res.status(201).json({ success: true, data: await startSubscription(row, req.user.id, req.body.planName, { id: req.body.id, paymentId: req.body.paymentId }) });
});

async function threadMessages(thread, limit = 200) {
  const { rows } = await query(`SELECT * FROM docs WHERE collection = 'messages' AND data @> $1::jsonb ORDER BY created_at ASC LIMIT $2`, [JSON.stringify({ thread }), limit]);
  return rows.map((r) => docs.toItem(r));
}

router.get('/:id/chat', requireAuth, async (req, res) => {
  const thread = `${req.params.id}|${req.user.id}`;
  await query(`UPDATE docs SET data = data || '{"readByUser":true}'::jsonb WHERE collection = 'messages' AND data @> $1::jsonb AND data->>'readByUser' = 'false'`, [JSON.stringify({ thread })]);
  const msgs = await threadMessages(thread);
  res.json({ success: true, data: msgs.map((m) => ({ ...m, me: m.fromId === req.user.id })) });
});

router.post('/:id/chat', requireAuth, async (req, res) => {
  const text = String(req.body.text || '').trim().slice(0, 4000);
  if (!text) return res.status(400).json({ success: false, message: 'Empty message' });
  const row = await docs.upsert('messages', req.body.id || docs.newId('msg'), { thread: `${req.params.id}|${req.user.id}`, fromId: req.user.id, text, readByUser: true, readByTrainer: false });
  notify({ userId: req.params.id, title: 'New message', body: text.slice(0, 120), type: 'chat', refId: req.user.id }).catch(() => {});
  res.status(201).json({ success: true, data: { ...docs.toItem(row), me: true } });
});

router.post('/:id/checkins', requireAuth, async (req, res) => {
  const row = await docs.upsert('checkins', req.body.id || docs.newId('chk'), { ...req.body, trainerId: req.params.id, userId: req.user.id }, { ownerId: req.user.id });
  notify({ userId: req.params.id, title: 'New check-in', body: `Weight ${req.body.weight || '-'} kg · energy ${req.body.energy || '-'}/5`, type: 'checkin', refId: row.id }).catch(() => {});
  res.status(201).json({ success: true, data: docs.toItem(row) });
});

router.post('/:id/bookings', requireAuth, async (req, res) => {
  const row = await docs.upsert('bookings', req.body.id || docs.newId('bkg'), { ...req.body, trainerId: req.params.id, userId: req.user.id, status: 'booked' }, { ownerId: req.user.id });
  notify({ userId: req.params.id, title: 'Session booked', body: `${req.body.type || 'Session'} on ${req.body.at || ''}`, type: 'booking', refId: row.id }).catch(() => {});
  res.status(201).json({ success: true, data: docs.toItem(row) });
});

router.post('/:id/reviews', requireAuth, async (req, res) => {
  const stars = Math.max(1, Math.min(5, Number(req.body.stars || req.body.rating) || 5));
  const me = await one('SELECT name, photo_url FROM users WHERE id = $1', [req.user.id]);
  const id = `rev_${req.params.id}_${req.user.id}`; // one review per user per coach
  const row = await docs.upsert('reviews', id, { trainerId: req.params.id, stars, text: String(req.body.text || '').slice(0, 2000), name: me ? me.name : 'Member', photo: me ? me.photo_url : '' }, { ownerId: req.user.id });
  await cache.bump('trainers');
  res.status(201).json({ success: true, data: docs.toItem(row) });
});

// ============================ trainer panel ============================
const panel = express.Router();
panel.use(requireAuth);

async function myTrainer(req, res) {
  const row = await docs.get('trainers', req.user.id);
  if (!row) { res.status(404).json({ success: false, code: 'not_a_trainer', message: 'Register as a coach first.' }); return null; }
  return row;
}

panel.post('/apply', async (req, res) => {
  const me = await one('SELECT name, email, photo_url FROM users WHERE id = $1', [req.user.id]);
  const existing = await docs.get('trainers', req.user.id);
  const b = req.body || {};
  const row = await docs.upsert('trainers', req.user.id, {
    name: b.name || (me && me.name), email: me && me.email, role: b.headline || b.role || 'Fitness coach', headline: b.headline || b.role || 'Fitness coach',
    cat: b.cat || b.category || (Array.isArray(b.specialties) && b.specialties[0]) || 'Strength', specialties: b.specialties || [], city: b.city || '', bio: b.bio || '',
    photo: b.photo || b.photoUrl || (me && me.photo_url) || '', years: Number(b.years || b.experience || 0), price: Number(b.price || 999),
    certifications: b.certifications || [], tags: b.tags || b.specialties || [], languages: b.languages || [],
    accepting: true, status: existing ? existing.data.status : 'pending', appliedAt: existing ? existing.data.appliedAt : new Date().toISOString(),
  }, { ownerId: req.user.id });
  if (!existing) notify({ audience: 'admins', title: 'New coach application', body: `${row.data.name} applied to become a coach`, type: 'trainer_application', refId: row.id }).catch(() => {});
  res.status(existing ? 200 : 201).json({ success: true, data: docs.toItem(row) });
});

panel.get('/me', async (req, res) => {
  const row = await myTrainer(req, res); if (!row) return;
  res.json({ success: true, data: await trainerJson(row) });
});

panel.put('/me', async (req, res) => {
  const row = await myTrainer(req, res); if (!row) return;
  const b = { ...req.body };
  delete b.status; delete b.top; // admin-only
  const updated = await docs.upsert('trainers', row.id, b);
  res.json({ success: true, data: await trainerJson(updated) });
});

panel.get('/dashboard', async (req, res) => {
  const row = await myTrainer(req, res); if (!row) return;
  const subs = (await docs.list('trainer_subscriptions', { filters: { trainerId: row.id }, order: 'new', limit: 2000 })).map((r) => docs.toItem(r));
  const now = Date.now();
  const activeSubs = subs.filter((s) => s.status !== 'cancelled' && new Date(s.until).getTime() > now);
  const monthStart = new Date(); monthStart.setDate(1); monthStart.setHours(0, 0, 0, 0);
  const unread = await one(`SELECT count(*)::int AS n FROM docs WHERE collection = 'messages' AND data->>'thread' LIKE $1 AND data->>'readByTrainer' = 'false'`, [`${row.id}|%`]);
  const weekly = Array(7).fill(0);
  for (const s of subs) {
    const age = Math.floor((now - new Date(s.createdAt).getTime()) / 864e5);
    if (age < 7) weekly[6 - age] += Number(s.amount || 0);
  }
  res.json({ success: true, data: {
    trainer: await trainerJson(row),
    activeClients: activeSubs.length,
    expiring: activeSubs.filter((s) => new Date(s.until).getTime() - now < 7 * 864e5).length,
    unread: unread.n,
    balance: subs.filter((s) => s.paymentStatus === 'paid').reduce((a, s) => a + Number(s.amount || 0), 0),
    monthEarnings: subs.filter((s) => new Date(s.createdAt) >= monthStart).reduce((a, s) => a + Number(s.amount || 0), 0),
    weekly,
  } });
});

panel.get('/clients', async (req, res) => {
  const row = await myTrainer(req, res); if (!row) return;
  const { rows } = await query(
    `SELECT s.*, u.name AS u_name, u.photo_url AS u_photo, u.email AS u_email,
       (SELECT count(*)::int FROM docs m WHERE m.collection = 'messages' AND m.data->>'thread' = $1 || '|' || s.owner_id AND m.data->>'readByTrainer' = 'false') AS unread,
       (SELECT count(*)::int FROM user_records r WHERE r.user_id = s.owner_id AND r.collection = 'workout_progress' AND r.data->>'dayCompleted' = 'true') AS workouts
     FROM docs s LEFT JOIN users u ON u.id = s.owner_id
     WHERE s.collection = 'trainer_subscriptions' AND s.data->>'trainerId' = $1 ORDER BY s.created_at DESC LIMIT 1000`, [row.id]);
  const now = Date.now();
  res.json({ success: true, data: rows.map((r) => {
    const s = docs.toItem(r);
    const left = new Date(s.until).getTime() - now;
    const status = s.clientStatus || (s.status === 'cancelled' || left < 0 ? 'paused' : left < 7 * 864e5 ? 'expiring' : 'active');
    return { ...s, name: r.u_name || s.userName, photo: r.u_photo || s.userPhoto, email: r.u_email, unread: r.unread, workouts: r.workouts, status };
  }) });
});

panel.put('/clients/:subId', async (req, res) => {
  const row = await myTrainer(req, res); if (!row) return;
  const sub = await docs.get('trainer_subscriptions', req.params.subId);
  if (!sub || sub.data.trainerId !== row.id) return res.status(404).json({ success: false, message: 'Client not found' });
  const patch = {};
  if (req.body.status) patch.clientStatus = req.body.status;
  if (req.body.note !== undefined) patch.trainerNote = req.body.note;
  if (req.body.renewMonths) patch.until = new Date(Math.max(Date.now(), new Date(sub.data.until).getTime()) + 30 * 864e5 * Number(req.body.renewMonths)).toISOString();
  res.json({ success: true, data: docs.toItem(await docs.upsert('trainer_subscriptions', sub.id, patch)) });
});

panel.get('/clients/:userId/chat', async (req, res) => {
  const row = await myTrainer(req, res); if (!row) return;
  const thread = `${row.id}|${req.params.userId}`;
  await query(`UPDATE docs SET data = data || '{"readByTrainer":true}'::jsonb WHERE collection = 'messages' AND data @> $1::jsonb AND data->>'readByTrainer' = 'false'`, [JSON.stringify({ thread })]);
  const msgs = await threadMessages(thread);
  res.json({ success: true, data: msgs.map((m) => ({ ...m, me: m.fromId === row.id })) });
});

panel.post('/clients/:userId/chat', async (req, res) => {
  const row = await myTrainer(req, res); if (!row) return;
  const text = String(req.body.text || '').trim().slice(0, 4000);
  if (!text) return res.status(400).json({ success: false, message: 'Empty message' });
  const m = await docs.upsert('messages', req.body.id || docs.newId('msg'), { thread: `${row.id}|${req.params.userId}`, fromId: row.id, text, readByTrainer: true, readByUser: false });
  notify({ userId: req.params.userId, title: `${row.data.name} replied`, body: text.slice(0, 120), type: 'chat', refId: row.id }).catch(() => {});
  res.status(201).json({ success: true, data: { ...docs.toItem(m), me: true } });
});

panel.get('/checkins', async (req, res) => {
  const row = await myTrainer(req, res); if (!row) return;
  const rows = await docs.list('checkins', { filters: { trainerId: row.id }, order: 'new', limit: 300 });
  res.json({ success: true, data: rows.map((r) => docs.toItem(r)) });
});

panel.get('/bookings', async (req, res) => {
  const row = await myTrainer(req, res); if (!row) return;
  const rows = await docs.list('bookings', { filters: { trainerId: row.id }, order: 'new', limit: 300 });
  res.json({ success: true, data: rows.map((r) => docs.toItem(r)) });
});

panel.get('/reviews', async (req, res) => {
  const row = await myTrainer(req, res); if (!row) return;
  const rows = await docs.list('reviews', { filters: { trainerId: row.id }, order: 'new', limit: 300 });
  res.json({ success: true, data: rows.map((r) => docs.toItem(r)) });
});

panel.post('/reviews/:id/reply', async (req, res) => {
  const row = await myTrainer(req, res); if (!row) return;
  const r = await docs.get('reviews', req.params.id);
  if (!r || r.data.trainerId !== row.id) return res.status(404).json({ success: false, message: 'Review not found' });
  res.json({ success: true, data: docs.toItem(await docs.upsert('reviews', r.id, { reply: String(req.body.text || '') })) });
});

panel.get('/transactions', async (req, res) => {
  const row = await myTrainer(req, res); if (!row) return;
  const [rows, payouts] = await Promise.all([
    docs.list('trainer_subscriptions', { filters: { trainerId: row.id }, order: 'new', limit: 1000 }),
    docs.list('payout_requests', { ownerId: row.id, order: 'new', limit: 200 }),
  ]);
  const data = [
    ...rows.map((r) => { const s = docs.toItem(r); return { id: s.id, title: `${s.planName} plan · ${s.userName || 'Client'}`, amount: Number(s.amount || 0), at: s.createdAt, status: s.paymentStatus }; }),
    ...payouts.map((r) => { const p = docs.toItem(r); return { id: p.id, title: 'Payout to bank', amount: -Number(p.amount || 0), at: p.createdAt, status: p.status }; }),
  ].sort((a, b) => String(b.at).localeCompare(String(a.at)));
  res.json({ success: true, data });
});

// Coach asks for a payout of their paid earnings; the admin settles it.
panel.post('/payouts', async (req, res) => {
  const row = await myTrainer(req, res); if (!row) return;
  const amount = Math.round(Number(req.body.amount) || 0);
  const paid = await one(`SELECT COALESCE(sum((data->>'amount')::numeric), 0) AS n FROM docs WHERE collection = 'trainer_subscriptions' AND data->>'trainerId' = $1 AND data->>'paymentStatus' = 'paid'`, [row.id]);
  const out = await one(`SELECT COALESCE(sum((data->>'amount')::numeric), 0) AS n FROM docs WHERE collection = 'payout_requests' AND owner_id = $1 AND data->>'status' <> 'rejected'`, [row.id]);
  if (amount <= 0 || amount > Number(paid.n) - Number(out.n)) return res.status(400).json({ success: false, message: 'Amount is more than your balance.' });
  const p = await docs.upsert('payout_requests', docs.newId('pay'), { trainerId: row.id, trainerName: row.data.name, amount, status: 'requested' }, { ownerId: row.id });
  notify({ audience: 'admins', title: 'Payout requested', body: `${row.data.name} asked for ₹${amount}`, type: 'payout', refId: p.id }).catch(() => {});
  res.status(201).json({ success: true, data: docs.toItem(p) });
});

// trainer-owned content: workouts, diets (CRUD)
for (const [path, coll, prefix] of [['workouts', 'trainer_workouts', 'tw'], ['diets', 'trainer_diets', 'td']]) {
  panel.get(`/${path}`, async (req, res) => {
    const rows = await docs.list(coll, { ownerId: req.user.id, order: 'new', limit: 500 });
    res.json({ success: true, data: rows.map((r) => docs.toItem(r)) });
  });
  panel.post(`/${path}`, async (req, res) => {
    const row = await myTrainer(req, res); if (!row) return;
    const id = String(req.body.id || docs.newId(prefix));
    const existing = await docs.get(coll, id);
    if (existing && existing.owner_id !== row.id) return res.status(403).json({ success: false, message: 'Not yours' });
    const saved = await docs.upsert(coll, id, { ...req.body, trainerId: row.id }, { ownerId: row.id });
    res.status(201).json({ success: true, data: docs.toItem(saved) });
  });
  panel.delete(`/${path}/:id`, async (req, res) => {
    const existing = await docs.get(coll, req.params.id);
    if (!existing || existing.owner_id !== req.user.id) return res.status(404).json({ success: false, message: 'Not found' });
    await docs.remove(coll, existing.id);
    res.json({ success: true });
  });
}

// ============================ admin ============================
const admin = express.Router();
admin.use(requireAdmin);

admin.get('/', async (req, res) => {
  const filters = {};
  if (req.query.status) filters.status = req.query.status;
  const rows = await docs.list('trainers', { filters, order: 'new', limit: 1000, search: req.query.q, searchFields: ['name', 'email', 'city', 'cat'] });
  const money = await query(`SELECT data->>'trainerId' AS t,
      COALESCE(sum((data->>'amount')::numeric) FILTER (WHERE created_at > now() - interval '30 days'), 0) AS revenue30d,
      COALESCE(sum((data->>'amount')::numeric), 0) AS revenue,
      count(*) FILTER (WHERE created_at > now() - interval '30 days')::int AS new30d
    FROM docs WHERE collection = 'trainer_subscriptions' GROUP BY 1`);
  const m = new Map(money.rows.map((r) => [r.t, r]));
  res.json({ success: true, data: await Promise.all(rows.map(async (r) => {
    const x = m.get(r.id);
    return { ...(await trainerJson(r)), revenue30d: Number(x?.revenue30d || 0), revenue: Number(x?.revenue || 0), newClients30d: x?.new30d || 0 };
  })) });
});

async function setTrainerStatus(req, res, status) {
  const row = await docs.get('trainers', req.params.id);
  if (!row) return res.status(404).json({ success: false, message: 'Trainer not found' });
  const patch = { status, reviewedAt: new Date().toISOString() };
  if (req.body && req.body.reason) patch.reviewNote = req.body.reason;
  const updated = await docs.upsert('trainers', row.id, patch);
  await query(`UPDATE users SET role = $2, updated_at = now() WHERE id = $1 AND role NOT IN ('admin','superadmin')`, [row.id, status === 'approved' ? 'trainer' : 'user']);
  await cache.bump('users');
  notify({ userId: row.id, title: status === 'approved' ? 'You are now a NeuroFit coach 🎉' : 'Coach application update', body: status === 'approved' ? 'Your coach profile is live. Open the trainer panel to add plans.' : `Your application was ${status}.${patch.reviewNote ? ' ' + patch.reviewNote : ''}`, type: 'trainer' }).catch(() => {});
  res.json({ success: true, data: await trainerJson(updated) });
}
// Everything the admin trainer sheet shows: clients, check-ins, retention and reply time.
admin.get('/:id/detail', async (req, res) => {
  const id = req.params.id;
  const [subs, chk, reply] = await Promise.all([
    query(`SELECT s.owner_id, s.data, s.created_at, u.name, u.photo_url
             FROM docs s LEFT JOIN users u ON u.id = s.owner_id
            WHERE s.collection = 'trainer_subscriptions' AND s.data->>'trainerId' = $1 ORDER BY s.created_at DESC LIMIT 200`, [id]),
    query(`SELECT owner_id, count(*)::int AS n, max(created_at) AS last FROM docs WHERE collection = 'checkins' AND data->>'trainerId' = $1 GROUP BY owner_id`, [id]),
    one(`SELECT avg(EXTRACT(EPOCH FROM (r.created_at - m.created_at)) / 60) AS mins
           FROM docs m
           JOIN LATERAL (SELECT created_at FROM docs r WHERE r.collection = 'messages' AND r.data->>'thread' = m.data->>'thread'
                          AND r.data->>'fromId' = $1 AND r.created_at > m.created_at ORDER BY r.created_at LIMIT 1) r ON true
          WHERE m.collection = 'messages' AND m.data->>'thread' LIKE $1 || '|%' AND m.data->>'fromId' <> $1
            AND m.created_at > now() - interval '60 days'`, [id]),
  ]);
  const cm = new Map(chk.rows.map((r) => [r.owner_id, r]));
  const now = Date.now();
  const clients = subs.rows.map((s) => {
    const since = Date.parse(s.data.since || s.created_at);
    const c = cm.get(s.owner_id);
    const weeks = Math.max(1, Math.ceil((now - since) / (7 * 864e5)));
    return {
      userId: s.owner_id, name: s.name || s.data.userName || 'Client', photo: s.photo_url || s.data.userPhoto || '',
      planName: s.data.planName || 'Coaching', since: s.data.since, until: s.data.until, amount: Number(s.data.amount || 0),
      active: Date.parse(s.data.until) > now && s.data.status !== 'cancelled',
      days: Math.max(0, Math.floor((now - since) / 864e5)), checkins: c ? c.n : 0,
      adherence: Math.min(100, Math.round(((c ? c.n : 0) / weeks) * 100)),
    };
  });
  const total = clients.length, active = clients.filter((c) => c.active).length;
  res.json({ success: true, data: {
    clients, total, active,
    retention: total ? Math.round((active / total) * 1000) / 10 : 0,
    engaged: total ? Math.round((clients.filter((c) => c.checkins > 0).length / total) * 1000) / 10 : 0,
    replyMinutes: reply && reply.mins != null ? Math.round(Number(reply.mins)) : null,
  } });
});

// Admin puts a user on a coach's plan (complimentary, no payment).
admin.post('/:id/assign', async (req, res) => {
  const row = await docs.get('trainers', req.params.id);
  if (!row || row.data.status !== 'approved') return res.status(404).json({ success: false, message: 'Trainer not found' });
  const b = req.body || {};
  const u = b.userId ? await one('SELECT id FROM users WHERE id = $1', [b.userId]) : await one('SELECT id FROM users WHERE email = lower($1)', [String(b.email || '').trim()]);
  if (!u) return res.status(404).json({ success: false, message: 'No user with that email' });
  res.status(201).json({ success: true, data: await startSubscription(row, u.id, b.planName, { complimentary: true }) });
});

admin.post('/:id/approve', (req, res) => setTrainerStatus(req, res, 'approved'));
admin.post('/:id/reject', (req, res) => setTrainerStatus(req, res, 'rejected'));
admin.post('/:id/suspend', (req, res) => setTrainerStatus(req, res, 'suspended'));
admin.put('/:id', async (req, res) => {
  const row = await docs.get('trainers', req.params.id);
  if (!row) return res.status(404).json({ success: false, message: 'Trainer not found' });
  res.json({ success: true, data: await trainerJson(await docs.upsert('trainers', row.id, req.body || {})) });
});

module.exports = { router, panel, admin, trainerJson };
