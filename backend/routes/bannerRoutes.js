const express = require('express');
const router = express.Router();
const bannerController = require('../controllers/bannerController');

// Banner CRUD REST Routes
router.get('/', bannerController.getAllBanners);
router.get('/:id', bannerController.getBannerById);
router.post('/', bannerController.createBanner);
router.put('/:id', bannerController.updateBanner);
router.patch('/:id/status', bannerController.toggleBannerStatus);
router.post('/reorder', bannerController.reorderBanners);
router.delete('/:id', bannerController.deleteBanner);

module.exports = router;
