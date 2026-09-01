const mongoose = require('mongoose');

const DiscountSchema = new mongoose.Schema({
  discountId: { type: String, required: true, unique: true },
  title: { type: String, required: true },
  code: { type: String, required: true, uppercase: true, unique: true },
  type: { type: String, enum: ['percentage', 'fixed'], default: 'percentage' },
  value: { type: Number, required: true },
  minOrderValue: { type: Number, default: 0 },
  maxUses: { type: Number, default: 1000 },
  usedCount: { type: Number, default: 0 },
  status: { type: String, default: 'Active' },
  isActive: { type: Boolean, default: true }
}, { timestamps: true });

module.exports = mongoose.models.Discount || mongoose.model('Discount', DiscountSchema);
