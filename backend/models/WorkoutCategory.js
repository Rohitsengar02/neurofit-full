const mongoose = require('mongoose');

const workoutCategorySchema = new mongoose.Schema(
  {
    id: { type: String, required: true, unique: true, index: true },
    name: { type: String, required: true },
    description: { type: String, default: '' },
    mediaType: {
      type: String,
      enum: ['image', 'gif', 'video'],
      default: 'image',
    },
    mediaUrl: { type: String, default: '' },
    sortOrder: { type: Number, default: 1 },
    isActive: { type: Boolean, default: true },
  },
  { timestamps: true }
);

workoutCategorySchema.pre('save', function (next) {
  if (!this.id) {
    this.id = `wcat_${Date.now()}`;
  }
  next();
});

module.exports = mongoose.model('WorkoutCategory', workoutCategorySchema);
