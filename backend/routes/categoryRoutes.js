const express = require('express');
const router = express.Router();
const categoryController = require('../controllers/categoryController');

router.get('/', categoryController.getAllCategories);
router.post('/', categoryController.createOrUpdateCategory);
router.put('/:id', categoryController.createOrUpdateCategory);
router.delete('/:id', categoryController.deleteCategory);

module.exports = router;
