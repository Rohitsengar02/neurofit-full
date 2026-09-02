const express = require('express');
const router = express.Router();
const mediaController = require('../controllers/mediaController');

router.get('/', mediaController.getR2MediaImages);
router.post('/upload', mediaController.uploadMediaImage);
router.get('/proxy', mediaController.proxyMediaImage);
router.get('/file/:filename', mediaController.serveMediaFile);

module.exports = router;
