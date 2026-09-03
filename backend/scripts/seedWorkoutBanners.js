const mongoose = require('mongoose');
require('dotenv').config();
const WorkoutBanner = require('../models/WorkoutBanner');

const MONGO_URI = process.env.MONGO_URI || process.env.MONGODB_URI || 'mongodb://localhost:27017/neurofit';

const initialBanners = [
  {
    bannerId: 'wban_video_1',
    title: 'Hypertrophy Upper Body Blitz',
    subtitle: '45 Mins • Advanced Level • Chest & Back Shred',
    imageUrl: '1788015825487_scaled_1000013160.jpg',
    mediaType: 'video',
    targetType: 'workout',
    targetId: 'work_chest_incline',
    targetName: 'Incline Dumbbell Hyper-Chest Routine',
    badge: '🔥 POPULAR WORKOUT',
    buttonText: 'Start Workout',
    showTitle: true,
    sortOrder: 1,
    isActive: true,
  },
  {
    bannerId: 'wban_image_2',
    title: 'Conventional Deadlift Mastery',
    subtitle: 'Biomechanics & Posterior Chain Strength',
    imageUrl: 'workout_banner_2.png',
    mediaType: 'image',
    targetType: 'category',
    targetId: 'cat_strength_power',
    targetName: 'Strength & Olympic Powerlifting',
    badge: '👑 SPOTLIGHT',
    buttonText: 'View Technique',
    showTitle: true,
    sortOrder: 2,
    isActive: true,
  },
  {
    bannerId: 'wban_gif_3',
    title: 'HIIT Cardio Shred & Mobility',
    subtitle: '30-Day Lean Shred Masterclass',
    imageUrl: 'workout_banner_3.png',
    mediaType: 'gif',
    targetType: 'program',
    targetId: 'prog_30day_shred',
    targetName: '30-Day Lean Shred Masterclass',
    badge: '⚡ NEW PROGRAM',
    buttonText: 'Join Challenge',
    showTitle: true,
    sortOrder: 3,
    isActive: true,
  },
];

async function seedWorkoutBanners() {
  try {
    await mongoose.connect(MONGO_URI);
    console.log('Connected to MongoDB for seeding Workout Banners...');

    for (const b of initialBanners) {
      await WorkoutBanner.findOneAndUpdate({ bannerId: b.bannerId }, b, { upsert: true, new: true });
    }

    console.log('Successfully seeded Workout Banners in workout_banners collection!');
    process.exit(0);
  } catch (err) {
    console.error('Error seeding workout banners:', err);
    process.exit(1);
  }
}

seedWorkoutBanners();
