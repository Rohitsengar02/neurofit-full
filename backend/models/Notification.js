const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema({
  notificationId: { type: String, required: true, unique: true, index: true },
  uid: { type: String, required: true, index: true },
  title: { type: String, required: true },
  message: { type: String, required: true },
  type: {
    type: String,
    enum: ['ORDER_PLACED', 'ORDER_STATUS', 'SYSTEM', 'PROMOTION'],
    default: 'ORDER_PLACED'
  },
  data: {
    orderId: { type: String, default: '' },
    totalAmount: { type: Number, default: 0 },
    itemsCount: { type: Number, default: 0 },
    additionalData: { type: Object, default: {} }
  },
  isRead: { type: Boolean, default: false },
  fcmMessageId: { type: String, default: '' },
  fcmStatus: { type: String, default: 'pending' }, // pending, sent, failed
}, { timestamps: true });

module.exports = mongoose.model('Notification', notificationSchema);
