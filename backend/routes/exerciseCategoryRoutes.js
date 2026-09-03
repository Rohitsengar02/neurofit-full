const express = require('express');
const router = express.Router();
const {
  getExerciseCategories,
  createExerciseCategory,
  updateExerciseCategory,
  deleteExerciseCategory,
} = require('../controllers/exerciseCategoryController');

router.get('/', getExerciseCategories);
router.post('/', createExerciseCategory);
router.put('/:id', updateExerciseCategory);
router.delete('/:id', deleteExerciseCategory);

module.exports = router;
