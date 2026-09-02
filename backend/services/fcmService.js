const admin = require('../config/firebaseAdmin');
const User = require('../models/User');

/**
 * Send FCM Push Notification to a user or topic
 * @param {Object} options
 * @param {String} options.uid - User ID to look up registered device FCM token
 * @param {String} options.token - Direct FCM device registration token (optional)
 * @param {String} options.topic - FCM topic (e.g. 'orders', 'user_uid') (optional)
 * @param {String} options.title - Notification Title
 * @param {String} options.body - Notification Body
 * @param {Object} options.data - Additional data payload (key-value strings)
 */
async function sendPushNotification({ uid, token, topic, title, body, data = {} }) {
  try {
    let targetToken = token;

    // If no direct token was passed, lookup User's FCM token in MongoDB
    if (!targetToken && uid) {
      const user = await User.findOne({ uid });
      if (user && user.fcmToken) {
        targetToken = user.fcmToken;
      }
    }

    const payloadData = {};
    for (const [key, value] of Object.entries(data)) {
      payloadData[key] = typeof value === 'string' ? value : JSON.stringify(value);
    }

    const message = {
      notification: {
        title: title || 'NeuroFit Notification',
        body: body || '',
      },
      data: payloadData,
      webpush: {
        headers: {
          Urgency: 'high',
        },
        notification: {
          title: title || 'NeuroFit Notification',
          body: body || '',
          icon: '/favicon.png',
          badge: '/favicon.png',
          requireInteraction: true,
        },
        fcmOptions: {
          link: '/',
        },
      },
      android: {
        priority: 'high',
        notification: {
          title: title || 'NeuroFit Notification',
          body: body || '',
          sound: 'default',
          channelId: 'neurofit_orders',
          priority: 'high',
          visibility: 'public',
          defaultSound: true,
          defaultVibrateTimings: true,
        },
      },
    };

    if (targetToken) {
      message.token = targetToken;
      console.log(`📲 Sending FCM push notification directly to device token for user: ${uid || 'client'}...`);
    } else {
      // Fallback to topic: either user-specific topic or global 'orders_updates' topic
      const targetTopic = topic || (uid ? `user_${uid}` : 'orders_updates');
      message.topic = targetTopic;
      console.log(`📡 Sending FCM push notification to topic '${targetTopic}'...`);
    }

    const response = await admin.messaging().send(message);
    console.log(`✅ FCM Push Notification successfully dispatched! Message ID: ${response}`);
    return { success: true, messageId: response };
  } catch (err) {
    console.warn(`⚠️ FCM Dispatch Notice: ${err.code || err.message}`);
    return { success: false, error: err.message, code: err.code };
  }
}

/**
 * Send order placed push notification
 */
async function sendOrderPlacedPush(order) {
  const title = 'Order Placed Successfully! 🎉';
  const body = `Your order #${order.orderId} for ₹${Number(order.totalAmount).toFixed(0)} has been placed. We are preparing it for delivery!`;

  const userRes = await sendPushNotification({
    uid: order.uid,
    token: order.fcmToken || undefined,
    topic: `user_${order.uid}`,
    title,
    body,
    data: {
      type: 'ORDER_PLACED',
      orderId: String(order.orderId),
      totalAmount: String(order.totalAmount),
      paymentMethod: String(order.paymentMethod || 'UPI'),
      orderStatus: String(order.orderStatus || 'Placed'),
      timestamp: new Date().toISOString()
    }
  });

  // Also broadcast to admin_orders topic for real-time admin web push notification
  try {
    await sendPushNotification({
      topic: 'admin_orders',
      title: '🛒 New Order Received!',
      body: `Order #${order.orderId} for ₹${Number(order.totalAmount).toFixed(0)} (${order.paymentMethod || 'COD'})`,
      data: {
        type: 'NEW_ORDER_ADMIN',
        orderId: String(order.orderId),
        totalAmount: String(order.totalAmount),
        timestamp: new Date().toISOString()
      }
    });
  } catch (_) {}

  return userRes;
}

/**
 * Send order status update push notification
 */
async function sendOrderStatusPush(order, newStatus, reason = '') {
  if (newStatus && newStatus.toLowerCase() === 'cancelled') {
    return await sendOrderCancelledPush(order, reason || order.cancellationReason);
  }

  const statusEmojis = {
    'Processing': '⚙️',
    'Shipped': '🚚',
    'Out for Delivery': '🛵',
    'Delivered': '✅',
    'Cancelled': '❌'
  };
  const emoji = statusEmojis[newStatus] || '📦';
  const title = `Order Update: ${newStatus} ${emoji}`;
  const body = `Your order #${order.orderId} status has been updated to "${newStatus}".`;

  const userRes = await sendPushNotification({
    uid: order.uid,
    token: order.fcmToken || undefined,
    topic: `user_${order.uid}`,
    title,
    body,
    data: {
      type: 'ORDER_STATUS',
      orderId: String(order.orderId),
      status: String(newStatus),
      timestamp: new Date().toISOString()
    }
  });

  // Notify admin topic when order status changes
  try {
    await sendPushNotification({
      topic: 'admin_orders',
      title: `📦 Order #${order.orderId} Updated`,
      body: `Status is now "${newStatus}" for customer ${order.userName || order.shippingAddress?.fullName || 'Athlete'}`,
      data: {
        type: 'ORDER_STATUS_ADMIN',
        orderId: String(order.orderId),
        status: String(newStatus),
        timestamp: new Date().toISOString()
      }
    });
  } catch (_) {}

  return userRes;
}

/**
 * Send order cancellation push notification (To User & Admin)
 */
async function sendOrderCancelledPush(order, reason) {
  const reasonText = reason ? ` Reason: ${reason}` : '';
  const userTitle = 'Order Cancelled ❌';
  const userBody = `Your order #${order.orderId} for ₹${Number(order.totalAmount).toFixed(0)} has been cancelled.${reasonText}`;

  // 1. Send push to user
  const userRes = await sendPushNotification({
    uid: order.uid,
    token: order.fcmToken || undefined,
    topic: `user_${order.uid}`,
    title: userTitle,
    body: userBody,
    data: {
      type: 'ORDER_CANCELLED',
      orderId: String(order.orderId),
      reason: String(reason || ''),
      status: 'Cancelled',
      timestamp: new Date().toISOString()
    }
  });

  // 2. Also broadcast to admin_orders topic
  try {
    await sendPushNotification({
      topic: 'admin_orders',
      title: '⚠️ Order Cancelled Alert',
      body: `Order #${order.orderId} (₹${Number(order.totalAmount).toFixed(0)}) was cancelled.${reasonText}`,
      data: {
        type: 'ORDER_CANCELLED_ADMIN',
        orderId: String(order.orderId),
        reason: String(reason || ''),
        status: 'Cancelled',
        timestamp: new Date().toISOString()
      }
    });
  } catch (_) {}

  return userRes;
}

module.exports = {
  sendPushNotification,
  sendOrderPlacedPush,
  sendOrderStatusPush,
  sendOrderCancelledPush
};
