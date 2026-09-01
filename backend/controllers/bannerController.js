const Banner = require('../models/Banner');

exports.getAllBanners = async (req, res) => {
  try {
    const banners = await Banner.find().sort({ displayOrder: 1, createdAt: -1 });
    res.json({ success: true, count: banners.length, data: banners });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

exports.createOrUpdateBanner = async (req, res) => {
  try {
    const { id } = req.body;
    const banId = id || req.params.id || `ban_${Date.now()}`;
    const banner = await Banner.findOneAndUpdate(
      { id: banId },
      { ...req.body, id: banId },
      { new: true, upsert: true }
    );
    res.json({ success: true, data: banner });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};
