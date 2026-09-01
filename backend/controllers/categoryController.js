const Category = require('../models/Category');

exports.getAllCategories = async (req, res) => {
  try {
    const categories = await Category.find().sort({ sortOrder: 1, name: 1 });
    res.json({ success: true, count: categories.length, data: categories });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

exports.createOrUpdateCategory = async (req, res) => {
  try {
    const catId = req.params.id || req.body.id || req.body.categoryId || `cat_${Date.now()}`;
    const category = await Category.findOneAndUpdate(
      { id: catId },
      { ...req.body, id: catId },
      { new: true, upsert: true }
    );
    res.json({ success: true, data: category });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

exports.deleteCategory = async (req, res) => {
  try {
    const catId = req.params.id;
    await Category.findOneAndDelete({ id: catId });
    res.json({ success: true, message: 'Category deleted successfully from MongoDB Atlas' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};
