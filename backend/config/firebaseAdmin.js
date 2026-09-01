const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');

let serviceAccount;
const keyPath = path.join(__dirname, 'serviceAccountKey.json');

if (fs.existsSync(keyPath)) {
  serviceAccount = require(keyPath);
} else {
  serviceAccount = {
    projectId: process.env.FIREBASE_PROJECT_ID,
    clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
    privateKey: (process.env.FIREBASE_PRIVATE_KEY || '').replace(/\\n/g, '\n'),
  };
}

if (!admin.apps.length) {
  try {
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
    console.log('✅ Firebase Admin SDK successfully initialized for project: neurofit-63189');
  } catch (err) {
    console.error('❌ Error initializing Firebase Admin SDK:', err.message);
  }
}

module.exports = admin;
