const mongoose = require('mongoose');

const workoutLayoutSectionSchema = new mongoose.Schema(
  {
    id: { type: String, required: true, unique: true, index: true },
    sectionId: { type: String, index: true },
    title: { type: String, default: 'Workout Section' },
    subtitle: { type: String, default: '' },
    showTitle: { type: Boolean, default: true },
    showHeading: { type: Boolean, default: true },
    type: {
      type: String,
      enum: [
        'hero_banners',
        'categories',
        'popular_programs',
        'bento_spotlight',
        'muscle_groups',
        'celebrity_coaches',
        'equipment_training',
        'trending_challenges',
        'audio_beats',
        'custom_banner',
        'exercise_grid',
        'single_workout_card',
      ],
      default: 'popular_programs',
    },
    layoutMode: {
      type: String,
      enum: ['carousel', 'grid', 'bento', 'hero_carousel', 'card_list', 'square_cards'],
      default: 'carousel',
    },
    filterSource: {
      type: String,
      enum: ['all', 'featured', 'category', 'level', 'equipment', 'selected_ids', 'custom'],
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
    customBannerVideoUrl: { type: String, default: '' },
    customBannerTargetType: { type: String, default: 'program' },
    customBannerTargetId: { type: String, default: '' },
    customBannerButtonText: { type: String, default: 'Start Workout' },
    customBannerBadge: { type: String, default: '' },
  },
  { timestamps: true, strict: false }
);

workoutLayoutSectionSchema.pre('save', function (next) {
  if (!this.id && this.sectionId) this.id = this.sectionId;
  if (!this.sectionId && this.id) this.sectionId = this.id;
  if (this.sortOrder != null) this.displayOrder = this.sortOrder;
  if (this.showTitle != null) this.showHeading = this.showTitle;
  next();
});

module.exports = mongoose.model('WorkoutLayoutSection', workoutLayoutSectionSchema);
