// Nutrition: daily food log, water, history, food search, recipes.
// A day is stored as user_records('nutrition_day', 'YYYY-MM-DD'), so it also
// syncs to the phone's SQLite like everything else.
const express = require('express');
const crypto = require('crypto');
const { query, one } = require('../db');
const { requireAuth } = require('../lib/auth');
const { cached } = require('../lib/cache');
const cache = require('../lib/cache');
const docs = require('../lib/docs');

const router = express.Router();
const COLL = 'nutrition_day';

const today = () => new Date().toISOString().slice(0, 10);
const validDate = (d) => (/^\d{4}-\d{2}-\d{2}$/.test(String(d || '')) ? String(d) : today());

/** Daily targets from the questionnaire (Mifflin-St Jeor), with safe defaults. */
function targetsFor(user) {
  const q = (user && user.questionnaire) || {};
  const p = (user && user.profile) || {};
  if (p.targetCalories) {
    return { targetCalories: Number(p.targetCalories), targetProtein: Number(p.targetProtein || 140), targetCarbs: Number(p.targetCarbs || 220), targetFat: Number(p.targetFat || 60) };
  }
  const num = (...keys) => { for (const k of keys) { const v = parseFloat(q[k] ?? p[k]); if (Number.isFinite(v) && v > 0) return v; } return null; };
  const weight = num('weight', 'currentWeight', 'weightKg') || 70;
  const height = num('height', 'heightCm') || 170;
  const age = num('age') || 28;
  const gender = String(q.gender || p.gender || 'male').toLowerCase();
  const goal = String(q.goal || q.primaryGoal || q.fitnessGoal || p.goal || '').toLowerCase();
  let bmr = 10 * weight + 6.25 * height - 5 * age + (gender.startsWith('f') ? -161 : 5);
  let kcal = bmr * 1.45;
  if (/lose|loss|fat|cut|slim/.test(goal)) kcal -= 450;
  else if (/gain|muscle|bulk|build/.test(goal)) kcal += 300;
  kcal = Math.round(Math.max(1300, Math.min(4000, kcal)) / 10) * 10;
  const protein = Math.round(weight * (/gain|muscle|build/.test(goal) ? 2 : 1.6));
  const fat = Math.round((kcal * 0.27) / 9);
  const carbs = Math.max(80, Math.round((kcal - protein * 4 - fat * 9) / 4));
  return { targetCalories: kcal, targetProtein: protein, targetCarbs: carbs, targetFat: fat };
}

function recalc(day) {
  let kcal = 0, p = 0, c = 0, f = 0, fi = 0;
  for (const m of day.meals || []) {
    kcal += Number(m.calories) || 0; p += Number(m.protein) || 0; c += Number(m.carbs) || 0; f += Number(m.fat) || 0; fi += Number(m.fiber) || 0;
  }
  Object.assign(day, { consumedCalories: Math.round(kcal), consumedProtein: +p.toFixed(1), consumedCarbs: +c.toFixed(1), consumedFat: +f.toFixed(1), consumedFiber: +fi.toFixed(1) });
  return day;
}

async function loadDay(userId, date) {
  const row = await one(`SELECT data FROM user_records WHERE user_id = $1 AND collection = $2 AND id = $3 AND NOT deleted`, [userId, COLL, date]);
  const user = await one('SELECT questionnaire, profile FROM users WHERE id = $1', [userId]);
  const t = targetsFor(user);
  const day = row ? { ...row.data } : { meals: [], waterGlasses: 0, waterMilliliters: 0, waterTargetGlasses: 10 };
  return recalc({ waterTargetGlasses: 10, ...day, ...t, uid: userId, date });
}

async function saveDay(userId, day) {
  await query(
    `INSERT INTO user_records (user_id, collection, id, data, client_updated_at) VALUES ($1, $2, $3, $4, now())
     ON CONFLICT (user_id, collection, id) DO UPDATE SET data = EXCLUDED.data, deleted = false, client_updated_at = now(), rev = nextval('rev_seq')`,
    [userId, COLL, day.date, day]
  );
}

const timeLabel = () => {
  const d = new Date(Date.now() + 5.5 * 3600 * 1000); // IST
  const h = d.getUTCHours(); const m = String(d.getUTCMinutes()).padStart(2, '0');
  return `${h % 12 === 0 ? 12 : h % 12}:${m} ${h < 12 ? 'AM' : 'PM'}`;
};

router.get('/user-nutrition/today', requireAuth, async (req, res) => {
  res.json({ success: true, nutrition: await loadDay(req.user.id, validDate(req.query.date)) });
});

router.get('/user-nutrition/history', requireAuth, async (req, res) => {
  const start = /^\d{4}-\d{2}-\d{2}$/.test(req.query.startDate || '') ? req.query.startDate : new Date(Date.now() - 90 * 864e5).toISOString().slice(0, 10);
  const end = /^\d{4}-\d{2}-\d{2}$/.test(req.query.endDate || '') ? req.query.endDate : today();
  const { rows } = await query(
    `SELECT id, data FROM user_records WHERE user_id = $1 AND collection = $2 AND id BETWEEN $3 AND $4 AND NOT deleted`,
    [req.user.id, COLL, start, end]
  );
  const history = {};
  for (const r of rows) {
    const d = recalc({ ...r.data });
    const logged = (d.meals || []).length > 0 || (d.waterGlasses || 0) > 0;
    if (logged) history[r.id] = { hasLogged: true, consumedCalories: d.consumedCalories, waterGlasses: d.waterGlasses || 0, meals: (d.meals || []).length };
  }
  res.json({ success: true, history });
});

router.post('/user-nutrition/log-meal', requireAuth, async (req, res) => {
  const b = req.body || {};
  const day = await loadDay(req.user.id, validDate(b.date));
  const qty = Number(b.quantity) > 0 ? Number(b.quantity) : 1;
  const meal = {
    mealId: String(b.mealId || `meal_${Date.now().toString(36)}${crypto.randomBytes(2).toString('hex')}`),
    mealType: String(b.mealType || 'snack'),
    foodName: String(b.foodName || b.name || 'Meal'),
    source: String(b.source || 'Manual'),
    category: String(b.category || 'General'),
    calories: Math.round((Number(b.calories) || 0) * qty),
    protein: +((Number(b.protein) || 0) * qty).toFixed(1),
    carbs: +((Number(b.carbs) || 0) * qty).toFixed(1),
    fat: +((Number(b.fat) || 0) * qty).toFixed(1),
    fiber: +((Number(b.fiber) || 0) * qty).toFixed(1),
    servingSize: String(b.servingSize || '1 serving'),
    quantity: qty,
    time: String(b.time || timeLabel()),
    iconType: String(b.iconType || 'restaurant'),
  };
  // Replays from the offline queue carry the same mealId: don't double count.
  day.meals = (day.meals || []).filter((m) => m.mealId !== meal.mealId);
  day.meals.push(meal);
  recalc(day);
  await saveDay(req.user.id, day);
  res.json({ success: true, nutrition: day, meal });
});

router.delete('/user-nutrition/meal/:uid/:mealId', requireAuth, async (req, res) => {
  const day = await loadDay(req.user.id, validDate(req.query.date));
  let found = day.meals.some((m) => m.mealId === req.params.mealId);
  if (!found && !req.query.date) {
    // The app may not send the date: look through the last 14 days.
    const { rows } = await query(
      `SELECT id FROM user_records WHERE user_id = $1 AND collection = $2 AND data->'meals' @> $3::jsonb ORDER BY id DESC LIMIT 1`,
      [req.user.id, COLL, JSON.stringify([{ mealId: req.params.mealId }])]
    );
    if (rows[0]) {
      const other = await loadDay(req.user.id, rows[0].id);
      other.meals = other.meals.filter((m) => m.mealId !== req.params.mealId);
      recalc(other);
      await saveDay(req.user.id, other);
      return res.json({ success: true, nutrition: other });
    }
  }
  day.meals = day.meals.filter((m) => m.mealId !== req.params.mealId);
  recalc(day);
  await saveDay(req.user.id, day);
  res.json({ success: true, nutrition: day });
});

router.post('/user-nutrition/water', requireAuth, async (req, res) => {
  const b = req.body || {};
  const day = await loadDay(req.user.id, validDate(b.date));
  if (b.milliliters !== undefined || b.waterMilliliters !== undefined) {
    const ml = Math.max(0, Number(b.milliliters ?? b.waterMilliliters) || 0);
    day.waterMilliliters = ml;
    day.waterGlasses = Math.round(ml / 250);
  } else if (b.glasses !== undefined) {
    const g = Math.max(0, Number(b.glasses) || 0);
    day.waterGlasses = g;
    day.waterMilliliters = g * 250;
  } else if (b.addMl !== undefined) {
    day.waterMilliliters = Math.max(0, (day.waterMilliliters || 0) + Number(b.addMl));
    day.waterGlasses = Math.round(day.waterMilliliters / 250);
  }
  if (b.targetGlasses) day.waterTargetGlasses = Number(b.targetGlasses);
  await saveDay(req.user.id, day);
  res.json({ success: true, nutrition: day });
});

// ------------------------------ foods ------------------------------
const fetchJson = async (url, ms = 6000) => {
  const ctl = new AbortController();
  const t = setTimeout(() => ctl.abort(), ms);
  try {
    const r = await fetch(url, { signal: ctl.signal, headers: { 'User-Agent': 'NeuroFitApp/2.0 (fitness app)' } });
    return r.ok ? await r.json() : null;
  } catch (_) { return null; } finally { clearTimeout(t); }
};

async function searchOpenFoodFacts(q) {
  const j = await fetchJson(`https://world.openfoodfacts.org/cgi/search.pl?search_terms=${encodeURIComponent(q)}&search_simple=1&action=process&json=1&page_size=25&fields=code,product_name,brands,nutriments,serving_size,image_small_url,categories_tags`);
  return ((j && j.products) || []).filter((p) => p.product_name && p.nutriments).map((p) => {
    const n = p.nutriments;
    const per = n['energy-kcal_serving'] ? 'serving' : '100g';
    const g = (k) => +(Number(n[`${k}_${per}`] ?? n[`${k}_100g`] ?? 0)).toFixed(1);
    return {
      id: `off_${p.code}`, name: p.product_name, title: p.product_name, brand: p.brands || '',
      calories: Math.round(Number(n[`energy-kcal_${per}`] ?? n['energy-kcal_100g'] ?? 0)),
      protein: g('proteins'), carbs: g('carbohydrates'), fat: g('fat'), fiber: g('fiber'),
      servingSize: per === 'serving' ? (p.serving_size || '1 serving') : '100 g',
      category: 'Packaged', source: 'Open Food Facts', imageUrl: p.image_small_url || '',
    };
  }).filter((f) => f.calories > 0);
}

async function searchUsda(q) {
  const key = process.env.USDA_API_KEY;
  if (!key) return [];
  const j = await fetchJson(`https://api.nal.usda.gov/fdc/v1/foods/search?api_key=${key}&query=${encodeURIComponent(q)}&pageSize=20&dataType=Foundation,SR%20Legacy,Survey%20(FNDDS)`);
  return ((j && j.foods) || []).map((f) => {
    const val = (id) => { const x = (f.foodNutrients || []).find((n) => n.nutrientId === id || n.nutrientNumber === String(id)); return x ? +Number(x.value).toFixed(1) : 0; };
    return {
      id: `usda_${f.fdcId}`, name: f.description, title: f.description, brand: f.brandOwner || '',
      calories: Math.round(val(1008)), protein: val(1003), carbs: val(1005), fat: val(1004), fiber: val(1079),
      servingSize: '100 g', category: f.foodCategory || 'General', source: 'USDA',
    };
  }).filter((f) => f.calories > 0);
}

router.get('/foods/search-live', cached(['foods'], 24 * 3600), async (req, res) => {
  const q = String(req.query.query || req.query.q || '').trim().slice(0, 60) || 'healthy';
  const own = (await docs.list('foods', { search: q === 'healthy' ? undefined : q, searchFields: ['name', 'title', 'category'], limit: 30 })).map((r) => ({ ...docs.toItem(r), source: r.data.source || 'NeuroFit' }));
  const [usda, off] = await Promise.all([searchUsda(q), own.length >= 15 ? [] : searchOpenFoodFacts(q)]);
  const seen = new Set();
  const data = [...own, ...usda, ...off].filter((f) => { const k = String(f.name).toLowerCase(); if (seen.has(k)) return false; seen.add(k); return true; }).slice(0, 50);
  res.json({ success: true, count: data.length, data });
});
router.get('/foods/search', (req, res, next) => { req.url = '/foods/search-live' + (req.url.split('?')[1] ? `?${req.url.split('?')[1]}` : ''); next(); });

// ------------------------------ recipes ------------------------------
router.get('/recipes/daily-featured', cached(['recipes'], 6 * 3600), async (_req, res) => {
  const own = (await docs.list('recipes', { limit: 200 })).map((r) => docs.toItem(r)).filter((r) => r.isActive !== false);
  let recipes;
  if (own.length) {
    const day = Math.floor(Date.now() / 864e5);
    recipes = own.filter((r) => r.isFeatured).concat(own).filter((r, i, a) => a.indexOf(r) === i);
    if (recipes.length > 8) recipes = Array.from({ length: 8 }, (_, i) => recipes[(day + i) % recipes.length]);
  } else {
    recipes = [];
  }
  res.json({ success: true, recipes, data: recipes });
});

router.get('/user-nutrition/suggestions', requireAuth, cached(['recipes', 'foods'], 3600, { perUser: true }), async (req, res) => {
  const day = await loadDay(req.user.id, today());
  const left = Math.max(0, day.targetCalories - day.consumedCalories);
  const foods = (await docs.list('foods', { limit: 300 })).map((r) => docs.toItem(r));
  const pick = (type, share) => {
    const budget = Math.round(left * share);
    const pool = foods.filter((f) => !f.mealType || String(f.mealType).toLowerCase() === type);
    return pool.filter((f) => Number(f.calories) <= Math.max(budget, 150)).slice(0, 4);
  };
  res.json({
    success: true,
    caloriesLeft: left,
    suggestions: { breakfast: pick('breakfast', 0.25), lunch: pick('lunch', 0.35), snack: pick('snack', 0.1), dinner: pick('dinner', 0.3) },
  });
});

module.exports = { router, targetsFor, loadDay };
