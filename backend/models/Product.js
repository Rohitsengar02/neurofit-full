const mongoose = require('mongoose');

const productSchema = new mongoose.Schema({
  id: { type: String, required: true, unique: true, index: true },
  title: { type: String, required: true },
  description: { type: String, default: '' },
  sku: { type: String, default: '' },
  barcode: { type: String, default: '' },
  categoryId: { type: String, default: '' },
  categoryName: { type: String, default: 'General' },
  subcategoryId: { type: String, default: '' },
  subcategoryName: { type: String, default: '' },
  discountId: { type: String, default: '' },
  discountCode: { type: String, default: '' },
  price: { type: Number, default: 0.0 },
  regularPrice: { type: Number, default: 0.0 },
  costPerItem: { type: Number, default: 0.0 },
  stock: { type: Number, default: 0 },
  lowStockThreshold: { type: Number, default: 5 },
  brand: { type: String, default: 'NeuroFit' },
  vendor: { type: String, default: 'Official Store' },
  tags: [{ type: String }],
  status: { type: String, default: 'active' },
  mainImageUrl: { type: String, default: '' },
  additionalImages: [{ type: String }],
  variants: [{
    variantId: String,
    name: String,
    price: Number,
    stock: Number,
    sku: String,
    imageUrl: String
  }]
}, { timestamps: true });

module.exports = mongoose.model('Product', productSchema);
