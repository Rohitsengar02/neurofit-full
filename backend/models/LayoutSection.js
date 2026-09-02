const mongoose = require('mongoose');

const layoutSectionSchema = new mongoose.Schema(
  {
    id: { type: String, required: true, unique: true, index: true },
    sectionId: { type: String, index: true },
    title: { type: String, default: 'Section' },
    subtitle: { type: String, default: '' },
    showTitle: { type: Boolean, default: true },
    showHeading: { type: Boolean, default: true },
    type: {
      type: String,
      enum: ['banners', 'categories', 'subcategories', 'products', 'custom_promo', 'offers'],
      default: 'products',
    },
    layoutMode: {
      type: String,
      enum: ['carousel', 'grid', 'banner_strip', 'hero_carousel', 'two_column', 'list'],
      default: 'carousel',
    },
    filterSource: {
      type: String,
      enum: ['all', 'featured', 'trending', 'top_rated', 'category', 'subcategory', 'selected_ids', 'custom'],
      default: 'all',
    },
    filterId: { type: String, default: '' },
    filterName: { type: String, default: '' },
    selectedItemIds: [{ type: String }],
    itemLimit: { type: Number, default: 10 },
    sortOrder: { type: Number, default: 1 },
    displayOrder: { type: Number, default: 1 },
    isActive: { type: Boolean, default: true },
    customBannerImageUrl: { type: String, default: '' },
    customBannerTargetType: { type: String, default: 'category' },
    customBannerTargetId: { type: String, default: '' },
    customBannerButtonText: { type: String, default: 'Shop Now' },
    customBannerBadge: { type: String, default: '' },
  },
  { timestamps: true, strict: false }
);

layoutSectionSchema.pre('save', function (next) {
  if (!this.id && this.sectionId) this.id = this.sectionId;
  if (!this.sectionId && this.id) this.sectionId = this.id;
  if (this.sortOrder != null) this.displayOrder = this.sortOrder;
  if (this.showTitle != null) this.showHeading = this.showTitle;
  next();
});

module.exports = mongoose.model('LayoutSection', layoutSectionSchema);
