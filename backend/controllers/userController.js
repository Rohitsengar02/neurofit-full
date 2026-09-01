const User = require('../models/User');
const Address = require('../models/Address');

// GET ALL USERS
exports.getAllUsers = async (req, res) => {
  try {
    const users = await User.find().sort({ createdAt: -1 });
    console.log(`👥 Retrieved ${users.length} users from MongoDB Atlas`);
    res.json({ success: true, count: users.length, data: users });
  } catch (err) {
    console.error('Error in getAllUsers:', err.message);
    res.status(500).json({ success: false, message: err.message });
  }
};

// GET OR CREATE/UPDATE USER PROFILE
exports.getOrUpdateUser = async (req, res) => {
  try {
    const uid = req.params.uid || req.body.uid;
    if (!uid) {
      return res.status(400).json({ success: false, message: 'UID is required' });
    }

    if (req.method === 'GET') {
      let user = await User.findOne({ uid });
      if (!user) {
        return res.status(404).json({ success: false, message: 'User not found in MongoDB' });
      }
      return res.json({ success: true, data: user });
    } else {
      const userData = req.body;
      const user = await User.findOneAndUpdate(
        { uid },
        { ...userData, uid, updatedAt: new Date() },
        { new: true, upsert: true }
      );

      if (req.io) {
        req.io.emit('user:updated', user);
        req.io.to(`user_${uid}`).emit('user:self_updated', user);
      }

      console.log(`✅ User saved in MongoDB Atlas users collection -> UID: ${uid}, Name: ${user.name}, Email: ${user.email}`);
      return res.json({ success: true, message: 'User saved to MongoDB Atlas', data: user });
    }
  } catch (err) {
    console.error('Error in getOrUpdateUser:', err.message);
    res.status(500).json({ success: false, message: err.message });
  }
};

// CREATE USER (POST /api/users)
exports.createUser = async (req, res) => {
  try {
    const { uid } = req.body;
    if (!uid) {
      return res.status(400).json({ success: false, message: 'UID is required' });
    }

    const user = await User.findOneAndUpdate(
      { uid },
      { ...req.body, uid, updatedAt: new Date() },
      { new: true, upsert: true }
    );

    if (req.io) {
      req.io.emit('user:updated', user);
      req.io.to(`user_${uid}`).emit('user:self_updated', user);
    }

    console.log(`✅ User ${uid} (${user.email}) successfully created/upserted in MongoDB Atlas!`);
    res.status(201).json({ success: true, data: user });
  } catch (err) {
    console.error('Error in createUser:', err.message);
    res.status(500).json({ success: false, message: err.message });
  }
};

// SAVE QUESTIONNAIRE & PLAN DATA IN MONGO USERS COLLECTION
exports.saveQuestionnaire = async (req, res) => {
  try {
    const { uid } = req.params;
    const questionnaireData = req.body;

    const user = await User.findOneAndUpdate(
      { uid },
      { 
        questionnaireData,
        hasCompletedOnboarding: true,
        updatedAt: new Date()
      },
      { new: true, upsert: true }
    );

    if (req.io) {
      req.io.emit('user:questionnaire_saved', { uid, questionnaireData });
      req.io.to(`user_${uid}`).emit('user:self_updated', user);
    }

    console.log(`✅ Questionnaire answers & AI Plan saved in MongoDB Atlas users collection for user: ${uid}!`);
    res.json({
      success: true,
      message: 'Questionnaire data saved to MongoDB users collection!',
      data: user
    });
  } catch (err) {
    console.error('Error in saveQuestionnaire:', err.message);
    res.status(500).json({ success: false, message: err.message });
  }
};

// GET USER ADDRESS
exports.getUserAddress = async (req, res) => {
  try {
    const address = await Address.findOne({ uid: req.params.uid }).sort({ updatedAt: -1 });
    res.json({ success: true, data: address });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// SAVE USER ADDRESS
exports.saveUserAddress = async (req, res) => {
  try {
    const { uid } = req.params;
    const address = await Address.findOneAndUpdate(
      { uid },
      { ...req.body, uid, updatedAt: new Date() },
      { new: true, upsert: true }
    );
    if (req.io) {
      req.io.emit('user:address_updated', { uid, address });
      req.io.to(`user_${uid}`).emit('user:address_self_updated', address);
    }
    console.log(`✅ User address saved in MongoDB addresses collection for user: ${uid}!`);
    res.json({ success: true, data: address });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// DELETE USER
exports.deleteUser = async (req, res) => {
  try {
    const { uid } = req.params;
    await User.findOneAndDelete({ uid });
    await Address.deleteMany({ uid });
    console.log(`🗑️ User ${uid} deleted from MongoDB Atlas`);
    res.json({ success: true, message: `User ${uid} deleted from MongoDB` });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};
