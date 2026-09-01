const mongoose = require('mongoose');

const addressSchema = new mongoose.Schema({
  uid: { type: String, required: true, index: true },
  fullName: { type: String, required: true },
  phoneNumber: { type: String, required: true },
  streetAddress: { type: String, required: true },
  city: { type: String, required: true },
  state: { type: String, default: 'State' },
  pincode: { type: String, required: true },
  isDefault: { type: Boolean, default: true }
}, { timestamps: true });

module.exports = mongoose.model('Address', addressSchema);
