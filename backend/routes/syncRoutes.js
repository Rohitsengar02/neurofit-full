const express = require('express');
const router = express.Router();
const syncController = require('../controllers/syncController');

router.post('/firebase-to-mongo', syncController.triggerSync);

module.exports = router;
