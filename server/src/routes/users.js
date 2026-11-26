// Profiles, questionnaire, addresses (user) + user management (admin).
const express = require('express');
const crypto = require('crypto');
const { query, one } = require('../db');
const { userJson, requireAuth, requireAdmin, isAdmin } = require('../lib/auth');
const cache = require('../lib/cache');

const router = express.Router();

// Columns a user may change on their own profile. Everything else they send
// goes into the `profile` JSON (goals, height, weight, settings ...).
const OWN_FIELDS = { name: 'name', phone: 'phone', photoUrl: 'photo_url', hasCompletedOnboarding: 'has_completed_onboarding' };
const ADMIN_FIELDS = { ...OWN_FIELDS, role: 'role', status: 'status', isPremium: 'is_premium', isVerified: 'is_verified', email: 'email' };
const NEVER = new Set(['uid', 'id', '_id', 'email', 'authProvider', 'createdAt', 'updatedAt', 'lastActiveAt', 'addresses', 'questionnaireData', 'role', 'status', 'isPremium', 'isVerified', 'password', 'passwordHash']);

function canAccess(req, uid) {
  return req.user && (req.user.id === uid || isAdmin(req));
}

async function loadUser(uid) {
  return one('SELECT * FROM users WHERE id = $1', [uid]);
}

async function updateUser(uid, body, admin) {
  const allowed = admin ? ADMIN_FIELDS : OWN_FIELDS;
  const sets = [];
  const params = [uid];
  for (const [k, col] of Object.entries(allowed)) {
    if (body[k] === undefined) continue;
    let v = body[k];
    if (col === 'role' && !['user', 'trainer', 'vendor', 'admin', 'superadmin'].includes(v)) continue;
    if (col === 'status') v = String(v).toLowerCase();
    if (col === 'email') v = String(v).toLowerCase();
    params.push(v);
    sets.push(`${col} = $${params.length}`);
  }
  if (body.questionnaireData && typeof body.questionnaireData === 'object' && Object.keys(body.questionnaireData).length) {
    params.push(body.questionnaireData);
    sets.push(`questionnaire = questionnaire || $${params.length}::jsonb`);
  }
  const extra = {};
  for (const [k, v] of Object.entries(body)) {
    if (!NEVER.has(k) && !(k in allowed)) extra[k] = v;
  }
  if (Object.keys(extra).length) {
    params.push(extra);
    sets.push(`profile = profile || $${params.length}::jsonb`);
  }
  if (!sets.length) return loadUser(uid);
  const u = await one(`UPDATE users SET ${sets.join(', ')}, updated_at = now() WHERE id = $1 RETURNING *`, params);
  await cache.bump('users');
  return u;
}

// ---------- admin: list / search users ----------
router.get('/', requireAdmin, async (req, res) => {
  const where = [];
  const params = [];
  const q = String(req.query.q || req.query.search || '').trim().toLowerCase();
  if (q) {
    params.push(`%${q}%`);
    where.push(`(lower(name) LIKE $${params.length} OR email LIKE $${params.length} OR phone LIKE $${params.length})`);
  }
  if (req.query.role) { params.push(req.query.role); where.push(`role = $${params.length}`); }
  if (req.query.status) { params.push(String(req.query.status).toLowerCase()); where.push(`status = $${params.length}`); }
  if (req.query.premium === 'true') where.push('is_premium');
  if (req.query.verified === 'false') where.push('NOT is_verified');
  if (req.query.activeWithinDays) { params.push(Number(req.query.activeWithinDays)); where.push(`last_active_at > now() - ($${params.length} || ' days')::interval`); }
  if (req.query.newWithinDays) { params.push(Number(req.query.newWithinDays)); where.push(`created_at > now() - ($${params.length} || ' days')::interval`); }
  const order = req.query.sort === 'active' ? 'last_active_at DESC' : 'created_at DESC';
  const limit = Math.min(Number(req.query.limit) || 200, 1000);
  const offset = Number(req.query.offset) || 0;
  const w = where.length ? `WHERE ${where.join(' AND ')}` : '';
  const [rows, total] = await Promise.all([
    query(`SELECT * FROM users ${w} ORDER BY ${order} LIMIT ${limit} OFFSET ${offset}`, params),
    one(`SELECT count(*)::int AS n FROM users ${w}`, params),
  ]);
  res.json({ success: true, count: rows.rows.length, total: total.n, data: rows.rows.map(userJson) });
});

// ---------- profile ----------
router.get('/:uid', requireAuth, async (req, res) => {
  const uid = req.params.uid === 'me' ? req.user.id : req.params.uid;
  if (!canAccess(req, uid)) return res.status(403).json({ success: false, message: 'Not allowed' });
  const u = await loadUser(uid);
  if (!u) return res.status(404).json({ success: false, message: 'User not found' });
  res.json({ success: true, data: userJson(u) });
});

const saveProfile = async (req, res) => {
  const uid = req.params.uid === 'me' || !req.params.uid ? req.user.id : req.params.uid;
  if (!canAccess(req, uid)) return res.status(403).json({ success: false, message: 'Not allowed' });
  const u = await updateUser(uid, req.body || {}, isAdmin(req) && uid !== req.user.id);
  if (!u) return res.status(404).json({ success: false, message: 'User not found' });
  res.json({ success: true, data: userJson(u) });
};
router.post('/', requireAuth, saveProfile);
router.post('/:uid', requireAuth, saveProfile);
router.put('/:uid', requireAuth, saveProfile);
router.patch('/:uid', requireAuth, saveProfile);

router.patch('/:uid/status', requireAdmin, async (req, res) => {
  const status = String(req.body.status || (req.body.isActive === false ? 'suspended' : 'active')).toLowerCase();
  const u = await one('UPDATE users SET status = $2, updated_at = now() WHERE id = $1 RETURNING *', [req.params.uid, status]);
  if (!u) return res.status(404).json({ success: false, message: 'User not found' });
  if (status !== 'active') await query('DELETE FROM refresh_tokens WHERE user_id = $1', [u.id]);
  await cache.bump('users');
  res.json({ success: true, data: userJson(u) });
});

router.delete('/:uid', requireAuth, async (req, res) => {
  if (!canAccess(req, req.params.uid)) return res.status(403).json({ success: false, message: 'Not allowed' });
  await query('DELETE FROM users WHERE id = $1', [req.params.uid]);
  await query(`DELETE FROM docs WHERE owner_id = $1 AND collection NOT IN ('orders')`, [req.params.uid]);
  await cache.bump('users');
  res.json({ success: true, message: 'Account deleted' });
});

// ---------- questionnaire ----------
const saveQuestionnaire = async (req, res) => {
  const uid = req.params.uid;
  if (!canAccess(req, uid)) return res.status(403).json({ success: false, message: 'Not allowed' });
  const answers = req.body.questionnaireData || req.body || {};
  const u = await one(
    `UPDATE users SET questionnaire = questionnaire || $2::jsonb, has_completed_onboarding = true, updated_at = now() WHERE id = $1 RETURNING *`,
    [uid, answers]
  );
  if (!u) return res.status(404).json({ success: false, message: 'User not found' });
  res.json({ success: true, data: userJson(u), questionnaireData: u.questionnaire });
};
router.post('/:uid/questionnaire', requireAuth, saveQuestionnaire);
router.put('/:uid/questionnaire', requireAuth, saveQuestionnaire);

// ---------- addresses ----------
const addrId = () => `addr_${Date.now().toString(36)}${crypto.randomBytes(3).toString('hex')}`;

async function withAddresses(req, res, fn) {
  const uid = req.params.uid;
  if (!canAccess(req, uid)) return res.status(403).json({ success: false, message: 'Not allowed' });
  const u = await loadUser(uid);
  if (!u) return res.status(404).json({ success: false, message: 'User not found' });
  let list = Array.isArray(u.addresses) ? u.addresses : [];
  const next = fn ? fn(list) : null;
  if (next) {
    list = next;
    await query('UPDATE users SET addresses = $2::jsonb, updated_at = now() WHERE id = $1', [uid, JSON.stringify(list)]);
  }
  res.json({ success: true, data: list, addresses: list });
}

const listAddr = (req, res) => withAddresses(req, res, null);
const saveAddr = (req, res) => withAddresses(req, res, (list) => {
  const a = { ...(req.body || {}) };
  a.id = String(a.id || a.addressId || req.params.addressId || addrId());
  let out = list.filter((x) => x.id !== a.id);
  if (a.isDefault === true || out.length === 0) {
    out = out.map((x) => ({ ...x, isDefault: false }));
    a.isDefault = true;
  }
  return [a, ...out];
});
const setDefault = (req, res) => withAddresses(req, res, (list) =>
  list.map((x) => ({ ...x, isDefault: x.id === (req.params.addressId || req.body.addressId || req.body.id) })));
const delAddr = (req, res) => withAddresses(req, res, (list) => {
  const out = list.filter((x) => x.id !== req.params.addressId);
  if (out.length && !out.some((x) => x.isDefault)) out[0] = { ...out[0], isDefault: true };
  return out;
});

for (const p of ['addresses', 'address']) {
  router.get(`/:uid/${p}`, requireAuth, listAddr);
  router.post(`/:uid/${p}`, requireAuth, saveAddr);
  router.put(`/:uid/${p}`, requireAuth, saveAddr);
  router.put(`/:uid/${p}/default`, requireAuth, setDefault);
  router.put(`/:uid/${p}/primary`, requireAuth, setDefault);
  router.post(`/:uid/${p}/default`, requireAuth, setDefault);
  router.put(`/:uid/${p}/:addressId/default`, requireAuth, setDefault);
  router.post(`/:uid/${p}/:addressId/default`, requireAuth, setDefault);
  router.put(`/:uid/${p}/:addressId`, requireAuth, saveAddr);
  router.delete(`/:uid/${p}/:addressId`, requireAuth, delAddr);
}

module.exports = { router, updateUser };
