const express = require('express');
const bcrypt = require('bcryptjs');
const crypto = require('crypto');
const { OAuth2Client } = require('google-auth-library');
const config = require('../config');
const { one } = require('../db');
const { userJson, issueTokens, rotateRefresh, revokeRefresh, requireAuth, ADMIN_ROLES } = require('../lib/auth');
const cache = require('../lib/cache');

const router = express.Router();
const google = new OAuth2Client();

const newUserId = () => `u_${Date.now().toString(36)}${crypto.randomBytes(5).toString('hex')}`;
const emailOk = (e) => /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/.test(e);

async function respond(res, user, status = 200) {
  const tokens = await issueTokens(user);
  res.status(status).json({ success: true, data: userJson(user), user: userJson(user), ...tokens });
}

router.post('/register', async (req, res) => {
  const name = String(req.body.name || '').trim();
  const email = String(req.body.email || '').trim().toLowerCase();
  const password = String(req.body.password || '');
  const phone = String(req.body.phone || '').trim();
  if (!emailOk(email)) return res.status(400).json({ success: false, message: 'Enter a valid email address.' });
  if (password.length < 6) return res.status(400).json({ success: false, message: 'Password must be at least 6 characters.' });
  const existing = await one('SELECT id, password_hash FROM users WHERE email = $1', [email]);
  if (existing) {
    return res.status(409).json({
      success: false,
      code: existing.password_hash ? 'email_taken' : 'use_google',
      message: existing.password_hash ? 'An account with this email already exists. Please sign in.' : 'This email is registered with Google. Use Continue with Google.',
    });
  }
  const user = await one(
    `INSERT INTO users (id, email, password_hash, name, phone, auth_provider) VALUES ($1, $2, $3, $4, $5, 'email') RETURNING *`,
    [newUserId(), email, await bcrypt.hash(password, 10), name || email.split('@')[0], phone]
  );
  await cache.bump('users');
  return respond(res, user, 201);
});

router.post('/login', async (req, res) => {
  const email = String(req.body.email || '').trim().toLowerCase();
  const password = String(req.body.password || '');
  const user = await one('SELECT * FROM users WHERE email = $1', [email]);
  if (!user || !user.password_hash) {
    return res.status(401).json({
      success: false,
      code: user ? 'use_google' : 'no_account',
      message: user ? 'This email signs in with Google. Use Continue with Google.' : 'No account found for this email. Please register first.',
    });
  }
  if (!(await bcrypt.compare(password, user.password_hash))) {
    return res.status(401).json({ success: false, code: 'wrong_password', message: 'Incorrect password.' });
  }
  if (user.status === 'banned') return res.status(403).json({ success: false, message: 'This account has been suspended.' });
  return respond(res, user);
});

router.post('/google', async (req, res) => {
  const idToken = req.body.idToken || req.body.id_token;
  const accessToken = req.body.accessToken || req.body.access_token;
  if (!idToken && !accessToken) return res.status(400).json({ success: false, message: 'Missing Google token.' });
  if (!config.googleClientIds.length) {
    return res.status(503).json({ success: false, code: 'google_not_configured', message: 'Google sign-in is not set up on the server yet.' });
  }
  let p;
  try {
    if (idToken) {
      const ticket = await google.verifyIdToken({ idToken, audience: config.googleClientIds });
      p = ticket.getPayload();
    } else {
      // Web sign-in may only give an access token: check it was issued to our app, then read the profile.
      const info = await (await fetch(`https://oauth2.googleapis.com/tokeninfo?access_token=${encodeURIComponent(accessToken)}`)).json();
      if (!config.googleClientIds.includes(info.aud || info.azp)) throw new Error('wrong audience');
      p = await (await fetch('https://openidconnect.googleapis.com/v1/userinfo', { headers: { Authorization: `Bearer ${accessToken}` } })).json();
      if (!p.sub) throw new Error('no profile');
    }
  } catch (e) {
    return res.status(401).json({ success: false, message: 'Google sign-in could not be verified.' });
  }
  const email = (p.email || '').toLowerCase();
  let user = await one('SELECT * FROM users WHERE google_sub = $1 OR (email = $2 AND $2 <> \'\') ORDER BY google_sub NULLS LAST LIMIT 1', [p.sub, email]);
  let created = false;
  if (!user) {
    user = await one(
      `INSERT INTO users (id, email, google_sub, name, photo_url, auth_provider, is_verified) VALUES ($1, $2, $3, $4, $5, 'google', $6) RETURNING *`,
      [newUserId(), email || null, p.sub, p.name || (email ? email.split('@')[0] : 'Athlete'), p.picture || '', !!p.email_verified]
    );
    created = true;
    await cache.bump('users');
  } else if (!user.google_sub || (!user.photo_url && p.picture)) {
    user = await one(
      `UPDATE users SET google_sub = $2, photo_url = CASE WHEN photo_url = '' THEN $3 ELSE photo_url END, updated_at = now() WHERE id = $1 RETURNING *`,
      [user.id, p.sub, p.picture || '']
    );
  }
  if (user.status === 'banned') return res.status(403).json({ success: false, message: 'This account has been suspended.' });
  return respond(res, user, created ? 201 : 200);
});

router.post('/refresh', async (req, res) => {
  const out = await rotateRefresh(req.body.refreshToken);
  if (!out) return res.status(401).json({ success: false, code: 'refresh_invalid', message: 'Session expired. Please sign in again.' });
  res.json({ success: true, data: userJson(out.user), ...out.tokens });
});

router.post('/logout', async (req, res) => {
  if (req.body.refreshToken) await revokeRefresh(req.body.refreshToken);
  res.json({ success: true });
});

router.get('/me', requireAuth, async (req, res) => {
  const user = await one('SELECT * FROM users WHERE id = $1', [req.user.id]);
  if (!user) return res.status(404).json({ success: false, message: 'Account not found.' });
  res.json({ success: true, data: userJson(user) });
});

/** Admin panel login (same contract the admin app already uses). */
async function adminLogin(req, res) {
  const email = String(req.body.email || '').trim().toLowerCase();
  const password = String(req.body.password || '');
  const user = await one('SELECT * FROM users WHERE email = $1', [email]);
  if (!user || !user.password_hash || !ADMIN_ROLES.has(user.role) || !(await bcrypt.compare(password, user.password_hash))) {
    return res.status(401).json({ success: false, message: 'Invalid admin credentials' });
  }
  const tokens = await issueTokens(user);
  res.json({
    success: true,
    message: 'Admin authentication successful',
    data: { id: user.id, email: user.email, name: user.name, role: user.role, lastLogin: new Date().toISOString(), ...tokens },
    ...tokens,
  });
}

/** Creates (or updates the password of) the first admin from ADMIN_EMAIL / ADMIN_PASSWORD. */
async function ensureAdmin() {
  if (!config.adminEmail || !config.adminPassword) return;
  const hashPw = await bcrypt.hash(config.adminPassword, 10);
  const existing = await one('SELECT id, password_hash FROM users WHERE email = $1', [config.adminEmail]);
  if (!existing) {
    await one(
      `INSERT INTO users (id, email, password_hash, name, auth_provider, role, is_verified) VALUES ($1, $2, $3, 'Admin', 'email', 'superadmin', true) RETURNING id`,
      [newUserId(), config.adminEmail, hashPw]
    );
    console.log(`[auth] created admin ${config.adminEmail}`);
  } else if (!existing.password_hash || !(await bcrypt.compare(config.adminPassword, existing.password_hash))) {
    await one(`UPDATE users SET password_hash = $2, role = 'superadmin' WHERE id = $1 RETURNING id`, [existing.id, hashPw]);
  } else {
    await one(`UPDATE users SET role = 'superadmin' WHERE id = $1 AND role NOT IN ('admin','superadmin') RETURNING id`, [existing.id]);
  }
}

module.exports = { router, adminLogin, ensureAdmin, newUserId };
