const mongoose = require('mongoose');

const categorySchema = new mongoose.Schema({
  id: { type: String, required: true, unique: true, index: true },
  name: { type: String, required: true },
  imageUrl: { type: String, default: '' },
  description: { type: String, default: '' },
  productCount: { type: Number, default: 0 },
  status: { type: String, default: 'active' }
}, { timestamps: true });

module.exports = mongoose.model('Category', categorySchema);
