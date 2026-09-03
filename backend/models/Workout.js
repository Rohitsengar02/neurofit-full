const mongoose = require('mongoose');

const workoutExerciseSchema = new mongoose.Schema({
  exerciseId: { type: String },
  title: { type: String },
  categoryId: { type: String },
  muscleGroup: { type: String },
  mediaUrl: { type: String },
  mediaType: { type: String, default: 'image' },
  sets: { type: Number, default: 3 },
  reps: { type: Number, default: 12 },
  durationSeconds: { type: Number, default: 0 },
  restSeconds: { type: Number, default: 45 },
  instructions: { type: String, default: '' },
});

const workoutDaySchema = new mongoose.Schema({
  dayNumber: { type: Number, default: 1 },
  weekNumber: { type: Number, default: 1 },
  title: { type: String, default: '' },
  focus: { type: String, default: '' },
  durationMinutes: { type: Number, default: 30 },
  caloriesBurn: { type: Number, default: 250 },
  isRestDay: { type: Boolean, default: false },
  exercises: [workoutExerciseSchema],
});

const workoutSchema = new mongoose.Schema(
  {
    id: { type: String, required: true, unique: true, index: true },
    title: { type: String, required: true },
    subtitle: { type: String, default: '' },
    description: { type: String, default: '' },
    workoutCategoryId: { type: String, default: '' },
    category: { type: String, default: 'General' },
    exercises: [workoutExerciseSchema],
    days: [workoutDaySchema],
    durationMinutes: { type: Number, default: 30 },
    caloriesBurn: { type: Number, default: 250 },
    level: { type: String, enum: ['Beginner', 'Intermediate', 'Advanced', 'All Levels'], default: 'Intermediate' },
    coach: { type: String, default: 'Coach Alex' },
    imageUrl: { type: String, default: '' },
    videoUrl: { type: String, default: '' },
    gifUrl: { type: String, default: '' },
    exercisesCount: { type: Number, default: 6 },
    completionRate: { type: Number, default: 92.0 },
    rating: { type: Number, default: 4.9 },
    equipment: { type: String, default: 'None (Bodyweight)' },
    targetMuscle: { type: String, default: 'Full Body' },
    tags: [{ type: String }],
    isFeatured: { type: Boolean, default: false },
    isActive: { type: Boolean, default: true },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Workout', workoutSchema);
