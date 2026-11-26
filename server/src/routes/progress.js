// Workout day progress (user-workouts/*). Stored as user_records('workout_progress').
const express = require('express');
const { query, one } = require('../db');
const { requireAuth } = require('../lib/auth');

const router = express.Router();
const COLL = 'workout_progress';
const key = (w, d) => `${w}_${d}`;

async function load(userId, workoutId, day) {
  const row = await one(`SELECT data FROM user_records WHERE user_id = $1 AND collection = $2 AND id = $3 AND NOT deleted`, [userId, COLL, key(workoutId, day)]);
  return row ? row.data : null;
}

async function save(userId, p) {
  await query(
    `INSERT INTO user_records (user_id, collection, id, data, client_updated_at) VALUES ($1, $2, $3, $4, now())
     ON CONFLICT (user_id, collection, id) DO UPDATE SET data = EXCLUDED.data, deleted = false, client_updated_at = now(), rev = nextval('rev_seq')`,
    [userId, COLL, key(p.workoutId, p.dayNumber), p]
  );
  return p;
}

const blank = (uid, b) => ({
  uid, workoutId: String(b.workoutId), workoutTitle: b.workoutTitle || 'Workout', dayNumber: Number(b.dayNumber) || 1,
  weekNumber: Number(b.weekNumber) || 1, status: 'not_started', currentExerciseIndex: 0, currentSetIndex: 0,
  totalDurationSeconds: 0, completedExercises: [], dayCompleted: false,
});

router.get('/progress/:uid/:workoutId/:day', requireAuth, async (req, res) => {
  const p = (await load(req.user.id, req.params.workoutId, Number(req.params.day))) || blank(req.user.id, { workoutId: req.params.workoutId, dayNumber: req.params.day });
  res.json({ success: true, userWorkout: p });
});

router.get('/', requireAuth, async (req, res) => {
  const { rows } = await query(`SELECT data FROM user_records WHERE user_id = $1 AND collection = $2 AND NOT deleted ORDER BY client_updated_at DESC LIMIT 500`, [req.user.id, COLL]);
  res.json({ success: true, data: rows.map((r) => r.data) });
});

router.post('/start', requireAuth, async (req, res) => {
  const b = req.body || {};
  if (!b.workoutId) return res.status(400).json({ success: false, message: 'workoutId required' });
  const cur = (await load(req.user.id, b.workoutId, Number(b.dayNumber) || 1)) || blank(req.user.id, b);
  const p = { ...cur, workoutTitle: b.workoutTitle || cur.workoutTitle, weekNumber: Number(b.weekNumber) || cur.weekNumber,
    totalExercisesCount: Number(b.totalExercisesCount) || (b.exercises || []).length || cur.totalExercisesCount || 0,
    status: cur.dayCompleted ? 'completed' : 'in_progress', startedAt: cur.startedAt || new Date().toISOString() };
  res.json({ success: true, userWorkout: await save(req.user.id, p) });
});

router.post('/progress', requireAuth, async (req, res) => {
  const b = req.body || {};
  if (!b.workoutId) return res.status(400).json({ success: false, message: 'workoutId required' });
  const cur = (await load(req.user.id, b.workoutId, Number(b.dayNumber) || 1)) || blank(req.user.id, b);
  const done = new Set(cur.completedExercises || []);
  if (b.completedExerciseId) {
    if (b.isExerciseCompleted === false) done.delete(String(b.completedExerciseId));
    else done.add(String(b.completedExerciseId));
  }
  const p = { ...cur, completedExercises: [...done] };
  for (const k of ['currentExerciseIndex', 'currentSetIndex', 'totalDurationSeconds']) if (b[k] !== undefined) p[k] = Number(b[k]) || 0;
  if (b.dayCompleted !== undefined) p.dayCompleted = !!b.dayCompleted;
  if (b.caloriesBurned !== undefined) p.caloriesBurned = Number(b.caloriesBurned) || 0;
  p.status = p.dayCompleted ? 'completed' : 'in_progress';
  if (p.dayCompleted && !cur.dayCompleted) p.completedAt = new Date().toISOString();
  res.json({ success: true, userWorkout: await save(req.user.id, p) });
});

router.post('/reset', requireAuth, async (req, res) => {
  const b = req.body || {};
  if (!b.workoutId) return res.status(400).json({ success: false, message: 'workoutId required' });
  res.json({ success: true, userWorkout: await save(req.user.id, blank(req.user.id, b)) });
});

module.exports = { router };
