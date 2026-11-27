// Orders and coupon validation.
const express = require('express');
const realtime = require('../lib/realtime');
const docs = require('../lib/docs');
const { query, one } = require('../db');
const { requireAuth, requireAdmin, isAdmin } = require('../lib/auth');
const { notify } = require('./notifications');

const discounts = express.Router();

discounts.post('/validate', async (req, res) => {
  const code = String(req.body.code || '').trim().toUpperCase();
  const orderValue = Number(req.body.orderValue || req.body.subtotal || 0);
  const row = await one(
    `SELECT * FROM docs WHERE collection = 'discounts' AND upper(data->>'code') = $1 LIMIT 1`,
    [code]
  );
  const d = row && row.data;
  const active = d && d.isActive !== false && String(d.status || 'active').toLowerCase() !== 'inactive';
  if (!d || !active) return res.status(400).json({ success: false, message: 'Invalid coupon code' });
  if (d.expiryDate || d.endDate) {
    const end = new Date(d.expiryDate || d.endDate);
    if (!Number.isNaN(end.getTime()) && end < new Date()) return res.status(400).json({ success: false, message: 'This coupon has expired' });
  }
  const min = Number(d.minOrderValue || 0);
  if (orderValue < min) return res.status(400).json({ success: false, message: `Minimum order value for ${code} is ₹${Math.round(min)}` });
  const usageLimit = Number(d.usageLimit || 0);
  if (usageLimit && Number(d.usedCount || 0) >= usageLimit) return res.status(400).json({ success: false, message: 'This coupon has been fully used' });
  const value = Number(d.value || d.discountValue || 0);
  const type = String(d.type || d.discountType || 'percentage').toLowerCase();
  let amount = type.startsWith('percent') ? (orderValue * value) / 100 : value;
  if (d.maxDiscount) amount = Math.min(amount, Number(d.maxDiscount));
  amount = Math.min(amount, orderValue);
  res.json({
    success: true,
    data: { code, type, value, discountAmount: amount, finalAmount: orderValue - amount, title: d.title || code },
  });
});

const orders = express.Router();

const ORDER_STATUSES = ['Pending', 'Confirmed', 'Processing', 'Packed', 'Shipped', 'Out for Delivery', 'Delivered', 'Cancelled', 'Returned'];

orders.post('/', requireAuth, async (req, res) => {
  const body = req.body || {};
  const id = String(body.orderId || body.id || docs.newId('ord'));
  const existing = await docs.get('orders', id);
  if (existing) {
    // Offline replays send the same order twice; keep the first one.
    if (existing.owner_id !== req.user.id) return res.status(409).json({ success: false, message: 'Order id clash' });
    return res.json({ success: true, data: docs.toItem(existing, 'orderId') });
  }
  const user = await one('SELECT name, email, phone FROM users WHERE id = $1', [req.user.id]);
  const order = {
    ...body,
    orderId: id,
    uid: req.user.id,
    userId: req.user.id,
    customerName: body.customerName || (user && user.name) || '',
    customerEmail: body.customerEmail || (user && user.email) || '',
    orderStatus: body.orderStatus || 'Pending',
    paymentStatus: body.paymentStatus || (String(body.paymentMethod || '').toLowerCase() === 'cod' ? 'Pending' : 'Paid'),
  };
  const row = await docs.upsert('orders', id, order, { ownerId: req.user.id });
  realtime.toAdmins('order:created', { id });
  realtime.toAdmins('admin:new_order', { id });
  realtime.toUser(req.user.id, 'order:user_created', { id });
  // coupon usage + stock
  if (body.couponCode) {
    await query(
      `UPDATE docs SET data = jsonb_set(data, '{usedCount}', to_jsonb(COALESCE((data->>'usedCount')::int, 0) + 1))
       WHERE collection = 'discounts' AND upper(data->>'code') = upper($1)`,
      [String(body.couponCode)]
    );
  }
  for (const it of Array.isArray(body.items) ? body.items : []) {
    const pid = it.productId || it.id;
    const qty = Number(it.quantity || it.qty || 1);
    if (!pid) continue;
    await query(
      `UPDATE docs SET data = jsonb_set(data, '{stock}', to_jsonb(GREATEST(COALESCE((data->>'stock')::int, 0) - $2, 0)))
       WHERE collection = 'products' AND id = $1 AND data ? 'stock'`,
      [String(pid), qty]
    );
  }
  notify({ userId: null, audience: 'admins', title: 'New order', body: `${order.customerName || 'A customer'} placed order ${id}`, type: 'order', refId: id }).catch(() => {});
  res.status(201).json({ success: true, data: docs.toItem(row, 'orderId') });
});

orders.get('/user/:uid', requireAuth, async (req, res) => {
  const uid = isAdmin(req) ? req.params.uid : req.user.id;
  const rows = await docs.list('orders', { ownerId: uid, order: 'new', limit: 200 });
  res.json({ success: true, data: rows.map((r) => docs.toItem(r, 'orderId')) });
});

orders.get('/mine', requireAuth, async (req, res) => {
  const rows = await docs.list('orders', { ownerId: req.user.id, order: 'new', limit: 200 });
  res.json({ success: true, data: rows.map((r) => docs.toItem(r, 'orderId')) });
});

orders.get('/', requireAdmin, async (req, res) => {
  const filters = {};
  if (req.query.status) filters.orderStatus = req.query.status;
  const rows = await docs.list('orders', {
    filters, order: 'new', limit: Number(req.query.limit) || 500, offset: Number(req.query.offset) || 0,
    search: req.query.q, searchFields: ['orderId', 'customerName', 'customerEmail'],
  });
  const data = rows.map((r) => docs.toItem(r, 'orderId'));
  res.json({ success: true, count: data.length, data });
});

orders.get('/:id', requireAuth, async (req, res) => {
  const row = await docs.find('orders', req.params.id);
  if (!row || (!isAdmin(req) && row.owner_id !== req.user.id)) return res.status(404).json({ success: false, message: 'Order not found' });
  res.json({ success: true, data: docs.toItem(row, 'orderId') });
});

async function setStatus(req, res) {
  const row = await docs.find('orders', req.params.id);
  if (!row || (!isAdmin(req) && row.owner_id !== req.user.id)) return res.status(404).json({ success: false, message: 'Order not found' });
  const status = String(req.body.orderStatus || req.body.status || '');
  if (!isAdmin(req) && status !== 'Cancelled') return res.status(403).json({ success: false, message: 'You can only cancel your order' });
  const patch = { orderStatus: status || row.data.orderStatus };
  if (req.body.paymentStatus) patch.paymentStatus = req.body.paymentStatus;
  if (req.body.trackingNumber) patch.trackingNumber = req.body.trackingNumber;
  if (req.body.cancellationReason) patch.cancellationReason = String(req.body.cancellationReason).slice(0, 500);
  const history = Array.isArray(row.data.statusHistory) ? row.data.statusHistory : [];
  patch.statusHistory = [...history, { status: patch.orderStatus, at: new Date().toISOString() }];
  const updated = await docs.upsert('orders', row.id, patch);
  realtime.toUser(row.owner_id, 'order:user_updated', { id: row.id, status: patch.orderStatus });
  realtime.toAdmins('order_status_updated', { id: row.id, status: patch.orderStatus });
  if (isAdmin(req) && row.owner_id) {
    notify({ userId: row.owner_id, title: 'Order update', body: `Your order ${row.id} is now ${patch.orderStatus}`, type: 'order', refId: row.id }).catch(() => {});
  }
  res.json({ success: true, data: docs.toItem(updated, 'orderId') });
}
orders.put('/:id/status', requireAuth, setStatus);
orders.patch('/:id/status', requireAuth, setStatus);
orders.post('/:id/status', requireAuth, setStatus);

orders.put('/:id', requireAdmin, async (req, res) => {
  const row = await docs.find('orders', req.params.id);
  if (!row) return res.status(404).json({ success: false, message: 'Order not found' });
  const updated = await docs.upsert('orders', row.id, req.body || {});
  res.json({ success: true, data: docs.toItem(updated, 'orderId') });
});

module.exports = { discounts, orders, ORDER_STATUSES };
