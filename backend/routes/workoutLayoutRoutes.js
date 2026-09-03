const express = require('express');
const router = express.Router();
const workoutLayoutController = require('../controllers/workoutLayoutController');

router.get('/', workoutLayoutController.getAllWorkoutLayoutSections);
router.get('/:id', workoutLayoutController.getWorkoutLayoutSectionById);
router.post('/', workoutLayoutController.createWorkoutLayoutSection);
router.put('/:id', workoutLayoutController.updateWorkoutLayoutSection);
router.patch('/:id/status', workoutLayoutController.toggleWorkoutLayoutSectionStatus);
router.post('/reorder', workoutLayoutController.reorderWorkoutLayoutSections);
router.delete('/:id', workoutLayoutController.deleteWorkoutLayoutSection);

module.exports = router;
