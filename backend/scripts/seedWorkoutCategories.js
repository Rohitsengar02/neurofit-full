require('dotenv').config();
const mongoose = require('mongoose');
const WorkoutCategory = require('../models/WorkoutCategory');

const MONGODB_URI = process.env.MONGO_URI || process.env.MONGODB_URI;

const defaultCategories = [
  {
    id: 'wcat_strength',
    name: 'Strength',
    description: 'Hypertrophy, powerlifting, barbell, dumbbell & resistance training',
    mediaType: 'image',
    mediaUrl: 'https://pub-2faf8f45ef6f42afba49f3944feacff6.r2.dev/uploads/workout_category_1.png',
    sortOrder: 1,
    isActive: true,
  },
  {
    id: 'wcat_hiit',
    name: 'HIIT & Circuit',
    description: 'High-intensity interval training, Tabata & calorie torching circuits',
    mediaType: 'image',
    mediaUrl: 'https://pub-2faf8f45ef6f42afba49f3944feacff6.r2.dev/uploads/workout_category_2.jpg',
    sortOrder: 2,
    isActive: true,
  },
  {
    id: 'wcat_yoga',
    name: 'Yoga & Flow',
    description: 'Vinyasa flow, restorative flexibility, mobility & mindful breathwork',
    mediaType: 'image',
    mediaUrl: 'https://pub-2faf8f45ef6f42afba49f3944feacff6.r2.dev/uploads/workout_category_3.png',
    sortOrder: 3,
    isActive: true,
  },
  {
    id: 'wcat_core',
    name: 'Core & Abs',
    description: 'Midsection definition, rotational strength & deep core stabilization',
    mediaType: 'image',
    mediaUrl: 'https://pub-2faf8f45ef6f42afba49f3944feacff6.r2.dev/uploads/workout_category_4.png',
    sortOrder: 4,
    isActive: true,
  },
  {
    id: 'wcat_cardio',
    name: 'Cardio Blast',
    description: 'Endurance building, sprint conditioning, steady-state cardio & agility',
    mediaType: 'image',
    mediaUrl: 'https://pub-2faf8f45ef6f42afba49f3944feacff6.r2.dev/uploads/workout_category_5.png',
    sortOrder: 5,
    isActive: true,
  },
];

async function seed() {
  try {
    await mongoose.connect(MONGODB_URI);
    console.log('✅ Connected to MongoDB Atlas');

    for (const cat of defaultCategories) {
      await WorkoutCategory.findOneAndUpdate(
        { id: cat.id },
        { $set: cat },
        { upsert: true, new: true }
      );
    }

    const count = await WorkoutCategory.countDocuments();
    console.log(`✅ Successfully seeded ${count} workout categories into MongoDB Atlas.`);

    process.exit(0);
  } catch (err) {
    console.error('❌ Seeding Error:', err);
    process.exit(1);
  }
}

seed();
