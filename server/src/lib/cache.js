// Two-level cache for read-heavy endpoints.
// L1: in-process LRU (microseconds). L2: Redis, only if REDIS_URL is set
// (lets several server instances share one cache when you scale out).
// Writes bump a per-collection version, so stale entries are never served.
const crypto = require('crypto');
const { LRUCache } = require('lru-cache');
const config = require('../config');

const l1 = new LRUCache({ max: 5000, maxSize: 64 * 1024 * 1024, sizeCalculation: (v) => v.body.length + 64, ttl: 5 * 60 * 1000 });
const versions = new Map();

let redis = null;
if (config.redisUrl) {
  try {
    const Redis = require('ioredis');
    redis = new Redis(config.redisUrl, { maxRetriesPerRequest: 1, enableOfflineQueue: false, lazyConnect: false });
    redis.on('error', (e) => console.warn('[cache] redis', e.message));
  } catch (e) {
    console.warn('[cache] redis disabled', e.message);
  }
}

async function version(name) {
  if (redis && redis.status === 'ready') {
    try {
      const v = await redis.get(`ver:${name}`);
      if (v) versions.set(name, Number(v));
    } catch (_) {}
  }
  return versions.get(name) || 0;
}

async function bump(...names) {
  for (const name of names.flat()) {
    if (!name) continue;
    versions.set(name, (versions.get(name) || 0) + 1);
    if (redis && redis.status === 'ready') redis.incr(`ver:${name}`).catch(() => {});
    require('./realtime').changed(name);
  }
}

async function get(key) {
  const hit = l1.get(key);
  if (hit) return hit;
  if (redis && redis.status === 'ready') {
    try {
      const raw = await redis.get(`c:${key}`);
      if (raw) {
        const v = JSON.parse(raw);
        l1.set(key, v);
        return v;
      }
    } catch (_) {}
  }
  return null;
}

function set(key, value, ttlSec) {
  l1.set(key, value, { ttl: ttlSec * 1000 });
  if (redis && redis.status === 'ready') redis.set(`c:${key}`, JSON.stringify(value), 'EX', ttlSec).catch(() => {});
}

/**
 * Express middleware: caches a GET JSON response.
 * `tags` = collections the response depends on (a write to any of them invalidates it).
 * Public responses also get an ETag, so phones re-validate with a tiny 304.
 */
function cached(tags, ttlSec = 120, { perUser = false } = {}) {
  return async (req, res, next) => {
    if (req.method !== 'GET') return next();
    const tagList = typeof tags === 'function' ? tags(req) : tags;
    const vers = await Promise.all(tagList.map(version));
    const who = perUser ? (req.user ? req.user.id : 'anon') : 'pub';
    const key = `${tagList.join(',')}@${vers.join('.')}|${who}|${req.originalUrl}`;
    const hit = await get(key);
    if (hit) return send(req, res, hit, perUser);
    const json = res.json.bind(res);
    res.json = (payload) => {
      if (res.statusCode === 200) {
        const body = JSON.stringify(payload);
        const entry = { body, etag: `W/"${crypto.createHash('sha1').update(body).digest('base64').slice(0, 20)}"` };
        set(key, entry, ttlSec);
        return send(req, res, entry, perUser);
      }
      return json(payload);
    };
    next();
  };
}

function send(req, res, entry, perUser) {
  res.setHeader('ETag', entry.etag);
  res.setHeader('Cache-Control', perUser ? 'private, no-cache' : 'public, max-age=30, stale-while-revalidate=300');
  if (req.headers['if-none-match'] === entry.etag) return res.status(304).end();
  res.setHeader('Content-Type', 'application/json; charset=utf-8');
  return res.end(entry.body);
}

module.exports = { cached, bump, get, set, version, redis: () => redis };
