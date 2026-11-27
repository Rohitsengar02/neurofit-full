// All settings come from environment variables (Render → Environment).
const env = process.env;

const list = (v) => (v || '').split(',').map((s) => s.trim()).filter(Boolean);

module.exports = {
  port: Number(env.PORT || 5000),
  isProd: env.NODE_ENV === 'production',
  databaseUrl: env.DATABASE_URL || 'postgres://postgres@localhost:5433/neurofit',
  dbPoolMax: Number(env.DB_POOL_MAX || 10),
  jwtSecret: env.JWT_SECRET || 'dev-only-secret-change-me',
  accessTtl: env.ACCESS_TOKEN_TTL || '1h',
  refreshDays: Number(env.REFRESH_TOKEN_DAYS || 60),
  googleClientIds: list(env.GOOGLE_CLIENT_IDS || env.GOOGLE_WEB_CLIENT_ID),
  adminEmail: (env.ADMIN_EMAIL || '').toLowerCase(),
  adminPassword: env.ADMIN_PASSWORD || '',
  redisUrl: env.REDIS_URL || '',
  r2: {
    accountId: env.R2_ACCOUNT_ID || '',
    accessKeyId: env.R2_ACCESS_KEY_ID || '',
    secretAccessKey: env.R2_SECRET_ACCESS_KEY || '',
    bucket: env.R2_BUCKET || '',
    publicUrl: (env.R2_PUBLIC_URL || '').replace(/\/+$/, ''),
  },
  livekit: {
    url: env.LIVEKIT_URL || '',
    apiKey: env.LIVEKIT_API_KEY || '',
    apiSecret: env.LIVEKIT_API_SECRET || '',
  },
  corsOrigins: list(env.CORS_ORIGINS),
};
