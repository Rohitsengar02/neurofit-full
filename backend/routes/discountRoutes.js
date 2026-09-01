const express = require('express');
const router = express.Router();
const discountController = require('../controllers/discountController');

router.get('/', discountController.getAllDiscounts);
router.post('/validate', discountController.validateDiscount);
router.post('/', discountController.createOrUpdateDiscount);
router.put('/:id', discountController.createOrUpdateDiscount);
router.delete('/:id', discountController.deleteDiscount);

module.exports = router;
