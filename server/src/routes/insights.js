// Deeper admin analytics (users, revenue, orders, trainers, fitness, nutrition).
// One call, cached for two minutes. Everything is computed from real rows.
const express = require('express');
const { query, one } = require('../db');
const { requireAdmin } = require('../lib/auth');
const { cached } = require('../lib/cache');

const router = express.Router();
const NOT_ADMIN = `role NOT IN ('admin','superadmin')`;
const PAID = `data->>'totalAmount' ~ '^[0-9.]+$' AND COALESCE(data->>'orderStatus','') NOT IN ('Cancelled','Returned')`;
const AMT = `(data->>'totalAmount')::numeric`;
const rows = async (sql, p) => (await query(sql, p)).rows;
const num = (o) => Object.fromEntries(Object.entries(o || {}).map(([k, v]) => [k, v === null ? 0 : (typeof v === 'string' && /^-?[0-9.]+$/.test(v) ? Number(v) : v)]));
const fill = (list, n, key = 'day') => {
  const map = Object.fromEntries(list.map((r) => [new Date(r[key]).toISOString().slice(0, 10), Number(r.v)]));
  const out = [];
  for (let i = n - 1; i >= 0; i--) {
    const d = new Date(Date.now() - i * 864e5).toISOString().slice(0, 10);
    out.push({ date: d, value: map[d] || 0 });
  }
  return out;
};
const months12 = (list) => {
  const map = Object.fromEntries(list.map((r) => [new Date(r.m).toISOString().slice(0, 7), Number(r.v)]));
  const out = [];
  const now = new Date();
  for (let i = 11; i >= 0; i--) {
    const d = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth() - i, 1)).toISOString().slice(0, 7);
    out.push({ month: d, value: map[d] || 0 });
  }
  return out;
};

router.get('/', requireAdmin, cached(['users', 'orders', 'trainers', 'trainer_subscriptions', 'live_sessions', 'products', 'posts'], 120), async (_req, res) => {
  const [
    retention, platforms, heat, sessions, returning, goalsNew, signups90,
    rev, revDaily, revMonthly, payMethods, byUserType, plans, orderCats, cities, aov, refunds, orderDaily,
    trainerStatus, trainerCats, ratingBuckets, topTrainers, trainerGrowth, liveDaily, earnDaily, payout,
    fitnessUsers, workoutDaily, programs, nutrition, nutritionDaily, txns, ratingDaily, ratingAll, regs, tActs, wTypes, wMuscles, wDone, wDur, wCal, wRecent, wUsersDaily, mealSlots, topFoods, targets,
  ] = await Promise.all([
    // ---------- users ----------
    one(`SELECT
        round(100.0 * count(*) FILTER (WHERE last_active_at >= created_at + interval '1 day') / NULLIF(count(*) FILTER (WHERE created_at < now() - interval '1 day'), 0), 1) AS d1,
        round(100.0 * count(*) FILTER (WHERE last_active_at >= created_at + interval '7 days' AND created_at < now() - interval '7 days') / NULLIF(count(*) FILTER (WHERE created_at < now() - interval '7 days'), 0), 1) AS d7,
        round(100.0 * count(*) FILTER (WHERE last_active_at >= created_at + interval '14 days' AND created_at < now() - interval '14 days') / NULLIF(count(*) FILTER (WHERE created_at < now() - interval '14 days'), 0), 1) AS d14,
        round(100.0 * count(*) FILTER (WHERE last_active_at >= created_at + interval '30 days' AND created_at < now() - interval '30 days') / NULLIF(count(*) FILTER (WHERE created_at < now() - interval '30 days'), 0), 1) AS d30
      FROM users WHERE ${NOT_ADMIN}`),
    rows(`SELECT CASE WHEN lower(COALESCE(profile->>'platform','')) LIKE 'android%' THEN 'Android'
                      WHEN lower(COALESCE(profile->>'platform','')) IN ('ios','iphone','ipad') THEN 'iOS'
                      WHEN lower(COALESCE(profile->>'platform','')) = 'web' THEN 'Web' ELSE 'Unknown' END AS label, count(*)::int AS n
          FROM users WHERE ${NOT_ADMIN} GROUP BY 1 ORDER BY 2 DESC`),
    rows(`SELECT extract(isodow FROM client_updated_at)::int AS dow, (extract(hour FROM client_updated_at AT TIME ZONE 'Asia/Kolkata')::int * 7 / 24) AS slot, count(*)::int AS n
          FROM user_records WHERE client_updated_at > now() - interval '30 days' GROUP BY 1, 2`),
    one(`SELECT COALESCE(sum((data->>'count')::int), 0)::int AS sessions, COALESCE(sum((data->>'seconds')::bigint), 0)::bigint AS seconds,
           COALESCE(sum((data->>'screens')::int), 0)::int AS screens, COALESCE(sum((data->>'bounces')::int), 0)::int AS bounces,
           count(DISTINCT user_id)::int AS users
         FROM user_records WHERE collection = 'session_day' AND client_updated_at > now() - interval '30 days'`),
    one(`SELECT count(*) FILTER (WHERE last_active_at > now() - interval '7 days' AND created_at < now() - interval '7 days')::int AS returning,
           count(*) FILTER (WHERE last_active_at < now() - interval '30 days' OR last_active_at IS NULL)::int AS inactive
         FROM users WHERE ${NOT_ADMIN}`),
    rows(`SELECT COALESCE(questionnaire->>'goal', questionnaire->>'primaryGoal', questionnaire->>'fitnessGoal', 'Not set') AS goal,
           count(*)::int AS n, count(*) FILTER (WHERE created_at > now() - interval '7 days')::int AS new7, count(*) FILTER (WHERE created_at BETWEEN now() - interval '14 days' AND now() - interval '7 days')::int AS prev7
         FROM users WHERE ${NOT_ADMIN} GROUP BY 1 ORDER BY 2 DESC LIMIT 6`),
    rows(`SELECT date_trunc('day', created_at) AS day, count(*) AS v FROM users WHERE ${NOT_ADMIN} AND created_at > now() - interval '90 days' GROUP BY 1`),
    // ---------- revenue ----------
    one(`SELECT
        COALESCE((SELECT sum(${AMT}) FROM docs WHERE collection = 'orders' AND ${PAID}), 0) AS market,
        COALESCE((SELECT sum((data->>'amount')::numeric) FROM docs WHERE collection = 'trainer_subscriptions'), 0) AS subs,
        COALESCE((SELECT sum(${AMT}) FROM docs WHERE collection = 'orders' AND ${PAID} AND created_at > date_trunc('day', now())), 0)
          + COALESCE((SELECT sum((data->>'amount')::numeric) FROM docs WHERE collection = 'trainer_subscriptions' AND created_at > date_trunc('day', now())), 0) AS today,
        COALESCE((SELECT sum(${AMT}) FROM docs WHERE collection = 'orders' AND ${PAID} AND created_at > now() - interval '7 days'), 0)
          + COALESCE((SELECT sum((data->>'amount')::numeric) FROM docs WHERE collection = 'trainer_subscriptions' AND created_at > now() - interval '7 days'), 0) AS week,
        COALESCE((SELECT sum(${AMT}) FROM docs WHERE collection = 'orders' AND ${PAID} AND created_at BETWEEN now() - interval '14 days' AND now() - interval '7 days'), 0)
          + COALESCE((SELECT sum((data->>'amount')::numeric) FROM docs WHERE collection = 'trainer_subscriptions' AND created_at BETWEEN now() - interval '14 days' AND now() - interval '7 days'), 0) AS prev_week,
        COALESCE((SELECT sum(${AMT}) FROM docs WHERE collection = 'orders' AND ${PAID} AND created_at > date_trunc('month', now())), 0)
          + COALESCE((SELECT sum((data->>'amount')::numeric) FROM docs WHERE collection = 'trainer_subscriptions' AND created_at > date_trunc('month', now())), 0) AS month,
        COALESCE((SELECT sum(${AMT}) FROM docs WHERE collection = 'orders' AND ${PAID} AND created_at > date_trunc('year', now())), 0)
          + COALESCE((SELECT sum((data->>'amount')::numeric) FROM docs WHERE collection = 'trainer_subscriptions' AND created_at > date_trunc('year', now())), 0) AS year`),
    rows(`SELECT day, sum(v) AS v FROM (
            SELECT date_trunc('day', created_at) AS day, ${AMT} AS v FROM docs WHERE collection = 'orders' AND ${PAID} AND created_at > now() - interval '30 days'
            UNION ALL SELECT date_trunc('day', created_at), (data->>'amount')::numeric FROM docs WHERE collection = 'trainer_subscriptions' AND created_at > now() - interval '30 days') x GROUP BY 1`),
    rows(`SELECT m, sum(market) AS market, sum(subs) AS subs, sum(market + subs) AS v FROM (
            SELECT date_trunc('month', created_at) AS m, ${AMT} AS market, 0 AS subs FROM docs WHERE collection = 'orders' AND ${PAID} AND created_at > now() - interval '12 months'
            UNION ALL SELECT date_trunc('month', created_at), 0, (data->>'amount')::numeric FROM docs WHERE collection = 'trainer_subscriptions' AND created_at > now() - interval '12 months') x GROUP BY 1`),
    rows(`SELECT CASE WHEN lower(COALESCE(data->>'paymentMethod','')) IN ('cod','cash','cash on delivery') THEN 'Cash on Delivery'
                      WHEN lower(COALESCE(data->>'paymentMethod','')) LIKE '%upi%' THEN 'UPI'
                      WHEN lower(COALESCE(data->>'paymentMethod','')) LIKE '%card%' THEN 'Card'
                      WHEN lower(COALESCE(data->>'paymentMethod','')) LIKE '%wallet%' THEN 'Wallet'
                      WHEN COALESCE(data->>'paymentMethod','') = '' THEN 'Not set' ELSE initcap(data->>'paymentMethod') END AS label,
                 count(*)::int AS n, COALESCE(sum(${AMT}) FILTER (WHERE ${PAID}), 0) AS amount
          FROM docs WHERE collection = 'orders' GROUP BY 1 ORDER BY 3 DESC`),
    rows(`SELECT CASE WHEN u.is_premium THEN 'Premium' WHEN u.role = 'trainer' THEN 'Coaches' ELSE 'Free users' END AS label, COALESCE(sum((d.data->>'totalAmount')::numeric), 0) AS amount, count(*)::int AS n
          FROM docs d JOIN users u ON u.id = d.owner_id WHERE d.collection = 'orders' AND d.data->>'totalAmount' ~ '^[0-9.]+$' AND COALESCE(d.data->>'orderStatus','') NOT IN ('Cancelled','Returned') GROUP BY 1 ORDER BY 2 DESC`),
    rows(`SELECT COALESCE(data->>'planName', 'Coaching') AS label, count(*)::int AS n, COALESCE(sum((data->>'amount')::numeric), 0) AS amount
          FROM docs WHERE collection = 'trainer_subscriptions' GROUP BY 1 ORDER BY 3 DESC LIMIT 6`),
    // ---------- orders ----------
    rows(`SELECT COALESCE(NULLIF(it->>'category',''), NULLIF(it->>'categoryName',''), p.data->>'categoryName', p.data->>'category', 'Other') AS label,
                 sum(COALESCE((it->>'quantity')::int, 1))::int AS qty, sum(COALESCE((it->>'price')::numeric, 0) * COALESCE((it->>'quantity')::int, 1)) AS amount, count(DISTINCT o.id)::int AS orders
          FROM docs o CROSS JOIN LATERAL jsonb_array_elements(CASE WHEN jsonb_typeof(o.data->'items') = 'array' THEN o.data->'items' ELSE '[]'::jsonb END) it
          LEFT JOIN docs p ON p.collection = 'products' AND p.id = COALESCE(it->>'productId', it->>'id')
          WHERE o.collection = 'orders' GROUP BY 1 ORDER BY 3 DESC LIMIT 8`),
    rows(`SELECT initcap(COALESCE(NULLIF(data->'shippingAddress'->>'city',''), NULLIF(data->>'city',''), 'Unknown')) AS label, count(*)::int AS n, COALESCE(sum(${AMT}) FILTER (WHERE ${PAID}), 0) AS amount
          FROM docs WHERE collection = 'orders' GROUP BY 1 ORDER BY 2 DESC LIMIT 6`),
    rows(`SELECT date_trunc('day', created_at) AS day, avg(${AMT}) AS v FROM docs WHERE collection = 'orders' AND ${PAID} AND created_at > now() - interval '30 days' GROUP BY 1`),
    one(`SELECT COALESCE(sum(${AMT}) FILTER (WHERE data->>'orderStatus' IN ('Cancelled','Returned') AND COALESCE(data->>'paymentStatus','') ILIKE 'paid' AND data->>'totalAmount' ~ '^[0-9.]+$'), 0) AS refunded,
           count(*) FILTER (WHERE data->>'orderStatus' = 'Returned' OR data ? 'returnRequest')::int AS returns,
           COALESCE(sum(${AMT}) FILTER (WHERE data->>'totalAmount' ~ '^[0-9.]+$'), 0) AS gross
         FROM docs WHERE collection = 'orders'`),
    rows(`SELECT date_trunc('day', created_at) AS day, count(*) AS v FROM docs WHERE collection = 'orders' AND created_at > now() - interval '30 days' GROUP BY 1`),
    // ---------- trainers ----------
    rows(`SELECT COALESCE(data->>'status','pending') AS label, count(*)::int AS n FROM docs WHERE collection = 'trainers' GROUP BY 1`),
    rows(`SELECT initcap(COALESCE(NULLIF(data->>'cat',''), 'Other')) AS label, count(*)::int AS n FROM docs WHERE collection = 'trainers' AND data->>'status' = 'approved' GROUP BY 1 ORDER BY 2 DESC LIMIT 6`),
    rows(`SELECT CASE WHEN r IS NULL THEN 'No reviews' WHEN r >= 4.5 THEN '4.5 - 5.0' WHEN r >= 4 THEN '4.0 - 4.5' WHEN r >= 3 THEN '3.0 - 4.0' ELSE 'Below 3.0' END AS label, count(*)::int AS n
          FROM (SELECT t.id, (SELECT avg((r.data->>'stars')::float) FROM docs r WHERE r.collection = 'reviews' AND r.data->>'trainerId' = t.id) AS r
                FROM docs t WHERE t.collection = 'trainers' AND t.data->>'status' = 'approved') x GROUP BY 1 ORDER BY 1`),
    rows(`SELECT t.id, t.data->>'name' AS name, t.data->>'photo' AS photo, initcap(COALESCE(t.data->>'cat','')) AS cat,
                 count(s.id)::int AS clients, COALESCE(sum((s.data->>'amount')::numeric), 0) AS earnings,
                 (SELECT round(avg((r.data->>'stars')::numeric), 1) FROM docs r WHERE r.collection = 'reviews' AND r.data->>'trainerId' = t.id) AS rating
          FROM docs t LEFT JOIN docs s ON s.collection = 'trainer_subscriptions' AND s.data->>'trainerId' = t.id
          WHERE t.collection = 'trainers' AND t.data->>'status' = 'approved' GROUP BY t.id, t.data ORDER BY earnings DESC, clients DESC LIMIT 5`),
    rows(`SELECT date_trunc('day', created_at) AS day, count(*) AS v FROM docs WHERE collection = 'trainers' AND created_at > now() - interval '30 days' GROUP BY 1`),
    rows(`SELECT date_trunc('day', created_at) AS day, count(*) AS v FROM docs WHERE collection = 'live_sessions' AND created_at > now() - interval '30 days' GROUP BY 1`),
    rows(`SELECT date_trunc('day', created_at) AS day, sum((data->>'amount')::numeric) AS v FROM docs WHERE collection = 'trainer_subscriptions' AND created_at > now() - interval '30 days' GROUP BY 1`),
    rows(`SELECT initcap(COALESCE(data->>'paymentStatus', 'pending')) AS label, count(*)::int AS n, COALESCE(sum((data->>'amount')::numeric), 0) AS amount
          FROM docs WHERE collection = 'trainer_subscriptions' GROUP BY 1 ORDER BY 3 DESC`),
    // ---------- fitness ----------
    one(`SELECT count(DISTINCT user_id) FILTER (WHERE client_updated_at > now() - interval '7 days')::int AS active,
           count(DISTINCT user_id) FILTER (WHERE first_at > now() - interval '7 days')::int AS new,
           count(DISTINCT user_id) FILTER (WHERE n > 1)::int AS repeating,
           count(DISTINCT user_id) FILTER (WHERE client_updated_at < now() - interval '14 days')::int AS inactive,
           COALESCE(avg(secs) FILTER (WHERE secs > 0), 0) AS avg_seconds
         FROM (SELECT user_id, max(client_updated_at) AS client_updated_at, min(client_updated_at) AS first_at, count(*) AS n, avg((data->>'totalDurationSeconds')::numeric) AS secs
               FROM user_records WHERE collection = 'workout_progress' GROUP BY user_id) x`),
    rows(`SELECT date_trunc('day', client_updated_at) AS day, count(*) AS v FROM user_records WHERE collection = 'workout_progress' AND client_updated_at > now() - interval '30 days' GROUP BY 1`),
    rows(`SELECT COALESCE(data->>'programTitle', data->>'workoutTitle', 'Workout') AS title, count(DISTINCT user_id)::int AS athletes,
                 count(*) FILTER (WHERE data->>'dayCompleted' = 'true')::int AS completed, count(*)::int AS sessions
          FROM user_records WHERE collection = 'workout_progress' GROUP BY 1 ORDER BY 2 DESC LIMIT 5`),
    // ---------- nutrition ----------
    one(`SELECT COALESCE(sum(jsonb_array_length(CASE WHEN jsonb_typeof(data->'meals') = 'array' THEN data->'meals' ELSE '[]'::jsonb END)), 0)::int AS meals,
           COALESCE(avg(NULLIF(data->>'consumedCalories','')::numeric) FILTER (WHERE NULLIF(data->>'consumedCalories','')::numeric > 0), 0) AS avg_kcal,
           COALESCE(sum(NULLIF(data->>'consumedProtein','')::numeric), 0) AS protein, COALESCE(sum(NULLIF(data->>'consumedCarbs','')::numeric), 0) AS carbs,
           COALESCE(sum(NULLIF(data->>'consumedFat','')::numeric), 0) AS fat,
           round(100.0 * count(*) FILTER (WHERE NULLIF(data->>'targetProtein','')::numeric > 0 AND NULLIF(data->>'consumedProtein','')::numeric >= 0.9 * NULLIF(data->>'targetProtein','')::numeric)
                 / NULLIF(count(*) FILTER (WHERE NULLIF(data->>'targetProtein','')::numeric > 0), 0), 1) AS protein_adherence,
           count(*) FILTER (WHERE NULLIF(data->>'waterGlasses','')::numeric > 0)::int AS water_logs,
           COALESCE(sum(NULLIF(data->>'waterGlasses','')::numeric), 0) AS water_glasses
         FROM user_records WHERE collection = 'nutrition_day'`),
    rows(`SELECT date_trunc('day', client_updated_at) AS day, count(*) AS v FROM user_records WHERE collection = 'nutrition_day' AND client_updated_at > now() - interval '30 days' GROUP BY 1`),
    rows(`(SELECT id, 'order' AS kind, COALESCE(data->'items'->0->>'name', 'Store order') AS title, COALESCE(NULLIF(data->>'totalAmount','')::numeric, 0) AS amount,
              COALESCE(data->>'orderStatus', 'Pending') AS status, COALESCE(data->>'paymentStatus', '') AS payment, created_at AS at
            FROM docs WHERE collection = 'orders' AND (NOT (data ? 'totalAmount') OR data->>'totalAmount' ~ '^[0-9.]+$') ORDER BY created_at DESC LIMIT 8)
          UNION ALL
          (SELECT id, 'subscription', COALESCE(data->>'planName', 'Coaching') || ' · ' || COALESCE(data->>'trainerName', ''), COALESCE((data->>'amount')::numeric, 0),
              COALESCE(data->>'status', 'active'), COALESCE(data->>'paymentStatus', ''), created_at
            FROM docs WHERE collection = 'trainer_subscriptions' ORDER BY created_at DESC LIMIT 8)
          ORDER BY at DESC LIMIT 8`),
    rows(`SELECT date_trunc('day', created_at) AS day, avg((data->>'stars')::numeric) AS v FROM docs WHERE collection = 'reviews' AND created_at > now() - interval '30 days' GROUP BY 1`),
    one(`SELECT COALESCE(round(avg((data->>'stars')::numeric), 2), 0) AS avg, count(*)::int AS n FROM docs WHERE collection = 'reviews'`),
    rows(`SELECT id, data->>'name' AS name, initcap(COALESCE(data->>'cat','')) AS cat, COALESCE(data->>'status','pending') AS status, COALESCE(data->>'photo','') AS photo, created_at AS at
          FROM docs WHERE collection = 'trainers' ORDER BY created_at DESC LIMIT 5`),
    rows(`(SELECT 'live' AS kind, COALESCE(t.data->>'name', 'Coach') AS who, COALESCE(t.data->>'photo','') AS photo, 'went live: ' || COALESCE(l.data->>'title', 'Live class') AS what, l.created_at AS at
             FROM docs l LEFT JOIN docs t ON t.collection = 'trainers' AND t.id = l.owner_id WHERE l.collection = 'live_sessions' ORDER BY l.created_at DESC LIMIT 5)
          UNION ALL
          (SELECT 'payment', COALESCE(data->>'trainerName', 'Coach'), '', 'new client ' || COALESCE(data->>'userName', '') || ' · ₹' || COALESCE(data->>'amount', '0'), created_at
             FROM docs WHERE collection = 'trainer_subscriptions' ORDER BY created_at DESC LIMIT 5)
          UNION ALL
          (SELECT 'review', COALESCE(t.data->>'name', 'Coach'), COALESCE(t.data->>'photo',''), 'got a ' || COALESCE(r.data->>'stars', '?') || '★ review', r.created_at
             FROM docs r LEFT JOIN docs t ON t.collection = 'trainers' AND t.id = r.data->>'trainerId' WHERE r.collection = 'reviews' ORDER BY r.created_at DESC LIMIT 5)
          UNION ALL
          (SELECT 'update', COALESCE(data->>'name', 'Coach'), COALESCE(data->>'photo',''), 'updated their coach profile', updated_at
             FROM docs WHERE collection = 'trainers' AND updated_at > created_at + interval '1 minute' ORDER BY updated_at DESC LIMIT 5)
          ORDER BY at DESC LIMIT 6`),
    rows(`SELECT initcap(COALESCE(NULLIF(w.data->>'categoryName',''), NULLIF(w.data->>'category',''), NULLIF(w.data->>'type',''), 'Other')) AS label, count(*)::int AS n
          FROM user_records p LEFT JOIN docs w ON w.collection = 'workouts' AND w.id = p.data->>'workoutId'
          WHERE p.collection = 'workout_progress' GROUP BY 1 ORDER BY 2 DESC LIMIT 5`),
    rows(`SELECT initcap(COALESCE(NULLIF(e->>'muscleGroup',''), NULLIF(e->>'bodyPart',''), NULLIF(e->>'targetMuscle',''), 'Full body')) AS label, count(*)::int AS n
          FROM user_records p JOIN docs w ON w.collection = 'workouts' AND w.id = p.data->>'workoutId'
          CROSS JOIN LATERAL jsonb_array_elements(CASE WHEN jsonb_typeof(w.data->'exercises') = 'array' THEN w.data->'exercises' ELSE '[]'::jsonb END) e
          WHERE p.collection = 'workout_progress' AND p.client_updated_at > now() - interval '30 days' GROUP BY 1 ORDER BY 2 DESC LIMIT 5`),
    one(`SELECT count(*) FILTER (WHERE data->>'dayCompleted' = 'true')::int AS completed,
           count(*) FILTER (WHERE COALESCE(data->>'dayCompleted','false') <> 'true' AND client_updated_at > now() - interval '7 days')::int AS incomplete,
           count(*) FILTER (WHERE COALESCE(data->>'dayCompleted','false') <> 'true' AND client_updated_at <= now() - interval '7 days')::int AS abandoned
         FROM user_records WHERE collection = 'workout_progress'`),
    rows(`SELECT date_trunc('day', client_updated_at) AS day, avg(NULLIF(data->>'totalDurationSeconds','')::numeric) / 60 AS v
          FROM user_records WHERE collection = 'workout_progress' AND client_updated_at > now() - interval '30 days' GROUP BY 1`),
    rows(`SELECT date_trunc('day', client_updated_at) AS day, sum((data->>'caloriesBurned')::numeric) AS v
          FROM user_records WHERE collection = 'workout_progress' AND data->>'caloriesBurned' ~ '^[0-9.]+$' AND client_updated_at > now() - interval '30 days' GROUP BY 1`),
    rows(`SELECT u.name, u.photo_url AS photo, COALESCE(p.data->>'workoutTitle', 'a workout') AS title, (p.data->>'dayCompleted' = 'true') AS done, p.client_updated_at AS at
          FROM user_records p JOIN users u ON u.id = p.user_id WHERE p.collection = 'workout_progress' ORDER BY p.client_updated_at DESC LIMIT 5`),
    rows(`SELECT date_trunc('day', client_updated_at) AS day, count(DISTINCT user_id) AS v FROM user_records WHERE collection = 'workout_progress' AND client_updated_at > now() - interval '30 days' GROUP BY 1`),
    rows(`SELECT lower(COALESCE(m->>'mealType', 'snack')) AS slot, count(*)::int AS n, COALESCE(avg(NULLIF(m->>'calories','')::numeric), 0) AS avg_kcal, COALESCE(sum(NULLIF(m->>'calories','')::numeric), 0) AS kcal
          FROM user_records r CROSS JOIN LATERAL jsonb_array_elements(CASE WHEN jsonb_typeof(r.data->'meals') = 'array' THEN r.data->'meals' ELSE '[]'::jsonb END) m
          WHERE r.collection = 'nutrition_day' GROUP BY 1 ORDER BY 2 DESC`),
    rows(`SELECT COALESCE(m->>'foodName', m->>'name', 'Meal') AS name, max(COALESCE(m->>'category', m->>'source', '')) AS cat, count(*)::int AS n,
                 round(avg(NULLIF(m->>'calories','')::numeric)) AS kcal, round(avg(NULLIF(m->>'protein','')::numeric), 1) AS protein
          FROM user_records r CROSS JOIN LATERAL jsonb_array_elements(CASE WHEN jsonb_typeof(r.data->'meals') = 'array' THEN r.data->'meals' ELSE '[]'::jsonb END) m
          WHERE r.collection = 'nutrition_day' GROUP BY 1 ORDER BY 3 DESC LIMIT 5`),
    one(`SELECT COALESCE(round(avg(NULLIF(data->>'targetCalories','')::numeric)), 0) AS target_kcal FROM user_records WHERE collection = 'nutrition_day'`),
  ]);

  const heatmap = Array.from({ length: 7 }, () => Array(7).fill(0));
  for (const h of heat) heatmap[(h.dow - 1) % 7][Math.min(6, h.slot)] = h.n;
  const s = num(sessions);
  res.json({ success: true, generatedAt: new Date().toISOString(), data: {
    users: {
      retention: num(retention), platforms: platforms, heatmap, returning: returning.returning, inactive: returning.inactive,
      sessions: { total: s.sessions, users: s.users, avgSeconds: s.sessions ? Math.round(s.seconds / s.sessions) : 0, perUser: s.users ? +(s.sessions / s.users).toFixed(1) : 0,
        screensPerSession: s.sessions ? +(s.screens / s.sessions).toFixed(1) : 0, bounceRate: s.sessions ? +((s.bounces / s.sessions) * 100).toFixed(1) : 0 },
      goals: goalsNew, signups90: fill(signups90, 90),
    },
    revenue: { ...num(rev), total: Number(rev.market) + Number(rev.subs), daily: fill(revDaily, 30), monthly: months12(revMonthly).map((m) => { const r = revMonthly.find((x) => new Date(x.m).toISOString().slice(0, 7) === m.month) || {}; return { ...m, market: Number(r.market || 0), subs: Number(r.subs || 0) }; }),
      paymentMethods: payMethods.map(num), byUserType: byUserType.map(num), plans: plans.map(num), transactions: txns.map(num) },
    orders: { categories: orderCats.map(num), cities: cities.map(num), aovDaily: fill(aov, 30), daily: fill(orderDaily, 30), ...num(refunds) },
    trainers: { status: trainerStatus, categories: trainerCats, ratings: ratingBuckets, top: topTrainers.map(num), growth: fill(trainerGrowth, 30), liveDaily: fill(liveDaily, 30), earningsDaily: fill(earnDaily, 30), payout: payout.map(num), ratingDaily: fill(ratingDaily, 30), rating: num(ratingAll), recent: regs, activity: tActs },
    fitness: { ...num(fitnessUsers), daily: fill(workoutDaily, 30), programs, types: wTypes, muscles: wMuscles, completion: num(wDone),
      durationDaily: fill(wDur, 30), caloriesDaily: fill(wCal, 30), recent: wRecent, usersDaily: fill(wUsersDaily, 30) },
    nutrition: { ...num(nutrition), daily: fill(nutritionDaily, 30), slots: mealSlots.map(num), topFoods: topFoods.map(num), ...num(targets) },
  } });
});

module.exports = { router };
