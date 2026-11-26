// Admin dashboard numbers. Everything here is computed from real data.
const express = require('express');
const { query, one } = require('../db');
const { requireAdmin } = require('../lib/auth');
const { cached } = require('../lib/cache');
const { adminLogin } = require('./auth');

const router = express.Router();

router.post('/login', adminLogin);

const days = (n) => `now() - interval '${Number(n)} days'`;

async function series(sql, params = [], n = 30) {
  const { rows } = await query(sql, params);
  const map = Object.fromEntries(rows.map((r) => [r.day.toISOString().slice(0, 10), Number(r.v)]));
  const out = [];
  for (let i = n - 1; i >= 0; i--) {
    const d = new Date(Date.now() - i * 864e5).toISOString().slice(0, 10);
    out.push({ date: d, value: map[d] || 0 });
  }
  return out;
}

router.get('/stats', requireAdmin, cached(['users', 'orders', 'posts', 'trainers', 'trainer_subscriptions', 'workouts', 'exercises', 'products', 'live_sessions'], 60), async (_req, res) => {
  const [users, orders, catalog, community, trainers, fitness, nutrition] = await Promise.all([
    one(`SELECT count(*)::int AS total,
           count(*) FILTER (WHERE created_at > now() - interval '1 day')::int AS new_today,
           count(*) FILTER (WHERE created_at > ${days(7)})::int AS new_7d,
           count(*) FILTER (WHERE created_at > ${days(30)})::int AS new_30d,
           count(*) FILTER (WHERE last_active_at > now() - interval '1 day')::int AS dau,
           count(*) FILTER (WHERE last_active_at > ${days(7)})::int AS wau,
           count(*) FILTER (WHERE last_active_at > ${days(30)})::int AS mau,
           count(*) FILTER (WHERE last_active_at > now() - interval '15 minutes')::int AS online,
           count(*) FILTER (WHERE is_premium)::int AS premium,
           count(*) FILTER (WHERE role = 'trainer')::int AS trainers,
           count(*) FILTER (WHERE role = 'vendor')::int AS vendors,
           count(*) FILTER (WHERE status <> 'active')::int AS suspended,
           count(*) FILTER (WHERE NOT is_verified)::int AS unverified,
           count(*) FILTER (WHERE auth_provider = 'google')::int AS google,
           count(*) FILTER (WHERE has_completed_onboarding)::int AS onboarded
         FROM users WHERE role NOT IN ('admin','superadmin')`),
    one(`SELECT count(*)::int AS total,
           COALESCE(sum((data->>'totalAmount')::numeric) FILTER (WHERE data->>'orderStatus' NOT IN ('Cancelled','Returned')), 0) AS revenue,
           COALESCE(sum((data->>'totalAmount')::numeric) FILTER (WHERE created_at > now() - interval '1 day' AND data->>'orderStatus' NOT IN ('Cancelled','Returned')), 0) AS revenue_today,
           COALESCE(sum((data->>'totalAmount')::numeric) FILTER (WHERE created_at > ${days(30)} AND data->>'orderStatus' NOT IN ('Cancelled','Returned')), 0) AS revenue_30d,
           count(*) FILTER (WHERE created_at > now() - interval '1 day')::int AS today,
           count(*) FILTER (WHERE data->>'orderStatus' IN ('Pending','Confirmed','Processing','Packed'))::int AS open,
           count(*) FILTER (WHERE data->>'orderStatus' = 'Delivered')::int AS delivered,
           count(*) FILTER (WHERE data->>'orderStatus' = 'Cancelled')::int AS cancelled,
           count(*) FILTER (WHERE data->>'orderStatus' = 'Returned')::int AS returned
         FROM docs WHERE collection = 'orders' AND (NOT (data ? 'totalAmount') OR data->>'totalAmount' ~ '^[0-9.]+$')`),
    one(`SELECT count(*) FILTER (WHERE collection = 'products')::int AS products,
           count(*) FILTER (WHERE collection = 'products' AND COALESCE((data->>'stock')::int, 999) <= COALESCE((data->>'lowStockThreshold')::int, 5))::int AS low_stock,
           count(*) FILTER (WHERE collection = 'categories')::int AS categories,
           count(*) FILTER (WHERE collection = 'workouts')::int AS workouts,
           count(*) FILTER (WHERE collection = 'exercises')::int AS exercises,
           count(*) FILTER (WHERE collection = 'fitness_programs')::int AS programs,
           count(*) FILTER (WHERE collection = 'recipes')::int AS recipes,
           count(*) FILTER (WHERE collection = 'foods')::int AS foods,
           count(*) FILTER (WHERE collection = 'diet_plans')::int AS diet_plans,
           count(*) FILTER (WHERE collection = 'discounts')::int AS coupons
         FROM docs WHERE collection IN ('products','categories','workouts','exercises','fitness_programs','recipes','foods','diet_plans','discounts')`),
    one(`SELECT count(*) FILTER (WHERE collection = 'posts')::int AS posts,
           count(*) FILTER (WHERE collection = 'comments')::int AS comments,
           count(*) FILTER (WHERE collection = 'posts' AND created_at > now() - interval '1 day')::int AS posts_today,
           (SELECT count(DISTINCT target_id)::int FROM reactions WHERE kind = 'report') AS reported
         FROM docs WHERE collection IN ('posts','comments')`),
    one(`SELECT count(*) FILTER (WHERE collection = 'trainers' AND data->>'status' = 'approved')::int AS approved,
           count(*) FILTER (WHERE collection = 'trainers' AND data->>'status' = 'pending')::int AS pending,
           count(*) FILTER (WHERE collection = 'trainer_subscriptions' AND (data->>'until')::timestamptz > now() AND data->>'status' <> 'cancelled')::int AS active_subs,
           COALESCE(sum((data->>'amount')::numeric) FILTER (WHERE collection = 'trainer_subscriptions'), 0) AS sub_revenue,
           count(*) FILTER (WHERE collection = 'live_sessions' AND data->>'status' = 'live')::int AS live_now,
           count(*) FILTER (WHERE collection = 'live_sessions')::int AS sessions
         FROM docs WHERE collection IN ('trainers','trainer_subscriptions','live_sessions')`),
    one(`SELECT count(*) FILTER (WHERE data->>'dayCompleted' = 'true')::int AS completed,
           count(*)::int AS started,
           count(DISTINCT user_id)::int AS athletes,
           COALESCE(sum((data->>'totalDurationSeconds')::int), 0)::bigint AS seconds
         FROM user_records WHERE collection = 'workout_progress'`),
    one(`SELECT count(*)::int AS days_logged, count(DISTINCT user_id)::int AS users,
           COALESCE(sum(jsonb_array_length(COALESCE(data->'meals','[]'::jsonb))), 0)::int AS meals,
           COALESCE(avg((data->>'consumedCalories')::numeric) FILTER (WHERE (data->>'consumedCalories')::numeric > 0), 0) AS avg_kcal,
           COALESCE(avg((data->>'waterGlasses')::numeric) FILTER (WHERE (data->>'waterGlasses')::numeric > 0), 0) AS avg_water
         FROM user_records WHERE collection = 'nutrition_day'`),
  ]);

  const [signups, active, revenue, orderCount, workoutsDone, statusRows, topProducts, topWorkouts, goals, gender, ages, cities, recent, steps, calories] = await Promise.all([
    series(`SELECT date_trunc('day', created_at) AS day, count(*) AS v FROM users WHERE created_at > ${days(30)} GROUP BY 1`),
    series(`SELECT date_trunc('day', last_active_at) AS day, count(*) AS v FROM users WHERE last_active_at > ${days(30)} GROUP BY 1`),
    series(`SELECT date_trunc('day', created_at) AS day, COALESCE(sum((data->>'totalAmount')::numeric), 0) AS v FROM docs WHERE collection = 'orders' AND created_at > ${days(30)} AND data->>'totalAmount' ~ '^[0-9.]+$' AND data->>'orderStatus' NOT IN ('Cancelled','Returned') GROUP BY 1`),
    series(`SELECT date_trunc('day', created_at) AS day, count(*) AS v FROM docs WHERE collection = 'orders' AND created_at > ${days(30)} GROUP BY 1`),
    series(`SELECT date_trunc('day', client_updated_at) AS day, count(*) AS v FROM user_records WHERE collection = 'workout_progress' AND data->>'dayCompleted' = 'true' AND client_updated_at > ${days(30)} GROUP BY 1`),
    query(`SELECT COALESCE(data->>'orderStatus','Pending') AS status, count(*)::int AS n FROM docs WHERE collection = 'orders' GROUP BY 1 ORDER BY 2 DESC`),
    query(`SELECT it->>'name' AS name, COALESCE(it->>'productId', it->>'id') AS id, max(COALESCE(it->>'image', it->>'imageUrl', '')) AS image, sum(COALESCE((it->>'quantity')::int, 1))::int AS qty,
             sum(COALESCE((it->>'price')::numeric, 0) * COALESCE((it->>'quantity')::int, 1)) AS revenue
           FROM docs, jsonb_array_elements(CASE WHEN jsonb_typeof(data->'items') = 'array' THEN data->'items' ELSE '[]'::jsonb END) it
           WHERE collection = 'orders' GROUP BY 1, 2 ORDER BY qty DESC LIMIT 10`),
    query(`SELECT data->>'workoutId' AS id, max(data->>'workoutTitle') AS title, count(DISTINCT user_id)::int AS athletes,
             count(*) FILTER (WHERE data->>'dayCompleted' = 'true')::int AS completed
           FROM user_records WHERE collection = 'workout_progress' GROUP BY 1 ORDER BY athletes DESC LIMIT 10`),
    query(`SELECT COALESCE(questionnaire->>'goal', questionnaire->>'primaryGoal', questionnaire->>'fitnessGoal', 'Not set') AS goal, count(*)::int AS n
           FROM users WHERE role NOT IN ('admin','superadmin') GROUP BY 1 ORDER BY 2 DESC LIMIT 8`),
    query(`SELECT CASE WHEN lower(COALESCE(questionnaire->>'gender', profile->>'gender', '')) LIKE 'f%' THEN 'Female'
                       WHEN lower(COALESCE(questionnaire->>'gender', profile->>'gender', '')) LIKE 'm%' THEN 'Male'
                       WHEN COALESCE(questionnaire->>'gender', profile->>'gender', '') = '' THEN 'Not set' ELSE 'Other' END AS label, count(*)::int AS n
           FROM users WHERE role NOT IN ('admin','superadmin') GROUP BY 1 ORDER BY 2 DESC`),
    query(`SELECT CASE WHEN a < 18 THEN 'Under 18' WHEN a < 25 THEN '18-24' WHEN a < 35 THEN '25-34' WHEN a < 45 THEN '35-44' WHEN a < 55 THEN '45-54' ELSE '55+' END AS label, count(*)::int AS n
           FROM (SELECT NULLIF(regexp_replace(COALESCE(questionnaire->>'age', profile->>'age', ''), '[^0-9]', '', 'g'), '')::int AS a FROM users WHERE role NOT IN ('admin','superadmin')) x
           WHERE a IS NOT NULL GROUP BY 1 ORDER BY 2 DESC`),
    query(`SELECT initcap(COALESCE(NULLIF(addresses->0->>'city', ''), NULLIF(profile->>'city', ''), 'Unknown')) AS label, count(*)::int AS n
           FROM users WHERE role NOT IN ('admin','superadmin') GROUP BY 1 ORDER BY (initcap(COALESCE(NULLIF(addresses->0->>'city', ''), NULLIF(profile->>'city', ''), 'Unknown')) = 'Unknown'), 2 DESC LIMIT 5`),
    query(`(SELECT 'user' AS kind, name AS title, email AS detail, created_at AS at, id FROM users WHERE role NOT IN ('admin','superadmin') ORDER BY created_at DESC LIMIT 6)
           UNION ALL (SELECT 'order', COALESCE(data->>'customerName', 'Customer'), id || ' · ₹' || COALESCE(data->>'totalAmount', '0'), created_at, id FROM docs WHERE collection = 'orders' ORDER BY created_at DESC LIMIT 6)
           UNION ALL (SELECT 'trainer', COALESCE(data->>'name', 'Coach'), COALESCE(data->>'status', 'pending'), created_at, id FROM docs WHERE collection = 'trainers' ORDER BY created_at DESC LIMIT 4)
           UNION ALL (SELECT 'subscription', COALESCE(data->>'userName', 'Member'), COALESCE(data->>'trainerName', '') || ' · ' || COALESCE(data->>'planName', ''), created_at, id FROM docs WHERE collection = 'trainer_subscriptions' ORDER BY created_at DESC LIMIT 4)
           ORDER BY at DESC LIMIT 12`),
    one(`SELECT COALESCE(sum(NULLIF(regexp_replace(COALESCE(data->>'steps', '0'), '[^0-9]', '', 'g'), '')::bigint), 0)::bigint AS total FROM user_records WHERE collection = 'steps_day'`),
    one(`SELECT COALESCE(sum((data->>'caloriesBurned')::numeric), 0)::bigint AS total FROM user_records WHERE collection = 'workout_progress' AND data->>'caloriesBurned' ~ '^[0-9.]+$'`),
  ]);

  const revenueNum = Number(orders.revenue);
  res.json({
    success: true,
    generatedAt: new Date().toISOString(),
    data: {
      users: { ...users, conversion: users.total ? +((users.premium / users.total) * 100).toFixed(1) : 0 },
      orders: { ...orders, revenue: revenueNum, revenue_today: Number(orders.revenue_today), revenue_30d: Number(orders.revenue_30d), avg_order_value: orders.total ? Math.round(revenueNum / orders.total) : 0 },
      catalog, community, fitness: { ...fitness, minutes: Math.round(Number(fitness.seconds) / 60) },
      nutrition: { ...nutrition, avg_kcal: Math.round(Number(nutrition.avg_kcal)), avg_water: +Number(nutrition.avg_water).toFixed(1) },
      trainers: { ...trainers, sub_revenue: Number(trainers.sub_revenue) },
      series: { signups, active, revenue, orders: orderCount, workoutsDone },
      ordersByStatus: statusRows.rows,
      topProducts: topProducts.rows.map((r) => ({ ...r, revenue: Number(r.revenue) })),
      topWorkouts: topWorkouts.rows,
      goals: goals.rows,
      demographics: { gender: gender.rows, ages: ages.rows, cities: cities.rows },
      recentActivity: recent.rows,
      activity: { steps: Number(steps.total), caloriesBurned: Number(calories.total) },
    },
  });
});

// Everything about one user, for the user detail sheet.
router.get('/users/:uid/overview', requireAdmin, async (req, res) => {
  const uid = req.params.uid;
  const u = await one('SELECT * FROM users WHERE id = $1', [uid]);
  if (!u) return res.status(404).json({ success: false, message: 'User not found' });
  const [orders, ordersAgg, progress, progressAgg, sub, nutrition, streakDays] = await Promise.all([
    query(`SELECT * FROM docs WHERE collection = 'orders' AND owner_id = $1 ORDER BY created_at DESC LIMIT 5`, [uid]),
    one(`SELECT count(*)::int AS n, COALESCE(sum((data->>'totalAmount')::numeric) FILTER (WHERE data->>'totalAmount' ~ '^[0-9.]+$'), 0) AS spend FROM docs WHERE collection = 'orders' AND owner_id = $1`, [uid]),
    query(`SELECT data, client_updated_at FROM user_records WHERE user_id = $1 AND collection = 'workout_progress' ORDER BY client_updated_at DESC LIMIT 5`, [uid]),
    one(`SELECT count(*) FILTER (WHERE data->>'dayCompleted' = 'true')::int AS completed, COALESCE(sum((data->>'totalDurationSeconds')::int), 0)::bigint AS seconds,
           COALESCE(sum((data->>'caloriesBurned')::numeric) FILTER (WHERE data->>'caloriesBurned' ~ '^[0-9.]+$'), 0) AS kcal
         FROM user_records WHERE user_id = $1 AND collection = 'workout_progress'`, [uid]),
    one(`SELECT * FROM docs WHERE collection = 'trainer_subscriptions' AND owner_id = $1 ORDER BY created_at DESC LIMIT 1`, [uid]),
    one(`SELECT data FROM user_records WHERE user_id = $1 AND collection = 'nutrition_day' ORDER BY id DESC LIMIT 1`, [uid]),
    query(`SELECT DISTINCT date_trunc('day', client_updated_at)::date AS d FROM user_records WHERE user_id = $1 AND client_updated_at > now() - interval '120 days' ORDER BY d DESC`, [uid]),
  ]);
  let streak = 0;
  const today = new Date(); today.setUTCHours(0, 0, 0, 0);
  for (const r of streakDays.rows) {
    const d = new Date(r.d); d.setUTCHours(0, 0, 0, 0);
    if (Math.round((today - d) / 864e5) === streak) streak++; else break;
  }
  const { userJson } = require('../lib/auth');
  const docs = require('../lib/docs');
  const { targetsFor } = require('./nutrition');
  res.json({ success: true, data: {
    user: userJson(u),
    targets: targetsFor(u),
    orders: orders.rows.map((r) => docs.toItem(r, 'orderId')),
    orderCount: ordersAgg.n, spend: Number(ordersAgg.spend),
    workouts: { completed: progressAgg.completed, minutes: Math.round(Number(progressAgg.seconds) / 60), calories: Number(progressAgg.kcal), streak,
      recent: progress.rows.map((r) => ({ ...r.data, at: r.client_updated_at })) },
    subscription: sub ? docs.toItem(sub) : null,
    lastNutrition: nutrition ? nutrition.data : null,
  } });
});

// User lists for the admin "New / Active / Premium" screens, with each user's
// workouts, streak, spend and trainer subscription in one call.
router.get('/user-list', requireAdmin, cached(['users', 'orders', 'trainer_subscriptions'], 30), async (req, res) => {
  const seg = String(req.query.segment || 'all');
  const limit = Math.min(Number(req.query.limit) || 200, 500);
  const where = [`role NOT IN ('admin','superadmin')`];
  if (seg === 'new') where.push(`created_at > now() - interval '30 days'`);
  if (seg === 'active') where.push(`last_active_at > now() - interval '7 days'`);
  if (seg === 'premium') where.push(`(is_premium OR id IN (SELECT owner_id FROM docs WHERE collection = 'trainer_subscriptions' AND owner_id IS NOT NULL))`);
  if (seg === 'unverified') where.push('NOT is_verified');
  if (seg === 'suspended') where.push(`status <> 'active'`);
  const order = seg === 'active' ? 'last_active_at DESC NULLS LAST' : 'created_at DESC';
  const users = (await query(`SELECT * FROM users WHERE ${where.join(' AND ')} ORDER BY ${order} LIMIT ${limit}`)).rows;
  const ids = users.map((u) => u.id);
  if (!ids.length) return res.json({ success: true, data: [] });
  const [w, o, s, d] = await Promise.all([
    query(`SELECT user_id, count(*) FILTER (WHERE data->>'dayCompleted' = 'true')::int AS done FROM user_records WHERE collection = 'workout_progress' AND user_id = ANY($1) GROUP BY user_id`, [ids]),
    query(`SELECT owner_id, count(*)::int AS n, COALESCE(sum((data->>'totalAmount')::numeric) FILTER (WHERE data->>'totalAmount' ~ '^[0-9.]+$'), 0) AS spend FROM docs WHERE collection = 'orders' AND owner_id = ANY($1) GROUP BY owner_id`, [ids]),
    query(`SELECT DISTINCT ON (owner_id) owner_id, data FROM docs WHERE collection = 'trainer_subscriptions' AND owner_id = ANY($1) ORDER BY owner_id, created_at DESC`, [ids]),
    query(`SELECT DISTINCT user_id, date_trunc('day', client_updated_at)::date AS d FROM user_records WHERE user_id = ANY($1) AND client_updated_at > now() - interval '90 days' ORDER BY user_id, d DESC`, [ids]),
  ]);
  const by = (rows, k) => new Map(rows.map((r) => [r[k], r]));
  const wm = by(w.rows, 'user_id'), om = by(o.rows, 'owner_id'), sm = by(s.rows, 'owner_id');
  const days = new Map();
  for (const r of d.rows) { if (!days.has(r.user_id)) days.set(r.user_id, []); days.get(r.user_id).push(r.d); }
  const today = new Date(); today.setUTCHours(0, 0, 0, 0);
  const { userJson } = require('../lib/auth');
  res.json({ success: true, data: users.map((u) => {
    let streak = 0, next = null;
    for (const x of days.get(u.id) || []) {
      const t = new Date(x); t.setUTCHours(0, 0, 0, 0);
      const gap = Math.round((today - t) / 864e5);
      if (next === null ? gap <= 1 : gap === next) { streak++; next = gap + 1; } else break;
    }
    const sub = sm.get(u.id);
    return { ...userJson(u), workoutsDone: wm.get(u.id)?.done || 0, orderCount: om.get(u.id)?.n || 0, spend: Number(om.get(u.id)?.spend || 0) + Number(sub?.data?.amount || 0), streak, subscription: sub ? sub.data : null };
  }) });
});

// Coaching subscriptions (the paid plans users buy), newest first.
// Marketplace vendors = product brands. Sales come from order items joined to their product;
// an optional doc in the "vendors" collection (same name) adds contact details and commission.
router.get('/vendors', requireAdmin, cached(['orders', 'products', 'vendors'], 120), async (_req, res) => {
  const BRAND = `COALESCE(NULLIF(p.data->>'brand', ''), NULLIF(it->>'brand', ''), 'NeuroFit')`;
  const [sales, catalog, top, extra] = await Promise.all([
    query(`SELECT ${BRAND} AS brand,
             COALESCE(sum(COALESCE((it->>'price')::numeric, 0) * COALESCE((it->>'quantity')::int, 1)) FILTER (WHERE COALESCE(o.data->>'orderStatus','') NOT IN ('Cancelled','Returned')), 0) AS gross,
             count(DISTINCT o.id)::int AS orders,
             count(DISTINCT o.id) FILTER (WHERE o.data->>'orderStatus' IN ('Cancelled','Returned'))::int AS refunded,
             count(DISTINCT o.id) FILTER (WHERE o.data->>'orderStatus' = 'Delivered')::int AS delivered,
             COALESCE(avg(EXTRACT(EPOCH FROM (o.updated_at - o.created_at)) / 86400) FILTER (WHERE o.data->>'orderStatus' = 'Delivered'), 0) AS fulfil_days
           FROM docs o
           CROSS JOIN LATERAL jsonb_array_elements(CASE WHEN jsonb_typeof(o.data->'items') = 'array' THEN o.data->'items' ELSE '[]'::jsonb END) it
           LEFT JOIN docs p ON p.collection = 'products' AND p.id = COALESCE(it->>'productId', it->>'id')
           WHERE o.collection = 'orders' AND COALESCE(it->>'price', '0') ~ '^[0-9.]+$' AND COALESCE(it->>'quantity', '1') ~ '^[0-9]+$'
           GROUP BY 1`),
    query(`SELECT COALESCE(NULLIF(data->>'brand', ''), 'NeuroFit') AS brand, count(*)::int AS skus,
             mode() WITHIN GROUP (ORDER BY COALESCE(data->>'categoryName', data->>'category', 'General')) AS category,
             max(COALESCE(data->>'mainImageUrl', data->>'imageUrl', data->>'image', '')) AS image,
             COALESCE(avg((data->>'rating')::numeric) FILTER (WHERE data->>'rating' ~ '^[0-9.]+$'), 0) AS rating,
             COALESCE(sum((data->>'reviewCount')::int) FILTER (WHERE data->>'reviewCount' ~ '^[0-9]+$'), 0)::int AS reviews,
             min(created_at) AS since
           FROM docs WHERE collection = 'products' GROUP BY 1`),
    query(`SELECT ${BRAND} AS brand, p.id, max(COALESCE(p.data->>'name', p.data->>'title', it->>'name', it->>'title')) AS name,
             max(COALESCE(p.data->>'mainImageUrl', p.data->>'imageUrl', it->>'image', '')) AS image,
             max(COALESCE(p.data->>'price', it->>'price', '0')) AS price, max(COALESCE(p.data->>'stock', '')) AS stock,
             sum(COALESCE((it->>'quantity')::int, 1))::int AS sold
           FROM docs o
           CROSS JOIN LATERAL jsonb_array_elements(CASE WHEN jsonb_typeof(o.data->'items') = 'array' THEN o.data->'items' ELSE '[]'::jsonb END) it
           LEFT JOIN docs p ON p.collection = 'products' AND p.id = COALESCE(it->>'productId', it->>'id')
           WHERE o.collection = 'orders' AND COALESCE(it->>'quantity', '1') ~ '^[0-9]+$'
           GROUP BY 1, 2 ORDER BY sold DESC LIMIT 300`),
    query(`SELECT id, data FROM docs WHERE collection = 'vendors'`),
  ]);
  const by = new Map();
  const get = (b) => by.get(b) || by.set(b, { name: b }).get(b);
  for (const r of catalog.rows) Object.assign(get(r.brand), { skus: r.skus, category: r.category, image: r.image, rating: Number(r.rating), reviews: r.reviews, since: r.since });
  for (const r of sales.rows) Object.assign(get(r.brand), { gross: Number(r.gross), orders: r.orders, refunded: r.refunded, delivered: r.delivered, fulfilDays: +Number(r.fulfil_days).toFixed(1) });
  for (const r of top.rows) {
    const v = get(r.brand);
    (v.topProducts = v.topProducts || []).length < 3 && v.topProducts.push({ id: r.id, name: r.name, image: r.image, price: Number(r.price) || 0, stock: r.stock === '' ? null : Number(r.stock), sold: r.sold });
  }
  for (const { id, data } of extra.rows) {
    const key = data.name || data.storeName || data.brand;
    if (key) Object.assign(get(key), { id, ...data, name: key });
  }
  const list = [...by.values()].map((v) => {
    const rate = Number(v.commissionRate ?? v.commission ?? 10);
    const gross = v.gross || 0;
    return { skus: 0, gross: 0, orders: 0, refunded: 0, delivered: 0, fulfilDays: 0, rating: 0, reviews: 0, topProducts: [], category: 'General', image: '',
      ...v, commissionRate: rate, commissionEarned: Math.round((gross * rate) / 100), refundRate: v.orders ? +((v.refunded / v.orders) * 100).toFixed(1) : 0,
      status: v.status || 'Verified' };
  }).sort((a, b) => b.gross - a.gross);
  res.json({ success: true, data: list });
});

// Customers who placed orders, ranked by spend, with their latest orders. One query, capped.
router.get('/customers', requireAdmin, cached(['orders', 'users'], 60), async (req, res) => {
  const { userJson } = require('../lib/auth');
  const docs = require('../lib/docs');
  const limit = Math.min(Number(req.query.limit) || 200, 1000);
  const agg = await query(`SELECT owner_id, count(*)::int AS n,
      COALESCE(sum((data->>'totalAmount')::numeric) FILTER (WHERE data->>'totalAmount' ~ '^[0-9.]+$'), 0) AS spend
    FROM docs WHERE collection = 'orders' AND owner_id IS NOT NULL GROUP BY 1 ORDER BY spend DESC LIMIT $1`, [limit]);
  const ids = agg.rows.map((r) => r.owner_id);
  if (!ids.length) return res.json({ success: true, data: [], orders: [] });
  const [users, orders] = await Promise.all([
    query('SELECT * FROM users WHERE id = ANY($1)', [ids]),
    query(`SELECT * FROM (SELECT *, row_number() OVER (PARTITION BY owner_id ORDER BY created_at DESC) AS rn FROM docs WHERE collection = 'orders' AND owner_id = ANY($1)) x WHERE rn <= 10`, [ids]),
  ]);
  res.json({
    success: true,
    data: users.rows.map((u) => ({ ...userJson(u), city: (u.addresses && u.addresses[0] && u.addresses[0].city) || (u.profile && u.profile.city) || '' })),
    orders: orders.rows.map((r) => ({ ...docs.toItem(r, 'orderId'), uid: r.owner_id })),
  });
});

// Admin inbox: things waiting on an admin, built live from real rows (no separate feed to keep in sync).
router.get('/inbox', requireAdmin, cached(['trainers', 'orders', 'users', 'reports', 'trainer_subscriptions'], 20), async (_req, res) => {
  const [trainers, orders, verifs, reports, subs] = await Promise.all([
    query(`SELECT id, data, created_at FROM docs WHERE collection = 'trainers' AND COALESCE(data->>'status', 'pending') IN ('pending', 'applied', 'review') ORDER BY created_at DESC LIMIT 20`),
    query(`SELECT id, data, created_at FROM docs WHERE collection = 'orders' AND COALESCE(data->>'orderStatus', 'Pending') IN ('Pending', 'Placed', 'Confirmed', 'Processing', 'Packed') ORDER BY created_at DESC LIMIT 20`),
    query(`SELECT id, name, photo_url, profile, updated_at FROM users WHERE NOT is_verified AND profile->>'verificationStatus' IN ('pending', 'submitted') ORDER BY updated_at DESC LIMIT 20`),
    query(`SELECT id, data, created_at FROM docs WHERE collection = 'reports' AND COALESCE(data->>'status', 'open') IN ('open', 'pending') ORDER BY created_at DESC LIMIT 20`),
    query(`SELECT id, data, created_at FROM docs WHERE collection = 'trainer_subscriptions' AND created_at > now() - interval '3 days' ORDER BY created_at DESC LIMIT 10`),
  ]);
  const items = [];
  for (const r of trainers.rows) {
    const d = r.data;
    items.push({ id: `tr_${r.id}`, refId: r.id, kind: 'trainer', at: r.created_at, status: 'Pending', avatar: d.photo || d.photoUrl || d.image || '',
      title: `New Trainer Application: ${d.name || 'Coach'}`, subtitle: [d.specialty || d.category, d.experience ? `${d.experience} yrs exp` : null].filter(Boolean).join(' • ') || 'Waiting for review',
      meta: `Applicant ID: #${r.id}` });
  }
  for (const r of orders.rows) {
    const d = r.data;
    const items0 = Array.isArray(d.items) ? d.items : [];
    items.push({ id: `or_${r.id}`, refId: r.id, kind: 'order', at: r.created_at, status: 'Pending', avatar: (items0[0] && (items0[0].image || items0[0].imageUrl)) || '',
      title: `New Order: ₹${Number(d.totalAmount || 0).toLocaleString('en-IN')} Placed`, subtitle: `Order #${r.id} by ${d.customerName || 'Customer'} • ${items0.map((i) => `${i.quantity || 1}x ${i.name || i.title || 'Item'}`).slice(0, 3).join(', ')}`,
      meta: `Payment: ${d.paymentMethod || 'Not set'} • ${d.orderStatus || 'Pending'}` });
  }
  for (const u of verifs.rows) {
    items.push({ id: `ve_${u.id}`, refId: u.id, kind: 'verification', at: u.updated_at, status: 'Pending', avatar: u.photo_url || '',
      title: `User Verification Request: ${u.name || 'User'}`, subtitle: 'Documents uploaded for verification', meta: `User ID: #${u.id}` });
  }
  for (const r of reports.rows) {
    const d = r.data;
    items.push({ id: `rp_${r.id}`, refId: r.id, kind: 'report', at: r.created_at, status: 'Pending', avatar: '',
      title: d.title || `Reported ${d.category || 'content'}`, subtitle: d.description || `Flagged by ${d.count || 1} user(s)`,
      meta: `Report: #${r.id}${d.autoHidden ? ' • Auto-Hidden' : ''}` });
  }
  for (const r of subs.rows) {
    const d = r.data;
    items.push({ id: `su_${r.id}`, refId: r.id, kind: 'subscription', at: r.created_at, status: 'Completed', avatar: d.userPhoto || '',
      title: `New Subscription: ${d.userName || 'Member'}`, subtitle: `${d.planName || 'Plan'} with ${d.trainerName || 'coach'} for ₹${Number(d.amount || 0).toLocaleString('en-IN')}`,
      meta: d.paymentId ? `Payment #${d.paymentId}` : (d.complimentary ? 'Complimentary' : '') });
  }
  items.sort((a, b) => new Date(b.at) - new Date(a.at));
  res.json({ success: true, data: items });
});

router.get('/subscriptions', requireAdmin, cached(['trainer_subscriptions', 'users'], 30), async (_req, res) => {
  const { rows } = await query(
    `SELECT s.id, s.owner_id, s.data, s.created_at, u.name, u.email, u.phone, u.photo_url
       FROM docs s LEFT JOIN users u ON u.id = s.owner_id
      WHERE s.collection = 'trainer_subscriptions' ORDER BY s.created_at DESC LIMIT 1000`);
  res.json({ success: true, data: rows.map((r) => ({
    ...r.data, id: r.id, userId: r.owner_id, createdAt: r.created_at,
    userName: r.name || r.data.userName || 'User', email: r.email || '', phone: r.phone || '', photo: r.photo_url || r.data.userPhoto || '',
    active: r.data.status === 'active' && Date.parse(r.data.until) > Date.now(),
  })) });
});

router.patch('/subscriptions/:id', requireAdmin, async (req, res) => {
  const docs = require('../lib/docs');
  const row = await docs.get('trainer_subscriptions', req.params.id);
  if (!row) return res.status(404).json({ success: false, message: 'Subscription not found' });
  const patch = {};
  if (req.body.status) patch.status = req.body.status === 'active' ? 'active' : 'cancelled';
  const extra = Number(req.body.extendDays || 0);
  if (extra > 0) {
    const base = Math.max(Date.parse(row.data.until) || Date.now(), Date.now());
    patch.until = new Date(base + extra * 864e5).toISOString();
    patch.status = 'active';
    patch.grants = [...(row.data.grants || []), { days: extra, at: new Date().toISOString() }];
  }
  const updated = await docs.upsert('trainer_subscriptions', row.id, patch);
  await require('../lib/cache').bump('trainer_subscriptions');
  res.json({ success: true, data: docs.toItem(updated) });
});

// Health of the moving parts, for the admin settings page.
router.get('/system', requireAdmin, async (_req, res) => {
  const t = Date.now();
  await one('SELECT 1 AS ok');
  const dbMs = Date.now() - t;
  const size = await one(`SELECT pg_database_size(current_database())::bigint AS bytes`);
  res.json({ success: true, data: {
    dbLatencyMs: dbMs, dbSizeMb: Math.round(Number(size.bytes) / 1048576), uptimeSec: Math.round(process.uptime()),
    memoryMb: Math.round(process.memoryUsage().rss / 1048576), r2: require('./media').configured(),
    livekit: !!(process.env.LIVEKIT_API_KEY && process.env.LIVEKIT_URL), google: !!(process.env.GOOGLE_WEB_CLIENT_ID || process.env.GOOGLE_CLIENT_IDS),
    cache: require('../lib/cache').redis() ? 'redis + memory' : 'memory',
  } });
});

module.exports = { router };
