// Tiny event counter: POST /api/track { event: 'product_view', id }.
// The app fires it and forgets; one upsert per call, no per-user rows, so it stays cheap at scale.
const express = require('express');
const { query } = require('../db');

const ALLOWED = new Set(['product_view', 'product_add_to_cart', 'workout_view', 'recipe_view', 'trainer_view', 'banner_click']);
const router = express.Router();

router.post('/', async (req, res) => {
  const list = Array.isArray(req.body) ? req.body.slice(0, 50) : [req.body || {}];
  const rows = list.filter((e) => ALLOWED.has(e.event)).map((e) => [e.event, String(e.id || '').slice(0, 80), Math.min(Number(e.count) || 1, 100)]);
  for (const [event, ref, n] of rows) {
    await query(
      `INSERT INTO counters (event, ref, n) VALUES ($1, $2, $3)
       ON CONFLICT (event, ref, day) DO UPDATE SET n = counters.n + EXCLUDED.n`, [event, ref, n]);
  }
  res.status(202).json({ success: true, counted: rows.length });
});

module.exports = { router };
