const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  uid: { type: String, required: true, unique: true, index: true },
  name: { type: String, default: 'Athlete' },
  email: { type: String, default: '' },
  phone: { type: String, default: '' },
  photoUrl: { type: String, default: '' },
  authProvider: { type: String, default: 'google' },
  hasCompletedOnboarding: { type: Boolean, default: false },
  questionnaireData: {
    fitnessGoal: { type: String, default: '' },
    experienceLevel: { type: String, default: '' },
    workoutFrequency: { type: String, default: '' },
    dietaryPreference: { type: String, default: '' },
    targetWeight: { type: String, default: '' },
    height: { type: String, default: '' },
    age: { type: String, default: '' },
    gender: { type: String, default: '' },
    focusAreas: [{ type: String }],
    medicalConditions: { type: String, default: '' },
    completedAt: { type: Date, default: Date.now }
  }
}, { timestamps: true });

module.exports = mongoose.model('User', userSchema);
