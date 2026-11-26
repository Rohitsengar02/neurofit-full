// End-to-end API test against a real Postgres (DATABASE_URL).
// Run: DATABASE_URL=postgres://... npm test
process.env.ADMIN_EMAIL = process.env.ADMIN_EMAIL || 'admin@test.local';
process.env.ADMIN_PASSWORD = process.env.ADMIN_PASSWORD || 'Secret123';
process.env.PORT = process.env.PORT || '5077';
const test = require('node:test');
const assert = require('node:assert');
const { app } = require('../src/index');
const migrate = require('../src/migrate');
const { ensureAdmin } = require('../src/routes/auth');
const { pool } = require('../src/db');

let server; let base;
const call = async (method, path, body, token) => {
  const r = await fetch(base + path, { method, headers: { 'content-type': 'application/json', ...(token ? { authorization: `Bearer ${token}` } : {}) }, body: body ? JSON.stringify(body) : undefined });
  const text = await r.text();
  let json; try { json = JSON.parse(text); } catch (_) { json = text; }
  return { status: r.status, body: json };
};

test.before(async () => {
  await migrate();
  await ensureAdmin();
  await new Promise((ok) => { server = app.listen(0, ok); });
  base = `http://127.0.0.1:${server.address().port}`;
});
test.after(async () => { server.close(); await pool.end(); });

const uniq = Date.now().toString(36);
let user, user2, admin, coach, productId;

test('register, login, refresh, me', async () => {
  let r = await call('POST', '/api/auth/register', { name: 'Test User', email: `u${uniq}@t.local`, password: 'secret1' });
  assert.equal(r.status, 201); user = r.body;
  assert.ok(user.accessToken && user.refreshToken && user.data.uid);
  r = await call('POST', '/api/auth/register', { name: 'Dup', email: `u${uniq}@t.local`, password: 'secret1' });
  assert.equal(r.status, 409);
  r = await call('POST', '/api/auth/login', { email: `u${uniq}@t.local`, password: 'wrong' });
  assert.equal(r.status, 401);
  r = await call('POST', '/api/auth/login', { email: `U${uniq}@t.local`, password: 'secret1' });
  assert.equal(r.status, 200);
  r = await call('POST', '/api/auth/refresh', { refreshToken: user.refreshToken });
  assert.equal(r.status, 200); user.accessToken = r.body.accessToken; user.refreshToken = r.body.refreshToken;
  r = await call('GET', '/api/auth/me', null, user.accessToken);
  assert.equal(r.body.data.email, `u${uniq}@t.local`);
  r = await call('POST', '/api/auth/register', { name: 'Second', email: `v${uniq}@t.local`, password: 'secret1' });
  user2 = r.body;
});

test('admin login and protected writes', async () => {
  let r = await call('POST', '/api/admin/login', { email: 'admin@test.local', password: 'Secret123' });
  assert.equal(r.status, 200); admin = r.body;
  r = await call('POST', '/api/products', { name: 'Whey' }, user.accessToken);
  assert.equal(r.status, 403);
  r = await call('POST', '/api/products', { name: `Whey ${uniq}`, price: 1999, stock: 10, isActive: true }, admin.accessToken);
  assert.equal(r.status, 201); productId = r.body.data.id;
  r = await call('GET', `/api/products?q=${uniq}`);
  assert.equal(r.body.data.length, 1);
  r = await call('PATCH', `/api/products/${productId}/status`, {}, admin.accessToken);
  assert.equal(r.body.data.isActive, false);
  r = await call('GET', `/api/products?q=${uniq}&activeOnly=true`);
  assert.equal(r.body.data.length, 0);
  r = await call('PUT', `/api/products/${productId}`, { isActive: true, status: 'Active' }, admin.accessToken);
  assert.equal(r.body.data.name, `Whey ${uniq}`);
});

test('coupon, order, status, notifications', async () => {
  await call('POST', '/api/discounts', { code: `SAVE${uniq}`.toUpperCase(), type: 'percentage', value: 10, minOrderValue: 500 }, admin.accessToken);
  let r = await call('POST', '/api/discounts/validate', { code: `save${uniq}`, orderValue: 2000 });
  assert.equal(r.body.data.discountAmount, 200);
  r = await call('POST', '/api/orders', { orderId: `ord_${uniq}`, totalAmount: 1800, items: [{ productId, name: 'Whey', price: 1999, quantity: 1 }], couponCode: `SAVE${uniq}` }, user.accessToken);
  assert.equal(r.status, 201);
  r = await call('POST', '/api/orders', { orderId: `ord_${uniq}`, totalAmount: 1800 }, user.accessToken); // offline replay
  assert.equal(r.status, 200);
  r = await call('GET', `/api/orders/user/anything`, null, user.accessToken);
  assert.equal(r.body.data.length, 1);
  r = await call('GET', `/api/orders/user/${user.data.uid}`, null, user2.accessToken);
  assert.equal(r.body.data.length, 0, 'users only see their own orders');
  r = await call('PUT', `/api/orders/ord_${uniq}/status`, { orderStatus: 'Shipped' }, admin.accessToken);
  assert.equal(r.body.data.orderStatus, 'Shipped');
  r = await call('GET', `/api/products/${productId}`);
  assert.equal(r.body.data.stock, 9);
  r = await call('GET', '/api/notifications', null, user.accessToken);
  assert.ok(r.body.data.some((n) => n.title === 'Order update'));
});

test('profile, questionnaire, addresses', async () => {
  const uid = user.data.uid;
  let r = await call('PUT', `/api/users/${uid}`, { name: 'Renamed', heightCm: 180, role: 'admin' }, user.accessToken);
  assert.equal(r.body.data.name, 'Renamed'); assert.equal(r.body.data.role, 'user'); assert.equal(r.body.data.heightCm, 180);
  r = await call('POST', `/api/users/${uid}/questionnaire`, { goal: 'Lose weight', weight: 80, height: 175, age: 30, gender: 'male' }, user.accessToken);
  assert.equal(r.body.data.hasCompletedOnboarding, true);
  r = await call('POST', `/api/users/${uid}/addresses`, { fullName: 'A', city: 'Delhi' }, user.accessToken);
  const a1 = r.body.data[0].id; assert.equal(r.body.data[0].isDefault, true);
  r = await call('POST', `/api/users/${uid}/addresses`, { fullName: 'B', city: 'Pune' }, user.accessToken);
  const a2 = r.body.data[0].id;
  r = await call('PUT', `/api/users/${uid}/addresses/${a2}/default`, {}, user.accessToken);
  assert.equal(r.body.data.find((x) => x.id === a2).isDefault, true);
  r = await call('DELETE', `/api/users/${uid}/addresses/${a1}`, null, user.accessToken);
  assert.equal(r.body.data.length, 1);
  r = await call('GET', `/api/users/${uid}`, null, user2.accessToken);
  assert.equal(r.status, 403);
});

test('nutrition and workout progress', async () => {
  let r = await call('POST', '/api/user-nutrition/log-meal', { date: '2026-11-20', mealId: 'm1', foodName: 'Oats', calories: 300, protein: 10, quantity: 2 }, user.accessToken);
  assert.equal(r.body.nutrition.consumedCalories, 600);
  r = await call('POST', '/api/user-nutrition/log-meal', { date: '2026-11-20', mealId: 'm1', foodName: 'Oats', calories: 300, quantity: 2 }, user.accessToken);
  assert.equal(r.body.nutrition.meals.length, 1, 'replay does not duplicate');
  assert.ok(r.body.nutrition.targetCalories < 2400, 'weight loss target from questionnaire');
  r = await call('POST', '/api/user-nutrition/water', { date: '2026-11-20', glasses: 6 }, user.accessToken);
  assert.equal(r.body.nutrition.waterMilliliters, 1500);
  r = await call('GET', '/api/user-nutrition/history?startDate=2026-11-01&endDate=2026-11-30', null, user.accessToken);
  assert.equal(r.body.history['2026-11-20'].consumedCalories, 600);
  r = await call('DELETE', '/api/user-nutrition/meal/x/m1', null, user.accessToken);
  assert.equal(r.body.nutrition.consumedCalories, 0);
  r = await call('POST', '/api/user-workouts/start', { workoutId: 'wk1', dayNumber: 1, workoutTitle: 'Push' }, user.accessToken);
  assert.equal(r.body.userWorkout.status, 'in_progress');
  r = await call('POST', '/api/user-workouts/progress', { workoutId: 'wk1', dayNumber: 1, completedExerciseId: 'e1', dayCompleted: true }, user.accessToken);
  assert.deepEqual(r.body.userWorkout.completedExercises, ['e1']);
  r = await call('GET', '/api/user-workouts/progress/x/wk1/1', null, user.accessToken);
  assert.equal(r.body.userWorkout.dayCompleted, true);
});

test('offline sync push/pull with last-write-wins', async () => {
  let r = await call('POST', '/api/sync/push', { changes: [
    { collection: 'steps_day', id: '2026-11-20', data: { steps: 5000 }, updatedAt: '2026-11-20T10:00:00Z' },
    { collection: 'steps_day', id: '2026-11-21', data: { steps: 7000 }, updatedAt: '2026-11-21T10:00:00Z' },
  ] }, user.accessToken);
  assert.equal(r.body.accepted, 2);
  // older change must not overwrite
  await call('POST', '/api/sync/push', { changes: [{ collection: 'steps_day', id: '2026-11-20', data: { steps: 1 }, updatedAt: '2026-11-19T10:00:00Z' }] }, user.accessToken);
  r = await call('GET', '/api/sync/pull?since=0&collections=steps_day', null, user.accessToken);
  const d20 = r.body.changes.find((c) => c.id === '2026-11-20');
  assert.equal(d20.data.steps, 5000);
  const cursor = r.body.cursor;
  r = await call('GET', `/api/sync/pull?since=${cursor}`, null, user.accessToken);
  assert.equal(r.body.changes.length, 0);
  r = await call('GET', '/api/sync/pull?since=0', null, user2.accessToken);
  assert.ok(!r.body.changes.some((c) => c.collection === 'steps_day'), 'no data leaks between users');
});

test('trainer apply → approve → subscribe → chat → panel', async () => {
  let r = await call('POST', '/api/auth/register', { name: 'Coach Kay', email: `c${uniq}@t.local`, password: 'secret1' });
  coach = r.body;
  r = await call('POST', '/api/panel/apply', { headline: 'Strength coach', cat: 'Strength', city: 'Delhi', price: 999 }, coach.accessToken);
  assert.equal(r.body.data.status, 'pending');
  r = await call('GET', '/api/trainers');
  assert.ok(!r.body.data.some((t) => t.id === coach.data.uid));
  r = await call('POST', `/api/admin/trainers/${coach.data.uid}/approve`, {}, admin.accessToken);
  assert.equal(r.body.data.status, 'approved');
  r = await call('GET', '/api/trainers');
  assert.ok(r.body.data.some((t) => t.id === coach.data.uid));
  r = await call('POST', `/api/trainers/${coach.data.uid}/subscribe`, { planName: 'Quarterly' }, user.accessToken);
  assert.equal(r.status, 201);
  r = await call('GET', '/api/trainers/me/subscription', null, user.accessToken);
  assert.equal(r.body.data.trainerId, coach.data.uid);
  r = await call('POST', `/api/trainers/${coach.data.uid}/chat`, { text: 'Hi coach' }, user.accessToken);
  r = await call('GET', '/api/panel/clients', null, coach.accessToken);
  assert.equal(r.body.data.length, 1); assert.equal(r.body.data[0].unread, 1);
  r = await call('POST', `/api/panel/clients/${user.data.uid}/chat`, { text: 'Welcome!' }, coach.accessToken);
  r = await call('GET', `/api/trainers/${coach.data.uid}/chat`, null, user.accessToken);
  assert.equal(r.body.data.length, 3);
  r = await call('POST', `/api/trainers/${coach.data.uid}/reviews`, { stars: 4, text: 'Good' }, user.accessToken);
  r = await call('GET', `/api/trainers/${coach.data.uid}`);
  assert.equal(r.body.data.rating, 4);
  r = await call('GET', '/api/panel/dashboard', null, coach.accessToken);
  assert.equal(r.body.data.activeClients, 1);
  r = await call('POST', '/api/live/sessions', { title: 'Morning HIIT' }, coach.accessToken);
  assert.equal(r.status, 201);
  r = await call('GET', '/api/live/sessions?status=live');
  assert.ok(r.body.data.some((s) => s.title === 'Morning HIIT'));
  r = await call('GET', `/api/admin/trainers/${coach.data.uid}/detail`, null, admin.accessToken);
  assert.equal(r.status, 200); assert.equal(r.body.data.active, 1); assert.ok(r.body.data.replyMinutes !== undefined);
  r = await call('GET', '/api/admin/trainers', null, admin.accessToken);
  assert.ok(r.body.data.find((t) => t.id === coach.data.uid).revenue30d > 0);
  r = await call('POST', `/api/admin/trainers/${coach.data.uid}/assign`, { email: user2 ? user2.data.email : user.data.email }, admin.accessToken);
  assert.equal(r.status, 201); assert.equal(r.body.data.paymentStatus, 'complimentary');
});

test('community', async () => {
  let r = await call('POST', '/api/community/posts', { kind: 'poll', text: 'Best split?', options: ['PPL', 'Upper/Lower'] }, user.accessToken);
  const pid = r.body.data.id;
  r = await call('POST', `/api/community/posts/${pid}/vote`, { option: 1 }, user2.accessToken);
  assert.deepEqual(r.body.data.votes, [0, 1]);
  r = await call('POST', `/api/community/posts/${pid}/vote`, { option: 0 }, user2.accessToken);
  assert.deepEqual(r.body.data.votes, [1, 0]);
  r = await call('POST', `/api/community/posts/${pid}/like`, {}, user2.accessToken);
  assert.equal(r.body.count, 1);
  r = await call('POST', `/api/community/posts/${pid}/comments`, { text: 'PPL!' }, user2.accessToken);
  r = await call('GET', '/api/community/posts?limit=5', null, user.accessToken);
  const p = r.body.data.find((x) => x.id === pid);
  assert.equal(p.likes, 1); assert.equal(p.commentsCount, 1); assert.equal(p.mine, true);
  r = await call('DELETE', `/api/community/posts/${pid}`, null, user2.accessToken);
  assert.equal(r.status, 403);
});

test('firestore compatibility layer', async () => {
  const fsBase = '/fs/v1/projects/neurofit-9877b/databases/(default)/documents';
  let r = await call('POST', `${fsBase}/subscription_plans?documentId=pro_${uniq}`, { fields: { name: { stringValue: 'Pro' }, monthlyPrice: { doubleValue: 299 } } }, admin.accessToken);
  assert.equal(r.status, 200);
  r = await call('GET', `/api/plans/pro_${uniq}`);
  assert.equal(r.body.data.monthlyPrice, 299);
  r = await call('PATCH', `${fsBase}/subscription_plans/pro_${uniq}?updateMask.fieldPaths=name`, { fields: { name: { stringValue: 'Pro+' } } }, admin.accessToken);
  assert.equal(r.body.fields.name.stringValue, 'Pro+');
  assert.equal(r.body.fields.monthlyPrice.doubleValue, 299);
  r = await call('GET', `${fsBase}/subscription_plans`);
  assert.ok(r.body.documents.length >= 1);
  r = await call('PATCH', `${fsBase}/subscription_plans/pro_${uniq}`, { fields: {} }, user.accessToken);
  assert.equal(r.status, 403);
  r = await call('POST', `${fsBase}:runQuery`, { structuredQuery: { from: [{ collectionId: 'orders' }], where: { fieldFilter: { field: { fieldPath: 'uid' }, op: 'EQUAL', value: { stringValue: user.data.uid } } } } }, user2.accessToken);
  assert.ok(!r.body[0].document, 'cannot query other users orders');
});

test('admin stats', async () => {
  const r = await call('GET', '/api/admin/stats', null, admin.accessToken);
  assert.equal(r.status, 200);
  assert.ok(r.body.data.users.total >= 3);
  assert.ok(r.body.data.orders.total >= 1);
  assert.equal(r.body.data.series.signups.length, 30);
  const u = await call('GET', '/api/users?q=renamed', null, admin.accessToken);
  assert.ok(u.body.data.length >= 1);
});

test('admin stats, user list and user overview', async () => {
  let r = await call('GET', '/api/admin/stats', null, admin.accessToken);
  assert.equal(r.status, 200); assert.ok(r.body.data.users.total >= 1);
  r = await call('GET', '/api/admin/user-list?segment=new', null, admin.accessToken);
  assert.equal(r.status, 200);
  const me = r.body.data.find((u) => u.uid === user.data.uid);
  assert.ok(me); assert.ok(me.streak >= 1); assert.ok(me.orderCount >= 1);
  r = await call('GET', '/api/admin/user-list?segment=premium', null, admin.accessToken);
  assert.equal(r.status, 200);
  r = await call('GET', `/api/admin/users/${user.data.uid}/overview`, null, admin.accessToken);
  assert.equal(r.status, 200); assert.equal(r.body.data.user.uid, user.data.uid);
  r = await call('GET', '/api/admin/user-list', null, user.accessToken);
  assert.equal(r.status, 403);
});
