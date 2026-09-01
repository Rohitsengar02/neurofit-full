const Order = require('../models/Order');

exports.createOrder = async (req, res) => {
  try {
    const { orderId } = req.body;
    const id = orderId || `NF-ORD-${Date.now()}`;
    const order = await Order.create({ ...req.body, orderId: id });

    if (req.io) {
      req.io.emit('order:created', order);
      if (order.uid) {
        req.io.to(`user_${order.uid}`).emit('order:user_created', order);
      }
    }

    res.status(201).json({ success: true, data: order });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

exports.getUserOrders = async (req, res) => {
  try {
    const orders = await Order.find({ uid: req.params.uid }).sort({ createdAt: -1 });
    res.json({ success: true, count: orders.length, data: orders });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

exports.updateOrderStatus = async (req, res) => {
  try {
    const { orderId } = req.params;
    const { orderStatus, paymentStatus } = req.body;
    const order = await Order.findOneAndUpdate(
      { orderId },
      { orderStatus, paymentStatus },
      { new: true }
    );

    if (req.io && order) {
      req.io.emit('order:updated', order);
      req.io.to(`user_${order.uid}`).emit('order:user_updated', order);
    }

    res.json({ success: true, data: order });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};
