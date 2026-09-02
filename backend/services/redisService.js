const Redis = require('ioredis');

class RedisService {
  constructor() {
    this.client = null;
    this.isConnected = false;
    this.memoryCache = new Map();
    this.memoryExpirations = new Map();

    this.init();
  }

  init() {
    const rawUrl = (process.env.REDIS_URL || process.env.REDIS_URI || '').trim();
    const isValidUrl = rawUrl.startsWith('redis://') || rawUrl.startsWith('rediss://');

    if (!isValidUrl && !process.env.REDIS_HOST) {
      if (rawUrl) {
        console.log('ℹ️ [Redis] REDIS_URL should start with "redis://" or "rediss://" (e.g. rediss://default:<password>@<endpoint>.upstash.io:6379). Running with high-performance in-memory cache.');
      } else {
        console.log('ℹ️ [Redis] Running with built-in high-speed in-memory cache.');
      }
      return;
    }

    try {
      const options = {
        maxRetriesPerRequest: 1,
        connectTimeout: 4000,
        enableOfflineQueue: false,
        retryStrategy(times) {
          if (times > 2) {
            return null;
          }
          return 2000;
        },
      };

      if (isValidUrl) {
        this.client = new Redis(rawUrl, options);
      } else {
        this.client = new Redis({
          host: process.env.REDIS_HOST || '127.0.0.1',
          port: Number(process.env.REDIS_PORT) || 6379,
          password: process.env.REDIS_PASSWORD || undefined,
          ...options,
        });
      }

      this.client.on('connect', () => {
        this.isConnected = true;
        console.log('⚡ [Redis] Connected successfully! Memory cache accelerated.');
      });

      let hasLoggedError = false;
      this.client.on('error', (err) => {
        this.isConnected = false;
        if (!hasLoggedError) {
          hasLoggedError = true;
          console.warn(`ℹ️ [Redis Cache Notice] Redis server connection paused (${err.message}). Seamlessly using fast in-memory cache.`);
        }
      });

      this.client.on('close', () => {
        this.isConnected = false;
      });
    } catch (err) {
      this.isConnected = false;
      console.warn(`ℹ️ [Redis Cache Notice] ${err.message}. Using fast in-memory cache.`);
    }
  }

  /**
   * Get value from Redis or in-memory fallback
   */
  async get(key) {
    if (this.isConnected && this.client) {
      try {
        const raw = await this.client.get(key);
        if (!raw) return null;
        try {
          return JSON.parse(raw);
        } catch (_) {
          return raw;
        }
      } catch (err) {
        console.warn(`[Redis Get Error] ${err.message}`);
      }
    }

    // In-memory fallback
    const exp = this.memoryExpirations.get(key);
    if (exp && Date.now() > exp) {
      this.memoryCache.delete(key);
      this.memoryExpirations.delete(key);
      return null;
    }
    return this.memoryCache.get(key) ?? null;
  }

  /**
   * Set value in Redis with TTL (default 300 seconds = 5 minutes)
   */
  async set(key, value, ttlSeconds = 300) {
    const stringValue = typeof value === 'string' ? value : JSON.stringify(value);

    if (this.isConnected && this.client) {
      try {
        if (ttlSeconds > 0) {
          await this.client.set(key, stringValue, 'EX', ttlSeconds);
        } else {
          await this.client.set(key, stringValue);
        }
        return true;
      } catch (err) {
        console.warn(`[Redis Set Error] ${err.message}`);
      }
    }

    // In-memory fallback
    this.memoryCache.set(key, typeof value === 'string' ? value : JSON.parse(stringValue));
    if (ttlSeconds > 0) {
      this.memoryExpirations.set(key, Date.now() + ttlSeconds * 1000);
    }
    return true;
  }

  /**
   * Delete key from cache
   */
  async del(key) {
    if (this.isConnected && this.client) {
      try {
        await this.client.del(key);
      } catch (_) {}
    }
    this.memoryCache.delete(key);
    this.memoryExpirations.delete(key);
  }

  /**
   * Delete all keys matching a pattern (e.g. 'orders:*')
   */
  async delPattern(pattern) {
    if (this.isConnected && this.client) {
      try {
        const keys = await this.client.keys(pattern);
        if (keys && keys.length > 0) {
          await this.client.del(...keys);
        }
      } catch (_) {}
    }

    const regex = new RegExp('^' + pattern.replace(/\*/g, '.*') + '$');
    for (const k of this.memoryCache.keys()) {
      if (regex.test(k)) {
        this.memoryCache.delete(k);
        this.memoryExpirations.delete(k);
      }
    }
  }
}

module.exports = new RedisService();
