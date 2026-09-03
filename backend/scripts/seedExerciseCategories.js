const mongoose = require('mongoose');
require('dotenv').config();
const ExerciseCategory = require('../models/ExerciseCategory');

const MONGO_URI = process.env.MONGO_URI || process.env.MONGODB_URI || 'mongodb://localhost:27017/neurofit';

const initialCategories = [
  {
    categoryId: 'excat_chest',
    name: 'Chest & Pectorals',
    slug: 'chest-pectorals',
    description: 'Upper, lower, and inner chest muscle isolation and compound movements',
    imageUrl: '1788015825487_scaled_1000013160.jpg',
    mediaType: 'video',
    sortOrder: 1,
    isActive: true,
  },
  {
    categoryId: 'excat_back',
    name: 'Back & Lats',
    slug: 'back-lats',
    description: 'Lat pulldowns, rows, deadlifts, and upper back thickness',
    imageUrl: 'workout_banner_2.png',
    mediaType: 'image',
    sortOrder: 2,
    isActive: true,
  },
  {
    categoryId: 'excat_legs',
    name: 'Legs & Lower Body',
    slug: 'legs-lower-body',
    description: 'Squats, lunges, leg press, hamstrings, and calf isolation',
    imageUrl: 'workout_banner_3.png',
    mediaType: 'gif',
    sortOrder: 3,
    isActive: true,
  },
  {
    categoryId: 'excat_shoulders',
    name: 'Shoulders & Delts',
    slug: 'shoulders-delts',
    description: 'Overhead presses, lateral raises, and rear delt flyes',
    imageUrl: 'workout_banner_4.png',
    mediaType: 'image',
    sortOrder: 4,
    isActive: true,
  },
  {
    categoryId: 'excat_arms',
    name: 'Arms & Biceps/Triceps',
    slug: 'arms-biceps-triceps',
    description: 'Bicep curls, hammer curls, tricep extensions, and dips',
    imageUrl: 'workout_banner_1.png',
    mediaType: 'image',
    sortOrder: 5,
    isActive: true,
  },
  {
    categoryId: 'excat_core',
    name: 'Core & Abs Shred',
    slug: 'core-abs-shred',
    description: 'Planks, leg raises, cable crunches, and rotational core stability',
    imageUrl: '1788015825487_scaled_1000013160.jpg',
    mediaType: 'video',
    sortOrder: 6,
    isActive: true,
  },
];

async function seedExerciseCategories() {
  try {
    await mongoose.connect(MONGO_URI);
    console.log('Connected to MongoDB for seeding Exercise Categories...');

    for (const cat of initialCategories) {
      await ExerciseCategory.findOneAndUpdate({ categoryId: cat.categoryId }, cat, { upsert: true, new: true });
    }

    console.log('Successfully seeded Exercise Categories in exercise_categories collection!');
    process.exit(0);
  } catch (err) {
    console.error('Error seeding exercise categories:', err);
    process.exit(1);
  }
}

seedExerciseCategories();
