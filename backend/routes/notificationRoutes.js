const express = require('express');
const router = express.Router();
const notificationController = require('../controllers/notificationController');

// GET all notifications for user
router.get('/user/:uid', notificationController.getUserNotifications);

// MARK single notification read
router.put('/:notificationId/read', notificationController.markNotificationRead);

// MARK all read for user
router.put('/user/:uid/read-all', notificationController.markAllRead);

// GET Firebase Public Web Configuration (securely from .env)
router.get('/firebase-config', notificationController.getFirebaseConfig);

// GET VAPID Web Push Public Key
router.get('/vapid-key', notificationController.getVapidKey);

// REGISTER FCM Device / Web Push Token
router.post('/register-token', notificationController.registerToken);

// TEST Push Notification
router.post('/test', notificationController.testPush);

// SEND custom push notification
router.post('/send', notificationController.sendNotification);

module.exports = router;
