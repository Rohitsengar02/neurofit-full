const mongoose = require('mongoose');

const exerciseSchema = new mongoose.Schema(
  {
    id: { type: String, required: true, unique: true, index: true },
    title: { type: String, required: true },
    categoryId: { type: String, default: '' },
    category: { type: String, default: 'General' },
    muscleGroup: { type: String, default: 'Full Body' },
    equipment: { type: String, default: 'Bodyweight' },
    difficulty: { type: String, enum: ['Beginner', 'Intermediate', 'Advanced'], default: 'Intermediate' },
    sets: { type: Number, default: 3 },
    reps: { type: String, default: '10-12 reps' },
    imageUrl: { type: String, default: '' },
    gifUrl: { type: String, default: '' },
    videoUrl: { type: String, default: '' },
    mediaType: { type: String, enum: ['image', 'gif', 'video'], default: 'image' },
    mediaUrls: [{ type: String }],
    instructions: [{ type: String }],
    tips: { type: String, default: '' },
    sortOrder: { type: Number, default: 0 },
    isActive: { type: Boolean, default: true },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Exercise', exerciseSchema);
