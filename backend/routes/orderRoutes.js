const express = require('express');
const router = express.Router();
const orderController = require('../controllers/orderController');

// GET all orders & POST create order
router.get('/', orderController.getAllOrders);
router.post('/', orderController.createOrder);

// GET orders for user
router.get('/user/:uid', orderController.getUserOrders);

// GET single order
router.get('/:orderId', orderController.getOrderById);

// UPDATE order status
router.put('/:orderId/status', orderController.updateOrderStatus);

// DELETE / cancel order
router.delete('/:orderId', orderController.deleteOrder);

module.exports = router;
