require('./lib/async');
const express = require('express');
const compression = require('compression');
const helmet = require('helmet');
const cors = require('cors');
const { rateLimit } = require('express-rate-limit');
const config = require('./config');
const { pool } = require('./db');
const migrate = require('./migrate');
const { optionalAuth } = require('./lib/auth');
const collections = require('./routes/collections');
const auth = require('./routes/auth');
const commerce = require('./routes/commerce');

const app = express();
app.set('trust proxy', 1);
app.disable('x-powered-by');
app.use(helmet({ crossOriginResourcePolicy: { policy: 'cross-origin' }, contentSecurityPolicy: false }));
app.use(cors({ origin: config.corsOrigins.length ? config.corsOrigins : true, credentials: false, maxAge: 86400 }));
app.use(compression({ threshold: 1024 }));
app.use(express.json({ limit: '2mb' }));

// Rate limits per IP: generous for normal use, tight on sign-in.
app.use('/api/auth', rateLimit({ windowMs: 60_000, limit: 30, standardHeaders: 'draft-7', legacyHeaders: false }));
app.use('/api/admin/login', rateLimit({ windowMs: 60_000, limit: 10, standardHeaders: 'draft-7', legacyHeaders: false }));
app.use(['/api', '/fs'], rateLimit({ windowMs: 60_000, limit: 600, standardHeaders: 'draft-7', legacyHeaders: false }));

app.use(optionalAuth);

// Lightweight request log (method, path, status, ms). No bodies: they can hold personal data.
app.use((req, res, next) => {
  const t = process.hrtime.bigint();
  res.on('finish', () => {
    const ms = Number(process.hrtime.bigint() - t) / 1e6;
    if (ms > 800 || res.statusCode >= 500) console.log(`${req.method} ${req.originalUrl.split('?')[0]} ${res.statusCode} ${ms.toFixed(0)}ms`);
  });
  next();
});

app.get('/', (_req, res) => res.json({ name: 'NeuroFit API', version: '2.0.0', status: 'ok' }));
app.get(['/health', '/api/health'], async (_req, res) => {
  try {
    await pool.query('SELECT 1');
    res.json({ status: 'ok', db: 'ok', uptime: Math.round(process.uptime()) });
  } catch (e) {
    res.status(503).json({ status: 'degraded', db: 'down' });
  }
});
app.get('/api/config', (_req, res) => res.json({
  success: true,
  googleClientId: config.googleClientIds[0] || null,
  liveEnabled: !!(config.livekit.url && config.livekit.apiKey),
  uploadsEnabled: !!(config.r2.accountId && config.r2.accessKeyId),
  r2PublicUrl: config.r2.publicUrl || null,
}));

app.use('/api/auth', auth.router);
app.use('/api/admin/trainers', require('./routes/trainers').admin);
app.use('/api/admin/insights', require('./routes/insights').router);
app.use('/api/admin', require('./routes/admin').router);
app.use('/api/users', require('./routes/users').router);
app.use('/api/orders', commerce.orders);
app.use('/api/discounts', commerce.discounts);
app.use('/api/notifications', require('./routes/notifications').router);
app.use('/api/sync', require('./routes/sync').router);
app.use('/api/user-workouts', require('./routes/progress').router);
app.use('/api/trainers', require('./routes/trainers').router);
app.use('/api/panel', require('./routes/trainers').panel);
app.use('/api/community', require('./routes/community').router);
app.use('/api/live', require('./routes/live').router);
app.use('/api/media', require('./routes/media').router);
app.use('/api', require('./routes/nutrition').router);
collections.mount(app);
app.use('/fs', require('./routes/firestore').router);

app.use('/api', (req, res) => res.status(404).json({ success: false, message: `No route for ${req.method} ${req.originalUrl.split('?')[0]}` }));

// eslint-disable-next-line no-unused-vars
app.use((err, req, res, _next) => {
  if (err.type === 'entity.too.large') return res.status(413).json({ success: false, message: 'Request is too large' });
  if (err.type === 'entity.parse.failed') return res.status(400).json({ success: false, message: 'Invalid JSON' });
  console.error(`[error] ${req.method} ${req.originalUrl.split('?')[0]}:`, err.message);
  res.status(500).json({ success: false, message: 'Something went wrong on our side. Please try again.' });
});

async function start() {
  await migrate();
  await auth.ensureAdmin();
  require('./seed/exercises').seedIfEmpty().catch((e) => console.warn('[seed] exercises:', e.message));
  const server = app.listen(config.port, '0.0.0.0', () => console.log(`NeuroFit API listening on :${config.port}`));
  server.keepAliveTimeout = 65_000;
  server.headersTimeout = 66_000;
  const stop = () => server.close(() => pool.end().then(() => process.exit(0)));
  process.on('SIGTERM', stop);
  process.on('SIGINT', stop);
}

if (require.main === module) {
  start().catch((e) => {
    console.error('Failed to start:', e);
    process.exit(1);
  });
}

module.exports = { app, start };
