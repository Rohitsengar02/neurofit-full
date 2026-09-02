const express = require('express');
const router = express.Router();
const layoutController = require('../controllers/layoutController');

// Home Layout CMS REST Endpoints
router.get('/', layoutController.getAllLayoutSections);
router.get('/:id', layoutController.getLayoutSectionById);
router.post('/', layoutController.createLayoutSection);
router.put('/:id', layoutController.updateLayoutSection);
router.patch('/:id/status', layoutController.toggleLayoutSectionStatus);
router.post('/reorder', layoutController.reorderLayoutSections);
router.delete('/:id', layoutController.deleteLayoutSection);

module.exports = router;
