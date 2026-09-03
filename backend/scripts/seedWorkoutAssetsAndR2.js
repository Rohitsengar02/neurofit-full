const fs = require('fs');
const path = require('path');
const axios = require('axios');
const mongoose = require('mongoose');
const dotenv = require('dotenv');
dotenv.config();

const WorkoutLayoutSection = require('../models/WorkoutLayoutSection');
const Workout = require('../models/Workout');
const WorkoutProgram = require('../models/WorkoutProgram');
const Exercise = require('../models/Exercise');

const uploadsDir = path.join(__dirname, '../public/uploads');
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
}

const assetsDir = path.join(__dirname, '../../Neurofit-app/assets/images');

const workoutAssetFiles = [
  'workout_banner_1.png',
  'workout_banner_2.png',
  'workout_banner_3.png',
  'workout_banner_4.png',
  'workout_category_1.png',
  'workout_category_2.jpg',
  'workout_category_3.png',
  'workout_category_4.png',
  'workout_category_5.png',
  'spotlight_1.png',
  'spotlight_2.png',
  'spotlight_3.png',
  'workout_exercise_cutout.jpg',
  'top tabs/workout.png',
];

const publicDevUrl = process.env.CLOUDFLARE_R2_PUBLIC_DEV_URL || 'https://pub-2faf8f45ef6f42afba49f3944feacff6.r2.dev';
const accountId = process.env.CLOUDFLARE_R2_ACCOUNT_ID || '61519b8c6a1a20d3535eb39e85687539';
const bucketName = process.env.CLOUDFLARE_R2_BUCKET_NAME || 'neurofit';
const token = process.env.CLOUDFLARE_R2_API_TOKEN || 'cfat_CUzcTemF5447Ag5mi2gIrcDGYyrMrHSrO9PY6q5Sc69f5185';

async function uploadToR2(fileName, buffer, mimeType) {
  try {
    const cleanFileName = fileName.replace(/[^a-zA-Z0-9._-]/g, '_');
    const r2Uri = `https://api.cloudflare.com/client/v4/accounts/${accountId}/r2/buckets/${bucketName}/objects/uploads/${cleanFileName}`;
    await axios.put(r2Uri, buffer, {
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': mimeType,
      },
      maxContentLength: 50 * 1024 * 1024,
      maxBodyLength: 50 * 1024 * 1024,
      timeout: 15000,
    });
    console.log(`☁️  Uploaded to Cloudflare R2: uploads/${cleanFileName}`);
  } catch (err) {
    console.warn(`⚠️ R2 upload warning for ${fileName}: ${err.message}`);
  }
}

async function run() {
  console.log('🚀 [SEED] Starting Workout Assets & R2 Seeding...');

  // 1. Copy local assets to Express public/uploads and upload to Cloudflare R2
  for (const relPath of workoutAssetFiles) {
    const srcPath = path.join(assetsDir, relPath);
    const destFileName = path.basename(relPath);
    const destPath = path.join(uploadsDir, destFileName);

    if (fs.existsSync(srcPath)) {
      const buffer = fs.readFileSync(srcPath);
      fs.writeFileSync(destPath, buffer);
      console.log(`📁 Cached locally: public/uploads/${destFileName}`);

      const ext = path.extname(destFileName).toLowerCase();
      const mime = ext === '.png' ? 'image/png' : ext === '.jpg' || ext === '.jpeg' ? 'image/jpeg' : 'application/octet-stream';
      await uploadToR2(destFileName, buffer, mime);
    } else {
      console.log(`ℹ️  Source not found: ${srcPath}`);
    }
  }

  // 2. Connect to MongoDB Atlas
  await mongoose.connect(process.env.MONGO_URI);
  console.log('✅ Connected to MongoDB Atlas');

  // 3. Seed Default Workout Layout Sections
  const defaultSections = [
    {
      id: 'sec_workout_hero_banners',
      sectionId: 'sec_workout_hero_banners',
      title: 'Featured Programs & Challenges',
      subtitle: 'Top hand-picked workout challenges',
      showTitle: false,
      showHeading: false,
      type: 'hero_banners',
      layoutMode: 'hero_carousel',
      filterSource: 'all',
      sortOrder: 1,
      displayOrder: 1,
      isActive: true,
      customBannerImageUrl: `${publicDevUrl}/uploads/workout_banner_1.png`,
    },
    {
      id: 'sec_workout_categories',
      sectionId: 'sec_workout_categories',
      title: 'Categories',
      subtitle: 'Browse by training discipline',
      showTitle: true,
      showHeading: true,
      type: 'categories',
      layoutMode: 'square_cards',
      filterSource: 'all',
      sortOrder: 2,
      displayOrder: 2,
      isActive: true,
    },
    {
      id: 'sec_workout_popular_programs',
      sectionId: 'sec_workout_popular_programs',
      title: 'Popular Programs',
      subtitle: 'Most completed multi-week training plans',
      showTitle: true,
      showHeading: true,
      type: 'popular_programs',
      layoutMode: 'carousel',
      filterSource: 'featured',
      sortOrder: 3,
      displayOrder: 3,
      isActive: true,
    },
    {
      id: 'sec_workout_bento_spotlight',
      sectionId: 'sec_workout_bento_spotlight',
      title: 'Workout Spotlight',
      subtitle: 'Curated splits for today',
      showTitle: true,
      showHeading: true,
      type: 'bento_spotlight',
      layoutMode: 'bento',
      filterSource: 'all',
      sortOrder: 4,
      displayOrder: 4,
      isActive: true,
      customBannerImageUrl: `${publicDevUrl}/uploads/spotlight_1.png`,
    },
    {
      id: 'sec_workout_muscle_groups',
      sectionId: 'sec_workout_muscle_groups',
      title: 'Target Muscle Groups',
      subtitle: 'Focus your routine on specific areas',
      showTitle: true,
      showHeading: true,
      type: 'muscle_groups',
      layoutMode: 'carousel',
      filterSource: 'all',
      sortOrder: 5,
      displayOrder: 5,
      isActive: true,
    },
    {
      id: 'sec_workout_celebrity_coaches',
      sectionId: 'sec_workout_celebrity_coaches',
      title: 'Elite Coaches',
      subtitle: 'Learn form & intensity from the world-class pros',
      showTitle: true,
      showHeading: true,
      type: 'celebrity_coaches',
      layoutMode: 'carousel',
      filterSource: 'all',
      sortOrder: 6,
      displayOrder: 6,
      isActive: true,
    },
    {
      id: 'sec_workout_equipment_training',
      sectionId: 'sec_workout_equipment_training',
      title: 'Workout by Equipment',
      subtitle: 'Tailored routines for your available gym gear',
      showTitle: true,
      showHeading: true,
      type: 'equipment_training',
      layoutMode: 'carousel',
      filterSource: 'all',
      sortOrder: 7,
      displayOrder: 7,
      isActive: true,
    },
    {
      id: 'sec_workout_trending_challenges',
      sectionId: 'sec_workout_trending_challenges',
      title: 'Trending Challenges',
      subtitle: 'Community-driven fitness transformations',
      showTitle: true,
      showHeading: true,
      type: 'trending_challenges',
      layoutMode: 'carousel',
      filterSource: 'all',
      sortOrder: 8,
      displayOrder: 8,
      isActive: true,
    },
    {
      id: 'sec_workout_audio_beats',
      sectionId: 'sec_workout_audio_beats',
      title: 'Music-Synced Workouts',
      subtitle: 'Cardio & strength synced to exact BPM tracks',
      showTitle: true,
      showHeading: true,
      type: 'audio_beats',
      layoutMode: 'carousel',
      filterSource: 'all',
      sortOrder: 9,
      displayOrder: 9,
      isActive: true,
    },
  ];

  for (const s of defaultSections) {
    await WorkoutLayoutSection.findOneAndUpdate(
      { $or: [{ id: s.id }, { sectionId: s.id }] },
      { $set: s },
      { upsert: true, new: true }
    );
  }
  console.log(`✅ Seeded ${defaultSections.length} Workout Layout Sections`);

  // 4. Seed Default Workout Programs
  const defaultPrograms = [
    {
      id: 'prog_body_wellness',
      title: 'Body Wellness & Core',
      subtitle: 'Full body toning & condition',
      duration: '35 min',
      episodes: '18 episodes',
      level: 'Intermediate',
      rating: '4.9',
      coach: 'Coach Emma',
      imageUrl: 'https://images.unsplash.com/photo-1574680096145-d05b474e2155?q=80&w=600&auto=format&fit=crop',
      category: 'Body Wellness',
      tags: ['Core', 'Full Body', 'Toning'],
      sortOrder: 1,
      isActive: true,
    },
    {
      id: 'prog_muscle_hypertrophy',
      title: 'Lean Muscle Hypertrophy',
      subtitle: 'Dumbbell & compound mastery',
      duration: '45 min',
      episodes: '24 episodes',
      level: 'Advanced',
      rating: '5.0',
      coach: 'Coach David',
      imageUrl: 'https://images.unsplash.com/photo-1583454110551-21f2fa2afe61?q=80&w=600&auto=format&fit=crop',
      category: 'Strength',
      tags: ['Hypertrophy', 'Dumbbells', 'Strength'],
      sortOrder: 2,
      isActive: true,
    },
    {
      id: 'prog_morning_vinyasa',
      title: 'Morning Sun Vinyasa',
      subtitle: 'Flexibility & spine alignment',
      duration: '25 min',
      episodes: '14 episodes',
      level: 'All Levels',
      rating: '4.8',
      coach: 'Coach Maya',
      imageUrl: 'https://images.unsplash.com/photo-1506126613408-eca07ce68773?q=80&w=600&auto=format&fit=crop',
      category: 'Yoga',
      tags: ['Yoga', 'Flexibility', 'Morning'],
      sortOrder: 3,
      isActive: true,
    },
    {
      id: 'prog_hiit_metabolic',
      title: 'HIIT Metabolic Burn',
      subtitle: 'Explosive cardio & endurance',
      duration: '30 min',
      episodes: '16 episodes',
      level: 'Intermediate',
      rating: '4.9',
      coach: 'Coach Alex',
      imageUrl: 'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?q=80&w=600&auto=format&fit=crop',
      category: 'HIIT',
      tags: ['HIIT', 'Cardio', 'Fat Burn'],
      sortOrder: 4,
      isActive: true,
    },
  ];

  for (const p of defaultPrograms) {
    await WorkoutProgram.findOneAndUpdate({ id: p.id }, { $set: p }, { upsert: true, new: true });
  }
  console.log(`✅ Seeded ${defaultPrograms.length} Workout Programs`);

  // 5. Seed Default Workouts
  const defaultWorkouts = [
    {
      id: 'workout_chest_shred',
      title: 'Explosive Chest & Tricep Blast',
      subtitle: 'High-intensity compound push day',
      category: 'Chest & Triceps',
      durationMinutes: 40,
      caloriesBurn: 380,
      level: 'Advanced',
      coach: 'Coach Marcus Vance',
      imageUrl: `${publicDevUrl}/uploads/workout_category_1.png`,
      exercisesCount: 8,
      rating: 4.9,
      equipment: 'Dumbbells & Bench',
      targetMuscle: 'Chest, Triceps, Anterior Deltoid',
      tags: ['Chest', 'Push Day', 'Upper Body'],
      isFeatured: true,
      isActive: true,
    },
    {
      id: 'workout_leg_hypertrophy',
      title: 'Quads & Hamstrings Annihilation',
      subtitle: 'Volume-based lower body builder',
      category: 'Legs & Glutes',
      durationMinutes: 45,
      caloriesBurn: 440,
      level: 'Intermediate',
      coach: 'Coach Elena Rostova',
      imageUrl: `${publicDevUrl}/uploads/workout_category_2.jpg`,
      exercisesCount: 7,
      rating: 5.0,
      equipment: 'Dumbbells & Bodyweight',
      targetMuscle: 'Quads, Glutes, Calves',
      tags: ['Leg Day', 'Lower Body', 'Squats'],
      isFeatured: true,
      isActive: true,
    },
    {
      id: 'workout_sixpack_core',
      title: 'Six Pack Abs & Core Sculpt',
      subtitle: 'Targeted rotational & static core strength',
      category: 'Six Pack Abs',
      durationMinutes: 20,
      caloriesBurn: 210,
      level: 'All Levels',
      coach: 'Coach Sarah Jenkins',
      imageUrl: `${publicDevUrl}/uploads/workout_category_3.png`,
      exercisesCount: 6,
      rating: 4.8,
      equipment: 'Mat Only',
      targetMuscle: 'Rectus Abdominis, Obliques',
      tags: ['Abs', 'Core', 'Quick'],
      isFeatured: true,
      isActive: true,
    },
  ];

  for (const w of defaultWorkouts) {
    await Workout.findOneAndUpdate({ id: w.id }, { $set: w }, { upsert: true, new: true });
  }
  console.log(`✅ Seeded ${defaultWorkouts.length} Workouts`);

  // 6. Seed Default Exercises with GIF/Video placeholders
  const defaultExercises = [
    {
      id: 'ex_incline_dumbbell_press',
      title: 'Incline Dumbbell Press',
      category: 'Chest',
      muscleGroup: 'Upper Chest',
      equipment: 'Dumbbells & Incline Bench',
      difficulty: 'Intermediate',
      sets: 4,
      reps: '10-12 reps',
      imageUrl: `${publicDevUrl}/uploads/workout_category_1.png`,
      gifUrl: `${publicDevUrl}/uploads/workout_category_1.png`,
      instructions: [
        'Set bench to a 30 to 45 degree angle.',
        'Press dumbbells upward with control, squeezing the upper chest.',
        'Lower slowly for 3 seconds to feel a deep chest stretch.',
      ],
      tips: 'Keep wrists stacked directly over elbows to protect the joints.',
      isActive: true,
    },
    {
      id: 'ex_goblet_squat',
      title: 'Heavy Kettlebell Goblet Squat',
      category: 'Legs',
      muscleGroup: 'Quadriceps & Glutes',
      equipment: 'Kettlebell or Dumbbell',
      difficulty: 'Beginner',
      sets: 4,
      reps: '12-15 reps',
      imageUrl: `${publicDevUrl}/uploads/workout_category_2.jpg`,
      gifUrl: `${publicDevUrl}/uploads/workout_category_2.jpg`,
      instructions: [
        'Hold kettlebell at chest height with elbows tucked in.',
        'Descend into a deep squat below parallel.',
        'Drive through midfoot and heels to return to standing.',
      ],
      tips: 'Do not let knees cave inwards during the ascent.',
      isActive: true,
    },
    {
      id: 'ex_plank_shoulder_taps',
      title: 'Dynamic Plank Shoulder Taps',
      category: 'Abs',
      muscleGroup: 'Core Stability',
      equipment: 'Bodyweight',
      difficulty: 'Intermediate',
      sets: 3,
      reps: '20 total taps',
      imageUrl: `${publicDevUrl}/uploads/workout_category_3.png`,
      gifUrl: `${publicDevUrl}/uploads/workout_category_3.png`,
      instructions: [
        'Set up in a tall push-up plank position with feet slightly wider than hips.',
        'Without rocking your hips, tap opposite shoulder with one hand.',
        'Alternate sides in a controlled rhythm.',
      ],
      tips: 'Imagine balancing a glass of water on your lower back.',
      isActive: true,
    },
  ];

  for (const ex of defaultExercises) {
    await Exercise.findOneAndUpdate({ id: ex.id }, { $set: ex }, { upsert: true, new: true });
  }
  console.log(`✅ Seeded ${defaultExercises.length} Exercises`);

  await mongoose.disconnect();
  console.log('🎉 [SEED COMPLETE] All workout images, R2 objects, layout sections & data ready!');
}

run().catch((err) => {
  console.error('❌ Seeding error:', err);
  process.exit(1);
});
