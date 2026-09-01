const mongoose = require('mongoose');

const bannerSchema = new mongoose.Schema({
  id: { type: String, required: true, unique: true, index: true },
  title: { type: String, default: '' },
  subtitle: { type: String, default: '' },
  imageUrl: { type: String, required: true },
  linkUrl: { type: String, default: '' },
  tag: { type: String, default: '' },
  badgeText: { type: String, default: '' },
  ctaText: { type: String, default: 'Shop Now' },
  targetScreen: { type: String, default: '' },
  targetCategory: { type: String, default: '' },
  targetProductId: { type: String, default: '' },
  status: { type: String, default: 'active' },
  displayOrder: { type: Number, default: 0 }
}, { timestamps: true });

module.exports = mongoose.model('Banner', bannerSchema);
