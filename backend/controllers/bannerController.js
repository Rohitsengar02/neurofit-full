const Banner = require('../models/Banner');

// 1. GET ALL BANNERS
exports.getAllBanners = async (req, res) => {
  try {
    const { status, targetType } = req.query;
    const filter = {};
    if (status) {
      filter.status = new RegExp(`^${status}$`, 'i');
    }
    if (targetType) {
      filter.targetType = new RegExp(`^${targetType}$`, 'i');
    }

    const banners = await Banner.find(filter).sort({ sortOrder: 1, displayOrder: 1, createdAt: -1 });
    res.json({
      success: true,
      count: banners.length,
      data: banners,
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// 2. GET SINGLE BANNER BY ID
exports.getBannerById = async (req, res) => {
  try {
    const banId = req.params.id;
    const banner = await Banner.findOne({ $or: [{ id: banId }, { bannerId: banId }, { _id: banId.match(/^[0-9a-fA-F]{24}$/) ? banId : null }] });
    if (!banner) {
      return res.status(404).json({ success: false, message: 'Banner not found' });
    }
    res.json({ success: true, data: banner });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// 3. CREATE BANNER
exports.createBanner = async (req, res) => {
  try {
    const bannerId = req.body.id || req.body.bannerId || `banner_${Date.now()}`;
    const newBannerData = {
      ...req.body,
      id: bannerId,
      bannerId: bannerId,
      sortOrder: req.body.sortOrder || req.body.displayOrder || 1,
      displayOrder: req.body.sortOrder || req.body.displayOrder || 1,
      status: req.body.status || 'Active',
      isActive: (req.body.status || 'Active').toLowerCase() === 'active',
    };

    const banner = await Banner.create(newBannerData);

    // Socket.io Real-Time Broadcast
    if (req.io) {
      req.io.emit('banner_created', banner);
      const allBanners = await Banner.find().sort({ sortOrder: 1, createdAt: -1 });
      req.io.emit('banners_updated', allBanners);
      console.log(`📡 [SOCKET.IO] Broadcasted banner_created: ${banner.title} (${banner.id})`);
    }

    res.status(201).json({
      success: true,
      message: 'Banner created successfully in MongoDB Atlas',
      data: banner,
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// 4. UPDATE BANNER
exports.updateBanner = async (req, res) => {
  try {
    const banId = req.params.id;
    const updateData = { ...req.body };
    if (updateData.status) {
      updateData.isActive = updateData.status.toLowerCase() === 'active';
    }
    if (updateData.sortOrder !== undefined) {
      updateData.displayOrder = updateData.sortOrder;
    }

    const banner = await Banner.findOneAndUpdate(
      { $or: [{ id: banId }, { bannerId: banId }] },
      updateData,
      { new: true, upsert: true, runValidators: true }
    );

    // Socket.io Real-Time Broadcast
    if (req.io) {
      req.io.emit('banner_updated', banner);
      const allBanners = await Banner.find().sort({ sortOrder: 1, createdAt: -1 });
      req.io.emit('banners_updated', allBanners);
      console.log(`📡 [SOCKET.IO] Broadcasted banner_updated: ${banner.title} (${banner.id})`);
    }

    res.json({
      success: true,
      message: 'Banner updated successfully in MongoDB Atlas',
      data: banner,
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// 5. TOGGLE BANNER STATUS
exports.toggleBannerStatus = async (req, res) => {
  try {
    const banId = req.params.id;
    const { status } = req.body;
    const banner = await Banner.findOne({ $or: [{ id: banId }, { bannerId: banId }] });
    if (!banner) {
      return res.status(404).json({ success: false, message: 'Banner not found' });
    }

    const newStatus = status || (banner.status === 'Active' ? 'Inactive' : 'Active');
    banner.status = newStatus;
    banner.isActive = newStatus.toLowerCase() === 'active';
    await banner.save();

    // Socket.io Real-Time Broadcast
    if (req.io) {
      req.io.emit('banner_updated', banner);
      const allBanners = await Banner.find().sort({ sortOrder: 1, createdAt: -1 });
      req.io.emit('banners_updated', allBanners);
      console.log(`📡 [SOCKET.IO] Broadcasted banner status change: ${banner.title} => ${newStatus}`);
    }

    res.json({
      success: true,
      message: `Banner status updated to ${newStatus}`,
      data: banner,
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// 6. DELETE BANNER
exports.deleteBanner = async (req, res) => {
  try {
    const banId = req.params.id;
    const deletedBanner = await Banner.findOneAndDelete({ $or: [{ id: banId }, { bannerId: banId }] });

    // Socket.io Real-Time Broadcast
    if (req.io) {
      req.io.emit('banner_deleted', { id: banId, bannerId: banId });
      const allBanners = await Banner.find().sort({ sortOrder: 1, createdAt: -1 });
      req.io.emit('banners_updated', allBanners);
      console.log(`📡 [SOCKET.IO] Broadcasted banner_deleted: ${banId}`);
    }

    res.json({
      success: true,
      message: 'Banner deleted successfully from MongoDB Atlas',
      deletedId: banId,
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// 7. REORDER BANNERS (BATCH UPDATE SORT ORDER)
exports.reorderBanners = async (req, res) => {
  try {
    const { bannerOrders } = req.body; // Array of { id: string, sortOrder: number }
    if (!Array.isArray(bannerOrders)) {
      return res.status(400).json({ success: false, message: 'bannerOrders array is required' });
    }

    const updates = bannerOrders.map((item) =>
      Banner.updateOne(
        { $or: [{ id: item.id }, { bannerId: item.id }] },
        { $set: { sortOrder: item.sortOrder, displayOrder: item.sortOrder } }
      )
    );

    await Promise.all(updates);

    const updatedBanners = await Banner.find().sort({ sortOrder: 1, createdAt: -1 });

    // Socket.io Real-Time Broadcast
    if (req.io) {
      req.io.emit('banners_reordered', updatedBanners);
      req.io.emit('banners_updated', updatedBanners);
      console.log(`📡 [SOCKET.IO] Broadcasted banners_reordered (${updatedBanners.length} banners)`);
    }

    res.json({
      success: true,
      message: 'Banners reordered successfully',
      data: updatedBanners,
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};
