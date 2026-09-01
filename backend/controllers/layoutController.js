const LayoutSection = require('../models/LayoutSection');

exports.getAllLayoutSections = async (req, res) => {
  try {
    const sections = await LayoutSection.find().sort({ sortOrder: 1 });
    res.json({ success: true, count: sections.length, data: sections });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

exports.createOrUpdateLayoutSection = async (req, res) => {
  try {
    const { id } = req.body;
    const secId = id || req.params.id || `sec_${Date.now()}`;
    const section = await LayoutSection.findOneAndUpdate(
      { id: secId },
      { ...req.body, id: secId },
      { new: true, upsert: true }
    );
    res.json({ success: true, data: section });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};
