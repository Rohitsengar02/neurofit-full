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

// GET / POST user shipping address
router.get('/:uid/address', userController.getUserAddress);
router.post('/:uid/address', userController.saveUserAddress);

// DELETE user
router.delete('/:uid', userController.deleteUser);

module.exports = router;
