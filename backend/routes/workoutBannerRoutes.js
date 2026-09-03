const express = require('express');
const router = express.Router();
const {
  getWorkoutBanners,
  getActiveWorkoutBanners,
  createWorkoutBanner,
  updateWorkoutBanner,
  deleteWorkoutBanner,
  reorderWorkoutBanners,
} = require('../controllers/workoutBannerController');

router.get('/', getWorkoutBanners);
router.get('/active', getActiveWorkoutBanners);
router.post('/', createWorkoutBanner);
router.put('/:id', updateWorkoutBanner);
router.delete('/:id', deleteWorkoutBanner);
router.post('/reorder', reorderWorkoutBanners);

module.exports = router;
