const crypto = require('crypto');
const jwt = require('jsonwebtoken');
const config = require('../config');
const { one, query } = require('../db');

const ADMIN_ROLES = new Set(['admin', 'superadmin']);

function userJson(u) {
  if (!u) return null;
  const profile = u.profile || {};
  return {
    ...profile,
    uid: u.id,
    id: u.id,
    _id: u.id,
    name: u.name,
    email: u.email || '',
    phone: u.phone || '',
    photoUrl: u.photo_url || '',
    authProvider: u.auth_provider,
    role: u.role,
    status: u.status,
    isPremium: u.is_premium,
    isVerified: u.is_verified,
    hasCompletedOnboarding: u.has_completed_onboarding,
    questionnaireData: u.questionnaire || {},
    addresses: u.addresses || [],
    createdAt: u.created_at instanceof Date ? u.created_at.toISOString() : u.created_at,
    updatedAt: u.updated_at instanceof Date ? u.updated_at.toISOString() : u.updated_at,
    lastActiveAt: u.last_active_at instanceof Date ? u.last_active_at.toISOString() : u.last_active_at,
  };
}

function signAccess(user) {
  return jwt.sign({ sub: user.id, role: user.role }, config.jwtSecret, { expiresIn: config.accessTtl });
}

const hash = (t) => crypto.createHash('sha256').update(t).digest('hex');

async function issueTokens(user) {
  const refresh = crypto.randomBytes(32).toString('base64url');
  await query(
    `INSERT INTO refresh_tokens (token_hash, user_id, expires_at) VALUES ($1, $2, now() + ($3 || ' days')::interval)`,
    [hash(refresh), user.id, String(config.refreshDays)]
  );
  return { accessToken: signAccess(user), refreshToken: refresh, expiresIn: config.accessTtl };
}

async function rotateRefresh(token) {
  const row = await one(
    'DELETE FROM refresh_tokens WHERE token_hash = $1 AND expires_at > now() RETURNING user_id',
    [hash(token || '')]
  );
  if (!row) return null;
  const user = await one('SELECT * FROM users WHERE id = $1', [row.user_id]);
  if (!user || user.status === 'banned') return null;
  return { user, tokens: await issueTokens(user) };
}

async function revokeRefresh(token) {
  await query('DELETE FROM refresh_tokens WHERE token_hash = $1', [hash(token || '')]);
}

// Throttle "last active" writes to one per user per 5 minutes.
const lastSeen = new Map();
function touch(userId) {
  const now = Date.now();
  if ((lastSeen.get(userId) || 0) > now - 5 * 60 * 1000) return;
  lastSeen.set(userId, now);
  if (lastSeen.size > 200_000) lastSeen.clear();
  query('UPDATE users SET last_active_at = now() WHERE id = $1', [userId]).catch(() => {});
}

/** Reads the Bearer token if present. Never rejects. */
function optionalAuth(req, _res, next) {
  const h = req.headers.authorization || '';
  if (h.startsWith('Bearer ')) {
    try {
      const p = jwt.verify(h.slice(7), config.jwtSecret);
      req.user = { id: p.sub, role: p.role };
      touch(p.sub);
    } catch (_) {
      req.authError = 'invalid_token';
    }
  }
  next();
}

function requireAuth(req, res, next) {
  if (!req.user) {
    return res.status(401).json({ success: false, code: req.authError || 'auth_required', message: 'Please sign in again.' });
  }
  next();
}

function requireAdmin(req, res, next) {
  if (!req.user) return res.status(401).json({ success: false, code: req.authError || 'auth_required', message: 'Admin sign-in required.' });
  if (!ADMIN_ROLES.has(req.user.role)) return res.status(403).json({ success: false, message: 'Admins only.' });
  next();
}

const isAdmin = (req) => !!req.user && ADMIN_ROLES.has(req.user.role);

module.exports = { userJson, issueTokens, rotateRefresh, revokeRefresh, optionalAuth, requireAuth, requireAdmin, isAdmin, ADMIN_ROLES };
