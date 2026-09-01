const mongoose = require('mongoose');

const SubCategorySchema = new mongoose.Schema({
  id: { type: String, required: true, unique: true },
  parentCategoryId: { type: String, required: true },
  parentCategoryName: { type: String, required: true },
  name: { type: String, required: true },
  imageUrl: { type: String, default: '' },
  description: { type: String, default: '' },
  productCount: { type: Number, default: 0 },
  status: { type: String, default: 'active' },
  sortOrder: { type: Number, default: 1 }
}, { timestamps: true });

module.exports = mongoose.models.SubCategory || mongoose.model('SubCategory', SubCategorySchema);
