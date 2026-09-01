const express = require('express');
const router = express.Router();
const layoutController = require('../controllers/layoutController');

router.get('/', layoutController.getAllLayoutSections);
router.post('/', layoutController.createOrUpdateLayoutSection);
router.put('/:id', layoutController.createOrUpdateLayoutSection);

module.exports = router;
