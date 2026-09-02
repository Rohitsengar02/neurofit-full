const User = require('../models/User');
const Address = require('../models/Address');
const redisService = require('../services/redisService');

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

// GET ALL USER ADDRESSES (from User.addresses array with Redis Acceleration)
exports.getUserAddresses = async (req, res) => {
  try {
    const { uid } = req.params;
    const cacheKey = `user:addresses:${uid}`;

    const cached = await redisService.get(cacheKey);
    if (cached) {
      return res.json({
        success: true,
        count: cached.length,
        data: cached,
        source: 'redis'
      });
    }

    let user = await User.findOne({ uid }).select('addresses');
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    // If User.addresses is empty, check legacy Address collection
    if (!user.addresses || user.addresses.length === 0) {
      const legacyAddress = await Address.findOne({ uid }).sort({ updatedAt: -1 }).lean();
      if (legacyAddress) {
        const migrated = {
          id: 'addr_legacy_1',
          tag: 'Home',
          name: legacyAddress.fullName,
          phone: legacyAddress.phoneNumber,
          flat: legacyAddress.streetAddress,
          building: '',
          area: '',
          city: legacyAddress.city,
          state: legacyAddress.state || 'State',
          pincode: legacyAddress.pincode,
          isDefault: true,
          createdAt: legacyAddress.createdAt || new Date()
        };
        user.addresses = [migrated];
        await user.save();
      }
    }

    const addrList = user.addresses || [];
    await redisService.set(cacheKey, addrList, 300);

    res.json({
      success: true,
      count: addrList.length,
      data: addrList,
      source: 'mongo'
    });
  } catch (err) {
    console.error('Error in getUserAddresses:', err.message);
    res.status(500).json({ success: false, message: err.message });
  }
};

// GET SINGLE / DEFAULT USER ADDRESS (Optimized with projection & Redis)
exports.getUserAddress = async (req, res) => {
  try {
    const { uid } = req.params;
    const cacheKey = `user:default_address:${uid}`;

    const cached = await redisService.get(cacheKey);
    if (cached) {
      return res.json({ success: true, data: cached, source: 'redis' });
    }

    const user = await User.findOne({ uid }).select('addresses').lean();
    if (user && user.addresses && user.addresses.length > 0) {
      const defaultAddr = user.addresses.find(a => a.isDefault) || user.addresses[0];
      await redisService.set(cacheKey, defaultAddr, 300);
      return res.json({ success: true, data: defaultAddr, source: 'mongo' });
    }

    const legacyAddress = await Address.findOne({ uid }).sort({ updatedAt: -1 }).lean();
    if (legacyAddress) {
      await redisService.set(cacheKey, legacyAddress, 300);
    }
    res.json({ success: true, data: legacyAddress, source: 'mongo' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// SAVE ADDRESS INTO USER'S PROFILE ADDRESSES ARRAY IN MONGODB
exports.saveUserAddress = async (req, res) => {
  try {
    const { uid } = req.params;
    const body = req.body;

    const addressId = body.id || 'addr_' + Date.now();
    const isDefault = body.isDefault !== undefined ? body.isDefault : true;

    const newAddress = {
      id: addressId,
      tag: body.tag || 'Home',
      name: body.name || body.fullName || 'Athlete',
      phone: body.phone || body.phoneNumber || '',
      flat: body.flat || body.streetAddress || '',
      building: body.building || '',
      area: body.area || '',
      city: body.city || '',
      state: body.state || 'State',
      pincode: body.pincode || '',
      latitude: body.latitude != null ? Number(body.latitude) : null,
      longitude: body.longitude != null ? Number(body.longitude) : null,
      isDefault: isDefault,
      createdAt: new Date()
    };

    let user = await User.findOne({ uid });
    if (!user) {
      user = new User({
        uid,
        name: newAddress.name,
        phone: newAddress.phone,
        addresses: []
      });
    }

    if (!user.addresses) {
      user.addresses = [];
    }

    // If new address is default or it's the only address, unset other defaults
    if (isDefault || user.addresses.length === 0) {
      user.addresses.forEach(a => { a.isDefault = false; });
      newAddress.isDefault = true;
    }

    // Check if updating an existing address by id
    const existingIndex = user.addresses.findIndex(a => a.id === addressId);
    if (existingIndex >= 0) {
      user.addresses[existingIndex] = { ...user.addresses[existingIndex].toObject(), ...newAddress };
    } else {
      user.addresses.unshift(newAddress);
    }

    user.updatedAt = new Date();
    await user.save();

    // Also update legacy Address collection for backward compatibility
    await Address.findOneAndUpdate(
      { uid },
      {
        uid,
        fullName: newAddress.name,
        phoneNumber: newAddress.phone,
        streetAddress: `${newAddress.flat} ${newAddress.building} ${newAddress.area}`.trim(),
        city: newAddress.city,
        state: newAddress.state,
        pincode: newAddress.pincode,
        isDefault: newAddress.isDefault,
        updatedAt: new Date()
      },
      { upsert: true, new: true }
    );

    // Invalidate Redis address cache
    await redisService.del(`user:addresses:${uid}`);
    await redisService.del(`user:default_address:${uid}`);

    if (req.io) {
      req.io.emit('user:address_updated', { uid, address: newAddress, addresses: user.addresses });
      req.io.to(`user_${uid}`).emit('user:address_self_updated', { address: newAddress, addresses: user.addresses });
    }

    console.log(`📍 Address saved with GPS [Lat: ${newAddress.latitude}, Lng: ${newAddress.longitude}] into User profile addresses array in MongoDB! User: ${uid}`);

    res.json({
      success: true,
      message: 'Address saved to user profile addresses array in MongoDB',
      data: newAddress,
      addresses: user.addresses
    });
  } catch (err) {
    console.error('Error in saveUserAddress:', err.message);
    res.status(500).json({ success: false, message: err.message });
  }
};

// DELETE AN ADDRESS FROM USER'S PROFILE
exports.deleteUserAddress = async (req, res) => {
  try {
    const { uid, addressId } = req.params;
    const user = await User.findOne({ uid });
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    user.addresses = (user.addresses || []).filter(a => a.id !== addressId);
    if (user.addresses.length > 0 && !user.addresses.some(a => a.isDefault)) {
      user.addresses[0].isDefault = true;
    }
    await user.save();
    await redisService.del(`user:addresses:${uid}`);
    await redisService.del(`user:default_address:${uid}`);

    res.json({
      success: true,
      message: 'Address removed from user profile in MongoDB',
      addresses: user.addresses
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// SET DEFAULT ADDRESS
exports.setDefaultAddress = async (req, res) => {
  try {
    const { uid, addressId } = req.params;
    const user = await User.findOne({ uid });
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    user.addresses.forEach(a => {
      a.isDefault = (a.id === addressId);
    });
    await user.save();
    await redisService.del(`user:addresses:${uid}`);
    await redisService.del(`user:default_address:${uid}`);

    res.json({
      success: true,
      message: 'Default address updated',
      addresses: user.addresses
    });
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

// UPDATE USER FCM TOKEN FOR REALTIME PUSH NOTIFICATIONS
exports.updateFcmToken = async (req, res) => {
  try {
    const { uid } = req.params;
    const { fcmToken } = req.body;

    if (!fcmToken) {
      return res.status(400).json({ success: false, message: 'fcmToken is required' });
    }

    const user = await User.findOneAndUpdate(
      { uid },
      {
        $set: { fcmToken },
        $addToSet: { fcmTokens: fcmToken },
        updatedAt: new Date()
      },
      { new: true, upsert: true }
    );

    console.log(`📲 FCM Token registered in MongoDB for user ${uid}: ${fcmToken.substring(0, 15)}...`);
    res.json({ success: true, message: 'FCM Token registered successfully', fcmToken });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};
