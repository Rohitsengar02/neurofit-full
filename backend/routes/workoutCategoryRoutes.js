const express = require('express');
const router = express.Router();
const workoutCategoryController = require('../controllers/workoutCategoryController');

router.get('/', workoutCategoryController.getAllWorkoutCategories);
router.get('/:id', workoutCategoryController.getWorkoutCategoryById);
router.post('/', workoutCategoryController.createWorkoutCategory);
router.put('/:id', workoutCategoryController.updateWorkoutCategory);
router.patch('/:id/status', workoutCategoryController.toggleWorkoutCategoryStatus);
router.post('/reorder', workoutCategoryController.reorderWorkoutCategories);
router.delete('/:id', workoutCategoryController.deleteWorkoutCategory);

module.exports = router;
