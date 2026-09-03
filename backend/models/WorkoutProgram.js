const mongoose = require('mongoose');

const workoutProgramSchema = new mongoose.Schema(
  {
    id: { type: String, required: true, unique: true, index: true },
    title: { type: String, required: true },
    subtitle: { type: String, default: '' },
    coach: { type: String, default: 'Coach Emma' },
    duration: { type: String, default: '30 min' },
    episodes: { type: String, default: '16 episodes' },
    level: { type: String, default: 'Intermediate' },
    rating: { type: String, default: '4.9' },
    imageUrl: { type: String, default: '' },
    videoUrl: { type: String, default: '' },
    category: { type: String, default: 'Body Wellness' },
    tags: [{ type: String }],
    sortOrder: { type: Number, default: 1 },
    isActive: { type: Boolean, default: true },
  },
  { timestamps: true }
);

module.exports = mongoose.model('WorkoutProgram', workoutProgramSchema);
