const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');

// GET all users & POST new user
router.get('/', userController.getAllUsers);
router.post('/', userController.createUser);

// GET / POST single user profile
router.get('/:uid', userController.getOrUpdateUser);
router.post('/:uid', userController.getOrUpdateUser);
router.put('/:uid', userController.getOrUpdateUser);

// POST questionnaire answers
router.post('/:uid/questionnaire', userController.saveQuestionnaire);

// Address Routes (User.addresses array in MongoDB)
router.get('/:uid/addresses', userController.getUserAddresses);
router.post('/:uid/addresses', userController.saveUserAddress);
router.delete('/:uid/addresses/:addressId', userController.deleteUserAddress);
router.put('/:uid/addresses/:addressId/default', userController.setDefaultAddress);

// Backward-compatible single address routes
router.get('/:uid/address', userController.getUserAddress);
router.post('/:uid/address', userController.saveUserAddress);

// FCM Push Notification Token registration
router.post('/:uid/fcm-token', userController.updateFcmToken);

// DELETE user
router.delete('/:uid', userController.deleteUser);

module.exports = router;
