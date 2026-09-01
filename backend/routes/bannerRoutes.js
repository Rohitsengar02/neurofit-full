const express = require('express');
const router = express.Router();
const bannerController = require('../controllers/bannerController');

router.get('/', bannerController.getAllBanners);
router.post('/', bannerController.createOrUpdateBanner);
router.put('/:id', bannerController.createOrUpdateBanner);

module.exports = router;
