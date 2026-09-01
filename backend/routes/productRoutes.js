const express = require('express');
const router = express.Router();
const productController = require('../controllers/productController');

router.get('/', productController.getAllProducts);
router.get('/:id', productController.getProductById);
router.post('/', productController.createOrUpdateProduct);
router.put('/:id', productController.createOrUpdateProduct);
router.delete('/:id', productController.deleteProduct);

module.exports = router;
