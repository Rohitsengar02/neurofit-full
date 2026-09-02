const mongoose = require('mongoose');

const orderSchema = new mongoose.Schema({
  orderId: { type: String, required: true, unique: true, index: true },
  uid: { type: String, required: true, index: true },
  userEmail: { type: String, default: '' },
  userName: { type: String, default: '' },
  shippingAddress: {
    fullName: String,
    phoneNumber: String,
    streetAddress: String,
    city: String,
    state: String,
    pincode: String
  },
  items: [{
    productId: String,
    title: String,
    variant: String,
    price: Number,
    quantity: Number,
    imageUrl: String
  }],
  subtotal: { type: Number, default: 0.0 },
  shippingFee: { type: Number, default: 0.0 },
  tax: { type: Number, default: 0.0 },
  totalAmount: { type: Number, default: 0.0 },
  paymentMethod: { type: String, default: 'UPI' },
  paymentStatus: { type: String, default: 'Paid' },
  orderStatus: { type: String, default: 'Placed' },
  cancellationReason: { type: String, default: '' }
}, { timestamps: true });

module.exports = mongoose.model('Order', orderSchema);
