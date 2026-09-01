const Product = require('../models/Product');

exports.getAllProducts = async (req, res) => {
  try {
    const products = await Product.find().sort({ createdAt: -1 });
    res.json({ success: true, count: products.length, data: products });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

exports.getProductById = async (req, res) => {
  try {
    const product = await Product.findOne({ id: req.params.id });
    if (!product) return res.status(404).json({ success: false, message: 'Product not found' });
    res.json({ success: true, data: product });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

exports.createOrUpdateProduct = async (req, res) => {
  try {
    const prodId = req.params.id || req.body.id || req.body.productId || `prod_${Date.now()}`;
    const product = await Product.findOneAndUpdate(
      { id: prodId },
      { ...req.body, id: prodId },
      { new: true, upsert: true }
    );
    res.json({ success: true, data: product });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

exports.deleteProduct = async (req, res) => {
  try {
    const prodId = req.params.id;
    await Product.findOneAndDelete({ id: prodId });
    res.json({ success: true, message: 'Product deleted successfully from MongoDB Atlas' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};
