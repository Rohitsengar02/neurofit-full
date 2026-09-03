const mongoose = require('mongoose');

const exerciseCategorySchema = new mongoose.Schema(
  {
    categoryId: {
      type: String,
      required: true,
      unique: true,
      index: true,
    },
    name: {
      type: String,
      required: true,
      trim: true,
    },
    slug: {
      type: String,
      default: '',
    },
    description: {
      type: String,
      default: '',
    },
    imageUrl: {
      type: String,
      default: '',
    },
    mediaType: {
      type: String,
      enum: ['image', 'gif', 'video'],
      default: 'image',
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
    collection: 'exercise_categories',
  }
);

exerciseCategorySchema.pre('save', async function (next) {
  if (this.isNew && (!this.sortOrder || this.sortOrder === 0)) {
    try {
      const maxDoc = await this.constructor.findOne({}, { sortOrder: 1 }).sort({ sortOrder: -1 }).lean();
      this.sortOrder = maxDoc && typeof maxDoc.sortOrder === 'number' ? maxDoc.sortOrder + 1 : 1;
    } catch (e) {
      console.error('Error auto-incrementing ExerciseCategory sortOrder:', e);
    }
  }
  next();
});

module.exports = mongoose.model('ExerciseCategory', exerciseCategorySchema);
