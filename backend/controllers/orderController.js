const Order = require('../models/Order');
const Notification = require('../models/Notification');
const fcmService = require('../services/fcmService');
const redisService = require('../services/redisService');

// CREATE NEW ORDER (Full Real-Time with Socket.io, MongoDB, and FCM Push Notification)
exports.createOrder = async (req, res) => {
  try {
    const { orderId, uid, totalAmount, items, shippingAddress } = req.body;
    const id = orderId || `NF-ORD-${Date.now()}`;

    // 1. Save in MongoDB orders collection
    const order = await Order.create({
      ...req.body,
      orderId: id,
      totalAmount: Number(totalAmount) || 0,
      createdAt: new Date()
    });

    console.log(`🛒 Real-Time Order Placed in MongoDB: #${order.orderId} (₹${order.totalAmount}) for user: ${order.uid}`);

    if (order.uid && req.body.fcmToken) {
      try {
        const User = require('../models/User');
        await User.findOneAndUpdate(
          { uid: order.uid },
          { $set: { fcmToken: req.body.fcmToken } },
          { upsert: false }
        );
      } catch (_) {}
    }

    // Invalidate Redis cache for user and all orders
    await redisService.del(`orders:user:${order.uid}`);
    await redisService.delPattern('orders:all:*');

    // 2. Create Notification Document in MongoDB notifications collection
    let notification = null;
    try {
      notification = await Notification.create({
        notificationId: `notif_${Date.now()}_${Math.floor(Math.random() * 1000)}`,
        uid: order.uid,
        title: 'Order Placed Successfully! 🎉',
        message: `Your order #${order.orderId} for ₹${Number(order.totalAmount).toFixed(0)} has been placed. We are preparing it for delivery!`,
        type: 'ORDER_PLACED',
        data: {
          orderId: order.orderId,
          totalAmount: order.totalAmount,
          itemsCount: (order.items || []).length,
          paymentMethod: order.paymentMethod
        },
        createdAt: new Date()
      });
      console.log(`🔔 Notification saved in MongoDB notifications collection: ${notification.notificationId}`);
    } catch (notifErr) {
      console.error('Error creating notification document:', notifErr.message);
    }

    // 3. Real-Time Socket.io Broadcasts
    if (req.io) {
      // Global broadcast for admin dashboards
      req.io.emit('order:created', order);
      req.io.to('admin_room').emit('admin:new_order', order);

      // User specific room
      if (order.uid) {
        req.io.to(`user_${order.uid}`).emit('order:user_created', order);
        if (notification) {
          req.io.to(`user_${order.uid}`).emit('notification:received', notification);
        }
      }

      // Notification broadcast
      if (notification) {
        req.io.emit('notification:new', notification);
      }
      console.log(`⚡ Real-Time Socket.io events emitted for order #${order.orderId}`);
    }

    // 4. Send Firebase Cloud Messaging (FCM) Push Notification
    try {
      const fcmResult = await fcmService.sendOrderPlacedPush(order);
      if (notification && fcmResult && fcmResult.success) {
        notification.fcmMessageId = fcmResult.messageId || '';
        notification.fcmStatus = 'sent';
        await notification.save();
      }
    } catch (fcmErr) {
      console.warn('FCM push error notice:', fcmErr.message);
    }

    res.status(201).json({
      success: true,
      message: 'Order created successfully and notification dispatched!',
      data: order,
      notification: notification
    });
  } catch (err) {
    console.error('Error in createOrder:', err.message);
    res.status(500).json({ success: false, message: err.message });
  }
};

// GET ALL ORDERS (for Admin / Monitoring with Redis Acceleration)
exports.getAllOrders = async (req, res) => {
  try {
    const { status, limit = 100, page = 1 } = req.query;
    const cacheKey = `orders:all:${status || 'all'}:${limit}:${page}`;

    const cached = await redisService.get(cacheKey);
    if (cached) {
      return res.json({ ...cached, source: 'redis' });
    }

    const filter = {};
    if (status) filter.orderStatus = status;

    const orders = await Order.find(filter)
      .sort({ createdAt: -1 })
      .limit(Number(limit))
      .skip((Number(page) - 1) * Number(limit));

    const total = await Order.countDocuments(filter);
    const responsePayload = {
      success: true,
      count: orders.length,
      total,
      data: orders
    };

    await redisService.set(cacheKey, responsePayload, 120);
    res.json({ ...responsePayload, source: 'mongo' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// GET SINGLE ORDER BY ORDER ID
exports.getOrderById = async (req, res) => {
  try {
    const { orderId } = req.params;
    const cacheKey = `orders:single:${orderId}`;

    const cached = await redisService.get(cacheKey);
    if (cached) {
      return res.json({ success: true, data: cached, source: 'redis' });
    }

    const order = await Order.findOne({
      $or: [{ orderId }, { _id: orderId.match(/^[0-9a-fA-F]{24}$/) ? orderId : null }]
    });

    if (!order) {
      return res.status(404).json({ success: false, message: 'Order not found' });
    }

    await redisService.set(cacheKey, order, 300);
    res.json({ success: true, data: order, source: 'mongo' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// GET ORDERS FOR SPECIFIC USER (Redis Cached + Mongo Atlas)
exports.getUserOrders = async (req, res) => {
  try {
    const { uid } = req.params;
    const cacheKey = `orders:user:${uid}`;

    // 1. Try Redis cache
    const cached = await redisService.get(cacheKey);
    if (cached) {
      return res.json({ success: true, count: cached.length, data: cached, source: 'redis' });
    }

    // 2. Fetch from MongoDB
    const orders = await Order.find({ uid }).sort({ createdAt: -1 });

    // 3. Cache in Redis with 5 min TTL
    await redisService.set(cacheKey, orders, 300);

    res.json({ success: true, count: orders.length, data: orders, source: 'mongo' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// UPDATE ORDER STATUS (Real-Time with Socket.io & FCM Push + Redis Invalidation)
exports.updateOrderStatus = async (req, res) => {
  try {
    const { orderId } = req.params;
    const { orderStatus, paymentStatus, cancellationReason } = req.body;

    const updateFields = {};
    if (orderStatus) updateFields.orderStatus = orderStatus;
    if (paymentStatus) updateFields.paymentStatus = paymentStatus;
    if (cancellationReason) updateFields.cancellationReason = cancellationReason;
    updateFields.updatedAt = new Date();

    const order = await Order.findOneAndUpdate(
      {
        $or: [
          { orderId },
          { id: orderId },
          { _id: orderId.match(/^[0-9a-fA-F]{24}$/) ? orderId : null }
        ]
      },
      updateFields,
      { new: true }
    );

    if (!order) {
      return res.status(404).json({ success: false, message: 'Order not found' });
    }

    console.log(`📦 Order #${orderId} status updated to: ${orderStatus || order.orderStatus}`);

    // Invalidate Redis caches
    await redisService.del(`orders:user:${order.uid}`);
    await redisService.del(`orders:single:${orderId}`);
    await redisService.delPattern('orders:all:*');

    // Create status notification in MongoDB
    let notification = null;
    if (orderStatus) {
      const isCancelled = orderStatus.toLowerCase() === 'cancelled';
      const notifTitle = isCancelled ? 'Order Cancelled ❌' : `Order Update: ${orderStatus}`;
      const notifMessage = isCancelled
        ? `Your order #${order.orderId} has been cancelled.${cancellationReason ? ' Reason: ' + cancellationReason : ''}`
        : `Your order #${order.orderId} status has been updated to "${orderStatus}".`;

      try {
        notification = await Notification.create({
          notificationId: `notif_${Date.now()}_${Math.floor(Math.random() * 1000)}`,
          uid: order.uid,
          title: notifTitle,
          message: notifMessage,
          type: isCancelled ? 'ORDER_CANCELLED' : 'ORDER_STATUS',
          data: {
            orderId: order.orderId,
            status: orderStatus,
            cancellationReason: cancellationReason || ''
          },
          createdAt: new Date()
        });
      } catch (err) {
        console.error('Error creating status notification:', err.message);
      }

      // Send FCM push for status update / cancellation
      try {
        await fcmService.sendOrderStatusPush(order, orderStatus, cancellationReason);
      } catch (e) {
        console.warn('FCM status push notice:', e.message);
      }
    }

    // Socket.io Real-time update
    if (req.io) {
      req.io.emit('order:updated', order);
      if (order.uid) {
        req.io.to(`user_${order.uid}`).emit('order:user_updated', order);
        if (notification) {
          req.io.to(`user_${order.uid}`).emit('notification:received', notification);
        }
      }
    }

    res.json({
      success: true,
      message: 'Order status updated successfully',
      data: order,
      notification
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// DELETE / CANCEL ORDER
exports.deleteOrder = async (req, res) => {
  try {
    const { orderId } = req.params;
    const order = await Order.findOneAndDelete({ orderId });

    if (!order) {
      return res.status(404).json({ success: false, message: 'Order not found' });
    }

    // Invalidate Redis caches
    await redisService.del(`orders:user:${order.uid}`);
    await redisService.del(`orders:single:${orderId}`);
    await redisService.delPattern('orders:all:*');

    if (req.io) {
      req.io.emit('order:deleted', { orderId });
      req.io.to(`user_${order.uid}`).emit('order:user_deleted', { orderId });
    }

    // Push notification on order deletion
    try {
      await fcmService.sendOrderCancelledPush(order, 'Order removed/cancelled');
    } catch (_) {}

    res.json({ success: true, message: `Order #${orderId} deleted successfully` });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};
