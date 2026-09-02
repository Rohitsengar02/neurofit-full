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
    const privateKey = serviceAccount.private_key || serviceAccount.privateKey || '';
    if (!privateKey || privateKey.trim().length === 0) {
      console.warn('⚠️ Notice: FIREBASE_PRIVATE_KEY is missing in backend/.env or serviceAccountKey.json file.');
      console.warn('👉 To enable FCM Push dispatch from Admin SDK: Go to Firebase Console -> Project Settings -> Service Accounts -> Generate New Private Key, and paste into backend/.env as FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\\n..." or save as backend/config/serviceAccountKey.json');
    } else {
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
      });
      console.log('✅ Firebase Admin SDK successfully initialized for project: neurofit-63189');
    }
  } catch (err) {
    console.error('❌ Error initializing Firebase Admin SDK:', err.message);
  }
}

module.exports = admin;
