const Notification = require('../models/Notification');
const fcmService = require('../services/fcmService');

// GET ALL NOTIFICATIONS FOR USER
exports.getUserNotifications = async (req, res) => {
  try {
    const { uid } = req.params;
    const notifications = await Notification.find({ uid }).sort({ createdAt: -1 }).limit(50);
    const unreadCount = await Notification.countDocuments({ uid, isRead: false });

    res.json({
      success: true,
      count: notifications.length,
      unreadCount,
      data: notifications
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// MARK NOTIFICATION AS READ
exports.markNotificationRead = async (req, res) => {
  try {
    const { notificationId } = req.params;
    const notification = await Notification.findOneAndUpdate(
      { notificationId },
      { isRead: true },
      { new: true }
    );

    if (!notification) {
      return res.status(404).json({ success: false, message: 'Notification not found' });
    }

    if (req.io) {
      req.io.to(`user_${notification.uid}`).emit('notification:read', { notificationId });
    }

    res.json({ success: true, data: notification });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// MARK ALL AS READ
exports.markAllRead = async (req, res) => {
  try {
    const { uid } = req.params;
    await Notification.updateMany({ uid, isRead: false }, { isRead: true });

    if (req.io) {
      req.io.to(`user_${uid}`).emit('notification:all_read', { uid });
    }

    res.json({ success: true, message: 'All notifications marked as read' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// SEND CUSTOM NOTIFICATION (from admin or system)
exports.sendNotification = async (req, res) => {
  try {
    const { uid, title, message, type = 'GENERAL', data = {} } = req.body;
    if (!title || !message) {
      return res.status(400).json({ success: false, message: 'Title and message are required' });
    }

    const notification = await Notification.create({
      notificationId: `notif_${Date.now()}_${Math.floor(Math.random() * 1000)}`,
      uid: uid || 'global',
      title,
      message,
      type,
      data,
      createdAt: new Date()
    });

    // Real-time socket broadcast
    if (req.io) {
      if (uid && uid !== 'global') {
        req.io.to(`user_${uid}`).emit('notification:received', notification);
      } else {
        req.io.emit('notification:received', notification);
      }
      req.io.emit('notification:new', notification);
    }

    // FCM Push
    try {
      const fcmResult = await fcmService.sendPushNotification({
        uid,
        title,
        body: message,
        data
      });
      if (fcmResult.success) {
        notification.fcmMessageId = fcmResult.messageId || '';
        notification.fcmStatus = 'sent';
        await notification.save();
      }
    } catch (e) {}

    res.status(201).json({
      success: true,
      message: 'Notification sent successfully',
      data: notification
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// GET PUBLIC FIREBASE WEB CONFIGURATION (Read strictly from process.env)
exports.getFirebaseConfig = async (req, res) => {
  res.json({
    success: true,
    config: {
      apiKey: process.env.FIREBASE_API_KEY || '',
      authDomain: process.env.FIREBASE_AUTH_DOMAIN || '',
      projectId: process.env.FIREBASE_PROJECT_ID || '',
      storageBucket: process.env.FIREBASE_STORAGE_BUCKET || '',
      messagingSenderId: process.env.FIREBASE_MESSAGING_SENDER_ID || '',
      appId: process.env.FIREBASE_APP_ID || '',
      measurementId: process.env.FIREBASE_MEASUREMENT_ID || ''
    },
    vapidKey: process.env.FIREBASE_VAPID_PUBLIC_KEY || process.env.FIREBASE_VAPID_KEY || ''
  });
};

// GET VAPID PUBLIC KEY FOR WEB PUSH NOTIFICATIONS
exports.getVapidKey = async (req, res) => {
  res.json({
    success: true,
    vapidKey: process.env.FIREBASE_VAPID_PUBLIC_KEY || process.env.FIREBASE_VAPID_KEY || ''
  });
};

// REGISTER BROWSER / DEVICE FCM TOKEN AND SUBSCRIBE TO TOPICS
exports.registerToken = async (req, res) => {
  try {
    const { token, uid, role } = req.body;
    if (!token) {
      return res.status(400).json({ success: false, message: 'Token is required' });
    }

    if (uid) {
      const User = require('../models/User');
      await User.findOneAndUpdate(
        { uid },
        { $set: { fcmToken: token }, $addToSet: { fcmTokens: token } },
        { upsert: false }
      );
    }

    const adminSDK = require('../config/firebaseAdmin');
    const topics = ['orders_updates', 'broadcast'];
    if (role === 'admin') topics.push('admin_orders');
    if (uid) topics.push(`user_${uid}`);

    for (const t of topics) {
      try {
        await adminSDK.messaging().subscribeToTopic(token, t);
      } catch (subErr) {
        console.warn(`Notice subscribing to topic ${t}:`, subErr.message);
      }
    }

    console.log(`📲 FCM Token registered & subscribed to push topics: ${topics.join(', ')}`);
    res.json({ success: true, message: 'Token registered and subscribed to topics', topics });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// TEST PUSH NOTIFICATION
exports.testPush = async (req, res) => {
  try {
    const { token, topic = 'orders_updates', title = '🔔 NeuroFit Test Notification', body = 'Web Push notifications are now active and working!' } = req.body;
    const result = await fcmService.sendPushNotification({
      token,
      topic: token ? undefined : topic,
      title,
      body,
      data: { type: 'TEST_PUSH', time: new Date().toISOString() }
    });
    res.json(result);
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};
