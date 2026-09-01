const mongoose = require('mongoose');

const layoutSectionSchema = new mongoose.Schema({
  id: { type: String, required: true, unique: true, index: true },
  title: { type: String, required: true },
  subtitle: { type: String, default: '' },
  layoutType: { type: String, default: 'grid' },
  productIds: [{ type: String }],
  isEnabled: { type: Boolean, default: true },
  sortOrder: { type: Number, default: 0 }
}, { timestamps: true });

module.exports = mongoose.model('LayoutSection', layoutSectionSchema);
