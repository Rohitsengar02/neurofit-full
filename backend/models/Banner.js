const mongoose = require('mongoose');

const bannerSchema = new mongoose.Schema({
  id: { type: String, required: true, unique: true, index: true },
  bannerId: { type: String, index: true },
  title: { type: String, default: '' },
  subtitle: { type: String, default: '' },
  imageUrl: { type: String, required: true },
  imageKey: { type: String, default: '' },
  mediaType: { type: String, enum: ['image', 'gif', 'video'], default: 'image' },
  showTitle: { type: Boolean, default: true },
  showHeading: { type: Boolean, default: true },
  targetType: { 
    type: String, 
    enum: ['category', 'product', 'screen', 'url', 'custom', 'discount', 'General', 'Category', 'Product', 'Screen', 'ExternalUrl', ''],
    default: 'category' 
  },
  targetId: { type: String, default: '' },
  targetName: { type: String, default: '' },
  buttonText: { type: String, default: 'Shop Now' },
  badge: { type: String, default: 'FEATURED' },
  badgeText: { type: String, default: '' },
  discountCode: { type: String, default: '' },
  linkUrl: { type: String, default: '' },
  sortOrder: { type: Number, default: 1 },
  displayOrder: { type: Number, default: 1 },
  status: { type: String, enum: ['Active', 'Inactive', 'active', 'inactive'], default: 'Active' },
  isActive: { type: Boolean, default: true },
  createdBy: { type: String, default: 'admin@neurofit.app' },
}, { timestamps: true });

// Sync id and bannerId before saving
bannerSchema.pre('save', function(next) {
  if (!this.bannerId && this.id) this.bannerId = this.id;
  if (!this.id && this.bannerId) this.id = this.bannerId;
  if (this.sortOrder !== undefined) this.displayOrder = this.sortOrder;
  if (this.displayOrder !== undefined) this.sortOrder = this.displayOrder;
  this.isActive = this.status.toLowerCase() === 'active';
  next();
});

module.exports = mongoose.model('Banner', bannerSchema);
