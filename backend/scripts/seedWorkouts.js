const mongoose = require('mongoose');
const dotenv = require('dotenv');
const path = require('path');
const Workout = require('../models/Workout');

dotenv.config({ path: path.join(__dirname, '../.env') });

const sampleWorkouts = [
  {
    id: 'w_shred_21',
    title: '21-Day Shred & Tone Challenge',
    subtitle: 'High Intensity Fat Burning & Sculpting',
    description: 'Transform your body with 21 days of progressive HIIT cardio and full-body resistance training.',
    workoutCategoryId: 'wcat_fat_loss',
    category: 'Fat Loss HIIT',
    durationMinutes: 35,
    caloriesBurn: 480,
    level: 'Intermediate',
    coach: 'Coach Vikram',
    imageUrl: 'https://pub-2f9dfa009fb741278ffecf93798ef013.r2.dev/fitness_cms_1740994910000.jpg',
    mediaType: 'image',
    exercisesCount: 6,
    completionRate: 95.5,
    rating: 4.9,
    tags: ['Fat Loss', 'HIIT', 'Full Body', 'Challenging'],
    isFeatured: true,
    isActive: true,
    exercises: [
      { exerciseId: 'ex_incline_bench', title: 'Incline Dumbbell Press', sets: 4, reps: 12, restSeconds: 45 },
      { exerciseId: 'ex_pushups', title: 'Chest Flyes & Pushups', sets: 3, reps: 15, restSeconds: 30 },
      { exerciseId: 'ex_lat_pulldown', title: 'Wide Lat Pulldown', sets: 4, reps: 12, restSeconds: 45 },
    ]
  },
  {
    id: 'w_hypertrophy_chest',
    title: 'Chest & Triceps Hypertrophy',
    subtitle: 'Mass Building & Upper Body Sculpting',
    description: 'Target upper chest, lower chest, and triceps with progressive heavy overload movements.',
    workoutCategoryId: 'wcat_muscle_mass',
    category: 'Muscle Mass & Hypertrophy',
    durationMinutes: 45,
    caloriesBurn: 380,
    level: 'Advanced',
    coach: 'Coach Alex',
    imageUrl: 'https://pub-2f9dfa009fb741278ffecf93798ef013.r2.dev/banner_spotlight_video.mp4',
    mediaType: 'video',
    exercisesCount: 5,
    completionRate: 92.0,
    rating: 4.8,
    tags: ['Muscle Mass', 'Chest', 'Triceps', 'Heavy'],
    isFeatured: true,
    isActive: true,
    exercises: [
      { exerciseId: 'ex_incline_bench', title: 'Incline Dumbbell Press', sets: 4, reps: 10, restSeconds: 60 },
      { exerciseId: 'ex_pushups', title: 'Explosive Pushups', sets: 3, reps: 15, restSeconds: 45 },
    ]
  },
  {
    id: 'w_core_sixpack',
    title: 'Six Pack Abs & Core Shred',
    subtitle: 'Obliques, Upper & Lower Core Burn',
    description: 'Sculpt steel core stability and defined 6-pack abdominal muscles in under 20 minutes.',
    workoutCategoryId: 'wcat_core_shred',
    category: 'Six Pack Core Shred',
    durationMinutes: 20,
    caloriesBurn: 260,
    level: 'All Levels',
    coach: 'Coach Maya',
    imageUrl: 'https://pub-2f9dfa009fb741278ffecf93798ef013.r2.dev/fitness_cms_1740994910000.jpg',
    mediaType: 'image',
    exercisesCount: 4,
    completionRate: 98.0,
    rating: 5.0,
    tags: ['Core', 'Abs', 'Obliques', 'Quick Workout'],
    isFeatured: true,
    isActive: true,
    exercises: [
      { exerciseId: 'ex_hanging_leg_raise', title: 'Hanging Leg Raise', sets: 4, reps: 15, restSeconds: 30 },
      { exerciseId: 'ex_plank', title: 'Weighted Forearm Plank', sets: 3, reps: 1, durationSeconds: 60, restSeconds: 30 },
    ]
  }
];

async function seedWorkouts() {
  try {
    const mongoUri = process.env.MONGO_URI || process.env.MONGODB_URI;
    if (!mongoUri) {
      console.error('MONGODB_URI missing in .env file');
      process.exit(1);
    }

    await mongoose.connect(mongoUri);
    console.log('Connected to MongoDB for seeding Workouts...');

    for (const wData of sampleWorkouts) {
      await Workout.findOneAndUpdate({ id: wData.id }, wData, { upsert: true, new: true });
    }

    console.log('Successfully seeded sample Workouts in MongoDB Atlas!');
    process.exit(0);
  } catch (error) {
    console.error('Error seeding Workouts:', error);
    process.exit(1);
  }
}

seedWorkouts();
