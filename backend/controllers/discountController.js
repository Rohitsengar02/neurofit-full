const Discount = require('../models/Discount');

exports.getAllDiscounts = async (req, res) => {
  try {
    const discounts = await Discount.find().sort({ createdAt: -1 });
    res.json({ success: true, count: discounts.length, data: discounts });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

exports.validateDiscount = async (req, res) => {
  try {
    const { code, orderValue } = req.body;
    if (!code) return res.status(400).json({ success: false, message: 'Discount code is required' });

    const discount = await Discount.findOne({ code: code.toUpperCase().trim(), isActive: true, status: 'Active' });
    if (!discount) return res.status(404).json({ success: false, message: 'Invalid or inactive coupon code' });

    if (orderValue && orderValue < discount.minOrderValue) {
      return res.status(400).json({
        success: false,
        message: `Minimum order value for this coupon is ₹${discount.minOrderValue}`
      });
    }

    if (discount.usedCount >= discount.maxUses) {
      return res.status(400).json({ success: false, message: 'Coupon limit reached' });
    }

    res.json({ success: true, message: 'Coupon applied successfully', data: discount });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

exports.createOrUpdateDiscount = async (req, res) => {
  try {
    const discId = req.params.id || req.body.discountId || req.body.id || `disc_${Date.now()}`;
    const discount = await Discount.findOneAndUpdate(
      { discountId: discId },
      { ...req.body, discountId: discId },
      { new: true, upsert: true }
    );
    req.app.get('io')?.emit('discount_updated', discount);
    req.app.get('io')?.emit('discounts_updated', discount);
    res.json({ success: true, data: discount });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

exports.deleteDiscount = async (req, res) => {
  try {
    const discId = req.params.id;
    await Discount.findOneAndDelete({ $or: [{ discountId: discId }, { id: discId }] });
    req.app.get('io')?.emit('discount_deleted', { discountId: discId });
    req.app.get('io')?.emit('discounts_updated', { discountId: discId });
    res.json({ success: true, message: 'Discount deleted successfully from MongoDB Atlas' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};
