// Live updates over socket.io (free: runs inside the same Render web service).
// Every write already bumps a cache tag; we turn that into the small "<thing>_updated"
// events both apps listen for, so screens refetch (from the cache) instead of polling.
// Events carry no private data: they only say "this list changed".
const { Server } = require('socket.io');
const jwt = require('jsonwebtoken');
const config = require('../config');

let io = null;

// collection -> events broadcast to everyone (apps listen for these names)
const PUBLIC = {
  products: ['products_updated', 'product_updated'],
  categories: ['categories_updated', 'category_updated'],
  subcategories: ['subcategories_updated'],
  banners: ['banners_updated', 'banner_updated'],
  layout: ['layout_sections_updated', 'layout_section_updated'],
  discounts: ['discounts_updated', 'discount_updated'],
  workouts: ['workouts_updated', 'workout_updated'],
  exercises: ['exercises_updated', 'exercise_updated'],
  'workout-banners': ['workout_banners_updated', 'workout_banner_updated'],
  'workout-layout': ['workout_layout_updated'],
  'workout-sections': ['workout_layout_updated'],
  'workout-categories': ['workout_category_updated'],
  posts: ['posts_updated'],
  trainers: ['trainers_updated'],
};
// collection -> events only the admin room gets
const ADMIN = {
  users: ['user:updated'],
  orders: ['order:updated'],
  reports: ['reports_updated'],
  trainer_subscriptions: ['subscriptions_updated'],
  media: ['media_uploaded'],
};

// Coalesce bursts (a reorder writes many rows) into one event per 400 ms.
const pending = new Set();
let timer = null;
function flush() {
  timer = null;
  const names = [...pending];
  pending.clear();
  if (!io) return;
  for (const n of names) {
    for (const ev of PUBLIC[n] || []) io.emit(ev, { collection: n });
    for (const ev of ADMIN[n] || []) io.to('admin').emit(ev, { collection: n });
  }
}

function changed(name) {
  if (!io || (!PUBLIC[name] && !ADMIN[name])) return;
  pending.add(name);
  if (!timer) timer = setTimeout(flush, 400);
}

function userFromToken(token) {
  try {
    return token ? jwt.verify(String(token).replace(/^Bearer\s+/i, ''), config.jwtSecret) : null;
  } catch (_) {
    return null;
  }
}

function init(server) {
  io = new Server(server, {
    cors: { origin: config.corsOrigins.length ? config.corsOrigins : '*' },
    transports: ['websocket', 'polling'],
    pingInterval: 25_000,
    pingTimeout: 20_000,
    maxHttpBufferSize: 16 * 1024,
    serveClient: false,
  });
  // Several server instances: set REDIS_URL and add @socket.io/redis-adapter here.
  io.on('connection', (socket) => {
    const auth = socket.handshake.auth || {};
    const me = userFromToken(auth.token || socket.handshake.query.token || socket.handshake.headers.authorization);
    if (me) {
      socket.join(`user:${me.sub || me.id}`);
      if (['admin', 'superadmin'].includes(me.role)) socket.join('admin');
    }
    // Old clients join rooms by name. A user room only ever gets "your data changed, refetch",
    // and the refetch itself is authorised, so joining by uid leaks nothing.
    socket.on('join_user_room', (uid) => typeof uid === 'string' && uid.length < 128 && socket.join(`user:${uid}`));
    socket.on('join_user_nutrition', (d) => d && typeof d.uid === 'string' && socket.join(`user:${d.uid}`));
    socket.on('join_admin_room', () => socket.join('admin'));
  });
  return io;
}

function toUser(userId, event, payload = {}) {
  if (io && userId) io.to(`user:${userId}`).emit(event, payload);
}
function toAdmins(event, payload = {}) {
  if (io) io.to('admin').emit(event, payload);
}

module.exports = { init, changed, toUser, toAdmins, PUBLIC, ADMIN };
