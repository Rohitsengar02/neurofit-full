const mongoose = require('mongoose');

const workoutBannerSchema = new mongoose.Schema(
  {
    bannerId: {
      type: String,
      required: true,
      unique: true,
      index: true,
    },
    title: {
      type: String,
      default: '',
    },
    subtitle: {
      type: String,
      default: '',
    },
    imageUrl: {
      type: String,
      required: true,
    },
    mediaType: {
      type: String,
      enum: ['image', 'gif', 'video'],
      default: 'image',
    },
    targetType: {
      type: String,
      default: 'category',
    },
    targetId: {
      type: String,
      default: '',
    },
    targetName: {
      type: String,
      default: '',
    },
    badge: {
      type: String,
      default: '',
    },
    buttonText: {
      type: String,
      default: 'Explore',
    },
    showTitle: {
      type: Boolean,
      default: true,
    },
    sortOrder: {
      type: Number,
      default: 0,
    },
    isActive: {
      type: Boolean,
      default: true,
    },
  },
  {
    timestamps: true,
    collection: 'workout_banners',
  }
);

workoutBannerSchema.pre('save', async function (next) {
  if (this.isNew && this.sortOrder === 0) {
    try {
      const maxDoc = await this.constructor.findOne({}, { sortOrder: 1 }).sort({ sortOrder: -1 }).lean();
      this.sortOrder = maxDoc && typeof maxDoc.sortOrder === 'number' ? maxDoc.sortOrder + 1 : 1;
    } catch (e) {
      console.error('Error auto-incrementing workout banner sortOrder:', e);
    }
  }
  next();
});

module.exports = mongoose.model('WorkoutBanner', workoutBannerSchema);
