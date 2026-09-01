const SubCategory = require('../models/SubCategory');

exports.getAllSubCategories = async (req, res) => {
  try {
    const query = req.query.categoryId ? { parentCategoryId: req.query.categoryId } : {};
    const subs = await SubCategory.find(query).sort({ sortOrder: 1, name: 1 });
    res.json({ success: true, count: subs.length, data: subs });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

exports.createOrUpdateSubCategory = async (req, res) => {
  try {
    const subId = req.params.id || req.body.id || req.body.subCategoryId || `sub_${Date.now()}`;
    const sub = await SubCategory.findOneAndUpdate(
      { id: subId },
      { ...req.body, id: subId },
      { new: true, upsert: true }
    );
    res.json({ success: true, data: sub });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

exports.deleteSubCategory = async (req, res) => {
  try {
    const subId = req.params.id;
    await SubCategory.findOneAndDelete({ id: subId });
    res.json({ success: true, message: 'Subcategory deleted successfully from MongoDB Atlas' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};
