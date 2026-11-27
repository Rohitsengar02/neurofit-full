const { Pool, types } = require('pg');
const config = require('./config');

// Return bigint / numeric as JS numbers (counts, revs) instead of strings.
types.setTypeParser(20, (v) => Number(v));
types.setTypeParser(1700, (v) => Number(v));

const needsSsl = /neon\.tech|supabase|sslmode=require|render\.com/.test(config.databaseUrl) &&
  !/\.internal|localhost|127\.0\.0\.1/.test(config.databaseUrl);

const pool = new Pool({
  connectionString: config.databaseUrl,
  max: config.dbPoolMax,
  idleTimeoutMillis: 30_000,
  connectionTimeoutMillis: 15_000,
  ssl: needsSsl ? { rejectUnauthorized: false } : undefined,
});

pool.on('error', (err) => console.error('[db] idle client error', err.message));

const query = (text, params) => pool.query(text, params);

async function one(text, params) {
  const r = await pool.query(text, params);
  return r.rows[0] || null;
}

async function tx(fn) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const out = await fn(client);
    await client.query('COMMIT');
    return out;
  } catch (e) {
    await client.query('ROLLBACK').catch(() => {});
    throw e;
  } finally {
    client.release();
  }
}

module.exports = { pool, query, one, tx };
