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

  const [signups, active, revenue, orderCount, workoutsDone, statusRows, topProducts, topWorkouts, goals] = await Promise.all([
    series(`SELECT date_trunc('day', created_at) AS day, count(*) AS v FROM users WHERE created_at > ${days(30)} GROUP BY 1`),
    series(`SELECT date_trunc('day', last_active_at) AS day, count(*) AS v FROM users WHERE last_active_at > ${days(30)} GROUP BY 1`),
    series(`SELECT date_trunc('day', created_at) AS day, COALESCE(sum((data->>'totalAmount')::numeric), 0) AS v FROM docs WHERE collection = 'orders' AND created_at > ${days(30)} AND data->>'totalAmount' ~ '^[0-9.]+$' AND data->>'orderStatus' NOT IN ('Cancelled','Returned') GROUP BY 1`),
    series(`SELECT date_trunc('day', created_at) AS day, count(*) AS v FROM docs WHERE collection = 'orders' AND created_at > ${days(30)} GROUP BY 1`),
    series(`SELECT date_trunc('day', client_updated_at) AS day, count(*) AS v FROM user_records WHERE collection = 'workout_progress' AND data->>'dayCompleted' = 'true' AND client_updated_at > ${days(30)} GROUP BY 1`),
    query(`SELECT COALESCE(data->>'orderStatus','Pending') AS status, count(*)::int AS n FROM docs WHERE collection = 'orders' GROUP BY 1 ORDER BY 2 DESC`),
    query(`SELECT it->>'name' AS name, COALESCE(it->>'productId', it->>'id') AS id, sum(COALESCE((it->>'quantity')::int, 1))::int AS qty,
             sum(COALESCE((it->>'price')::numeric, 0) * COALESCE((it->>'quantity')::int, 1)) AS revenue
           FROM docs, jsonb_array_elements(CASE WHEN jsonb_typeof(data->'items') = 'array' THEN data->'items' ELSE '[]'::jsonb END) it
           WHERE collection = 'orders' GROUP BY 1, 2 ORDER BY qty DESC LIMIT 10`),
    query(`SELECT data->>'workoutId' AS id, max(data->>'workoutTitle') AS title, count(DISTINCT user_id)::int AS athletes,
             count(*) FILTER (WHERE data->>'dayCompleted' = 'true')::int AS completed
           FROM user_records WHERE collection = 'workout_progress' GROUP BY 1 ORDER BY athletes DESC LIMIT 10`),
    query(`SELECT COALESCE(questionnaire->>'goal', questionnaire->>'primaryGoal', questionnaire->>'fitnessGoal', 'Not set') AS goal, count(*)::int AS n
           FROM users WHERE role NOT IN ('admin','superadmin') GROUP BY 1 ORDER BY 2 DESC LIMIT 8`),
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
    },
  });
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
