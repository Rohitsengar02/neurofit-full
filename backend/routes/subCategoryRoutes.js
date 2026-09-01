const express = require('express');
const router = express.Router();
const subCategoryController = require('../controllers/subCategoryController');

router.get('/', subCategoryController.getAllSubCategories);
router.post('/', subCategoryController.createOrUpdateSubCategory);
router.put('/:id', subCategoryController.createOrUpdateSubCategory);
router.delete('/:id', subCategoryController.deleteSubCategory);

module.exports = router;
