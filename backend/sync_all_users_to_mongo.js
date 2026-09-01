const mongoose = require('mongoose');
const dotenv = require('dotenv');
const admin = require('./config/firebaseAdmin');
const User = require('./models/User');

dotenv.config();

const mongoUri = process.env.MONGO_URI || 'mongodb+srv://rohitsengar02_db_user:HtQBKwZ4zHyDnSKS@neurofitapp.pfpotec.mongodb.net/neurofit?retryWrites=true&w=majority';

async function syncAllUsers() {
  try {
    console.log('Connecting to MongoDB Atlas...');
    await mongoose.connect(mongoUri, { serverSelectionTimeoutMS: 20000 });
    console.log('✅ Connected to MongoDB Atlas');

    console.log('Fetching users from Firebase Authentication...');
    const listUsersResult = await admin.auth().listUsers(1000);
    console.log(`Found ${listUsersResult.users.length} user(s) in Firebase Auth.`);

    if (listUsersResult.users.length === 0) {
      console.log('No users found in Firebase Auth yet. Creating a verified sample athlete document...');
      const sampleUser = await User.findOneAndUpdate(
        { uid: 'sample_athlete_01' },
        {
          uid: 'sample_athlete_01',
          name: 'Rohit Sengar',
          email: 'rohitsengar02@gmail.com',
          photoUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb',
          authProvider: 'google',
          hasCompletedOnboarding: true,
          questionnaireData: {
            fitnessGoal: 'Muscle Building & Hypertrophy',
            experienceLevel: 'Advanced',
            workoutFrequency: '5-6 Days/Week',
            dietaryPreference: 'High Protein Non-Veg',
            targetWeight: '78 kg',
            height: '180 cm',
            age: '24',
            gender: 'Male'
          },
          updatedAt: new Date()
        },
        { upsert: true, new: true }
      );
      console.log(`✅ Seeded sample user: ${sampleUser.name} (${sampleUser.email})`);
    } else {
      for (const fbUser of listUsersResult.users) {
        const userData = {
          uid: fbUser.uid,
          name: fbUser.displayName || 'Athlete',
          email: fbUser.email || '',
          phone: fbUser.phoneNumber || '',
          photoUrl: fbUser.photoURL || '',
          authProvider: fbUser.providerData.length > 0 ? fbUser.providerData[0].providerId : 'google',
          hasCompletedOnboarding: false,
          updatedAt: new Date()
        };

        const savedUser = await User.findOneAndUpdate(
          { uid: fbUser.uid },
          { $setOnInsert: { createdAt: new Date() }, ...userData },
          { upsert: true, new: true }
        );
        console.log(`✅ Synced to MongoDB Atlas users collection: ${savedUser.name} (${savedUser.email}) [UID: ${savedUser.uid}]`);
      }
    }

    const totalInMongo = await User.countDocuments();
    console.log(`🎉 Total Users in MongoDB Atlas users collection: ${totalInMongo}`);
    process.exit(0);
  } catch (err) {
    console.error('❌ Error syncing users:', err.message);
    process.exit(1);
  }
}

syncAllUsers();
