const WorkoutBanner = require('../models/WorkoutBanner');

// @desc    Get all workout banners
// @route   GET /api/workout-banners
// @access  Public
exports.getWorkoutBanners = async (req, res) => {
  try {
    const banners = await WorkoutBanner.find().sort({ sortOrder: 1, createdAt: -1 });
    res.status(200).json({
      success: true,
      count: banners.length,
      data: banners,
    });
  } catch (error) {
    console.error('Error fetching workout banners:', error);
    res.status(500).json({
      success: false,
      message: 'Server Error fetching workout banners',
      error: error.message,
    });
  }
};

// @desc    Get active workout banners
// @route   GET /api/workout-banners/active
// @access  Public
exports.getActiveWorkoutBanners = async (req, res) => {
  try {
    const banners = await WorkoutBanner.find({ isActive: true }).sort({ sortOrder: 1, createdAt: -1 });
    res.status(200).json({
      success: true,
      count: banners.length,
      data: banners,
    });
  } catch (error) {
    console.error('Error fetching active workout banners:', error);
    res.status(500).json({
      success: false,
      message: 'Server Error fetching active workout banners',
      error: error.message,
    });
  }
};

// @desc    Create a new workout banner
// @route   POST /api/workout-banners
// @access  Public / Admin
exports.createWorkoutBanner = async (req, res) => {
  try {
    const {
      title,
      subtitle,
      imageUrl,
      mediaType,
      targetType,
      targetId,
      targetName,
      badge,
      buttonText,
      showTitle,
      sortOrder,
      isActive,
    } = req.body;

    if (!imageUrl) {
      return res.status(400).json({
        success: false,
        message: 'imageUrl / mediaUrl is required',
      });
    }

    const bannerId = `wban_${Date.now()}_${Math.floor(Math.random() * 1000)}`;

    // Auto-detect mediaType if not explicitly passed
    let detectedType = mediaType || 'image';
    if (!mediaType) {
      const lower = imageUrl.toLowerCase();
      if (lower.endsWith('.mp4') || lower.endsWith('.mov') || lower.endsWith('.webm') || lower.endsWith('.avi')) {
        detectedType = 'video';
      } else if (lower.endsWith('.gif')) {
        detectedType = 'gif';
      }
    }

    const newBanner = await WorkoutBanner.create({
      bannerId,
      title: title || '',
      subtitle: subtitle || '',
      imageUrl,
      mediaType: detectedType,
      targetType: targetType || 'category',
      targetId: targetId || '',
      targetName: targetName || '',
      badge: badge || '',
      buttonText: buttonText || 'Explore',
      showTitle: showTitle !== undefined ? showTitle : true,
      sortOrder: sortOrder || 0,
      isActive: isActive !== undefined ? isActive : true,
    });

    const io = req.app.get('io');
    if (io) {
      io.emit('workout_banner_created', newBanner);
      io.emit('workout_banners_updated', await WorkoutBanner.find().sort({ sortOrder: 1 }));
    }

    res.status(201).json({
      success: true,
      message: 'Workout banner created successfully',
      data: newBanner,
    });
  } catch (error) {
    console.error('Error creating workout banner:', error);
    res.status(500).json({
      success: false,
      message: 'Server Error creating workout banner',
      error: error.message,
    });
  }
};

// @desc    Update a workout banner
// @route   PUT /api/workout-banners/:id
// @access  Public / Admin
exports.updateWorkoutBanner = async (req, res) => {
  try {
    const { id } = req.params;
    const banner = await WorkoutBanner.findOne({
      $or: [{ _id: id.match(/^[0-9a-fA-F]{24}$/) ? id : null }, { bannerId: id }],
    });

    if (!banner) {
      return res.status(404).json({
        success: false,
        message: 'Workout banner not found',
      });
    }

    const allowedFields = [
      'title',
      'subtitle',
      'imageUrl',
      'mediaType',
      'targetType',
      'targetId',
      'targetName',
      'badge',
      'buttonText',
      'showTitle',
      'sortOrder',
      'isActive',
    ];

    allowedFields.forEach((field) => {
      if (req.body[field] !== undefined) {
        banner[field] = req.body[field];
      }
    });

    await banner.save();

    const io = req.app.get('io');
    if (io) {
      io.emit('workout_banner_updated', banner);
      io.emit('workout_banners_updated', await WorkoutBanner.find().sort({ sortOrder: 1 }));
    }

    res.status(200).json({
      success: true,
      message: 'Workout banner updated successfully',
      data: banner,
    });
  } catch (error) {
    console.error('Error updating workout banner:', error);
    res.status(500).json({
      success: false,
      message: 'Server Error updating workout banner',
      error: error.message,
    });
  }
};

// @desc    Delete a workout banner
// @route   DELETE /api/workout-banners/:id
// @access  Public / Admin
exports.deleteWorkoutBanner = async (req, res) => {
  try {
    const { id } = req.params;
    const banner = await WorkoutBanner.findOneAndDelete({
      $or: [{ _id: id.match(/^[0-9a-fA-F]{24}$/) ? id : null }, { bannerId: id }],
    });

    if (!banner) {
      return res.status(404).json({
        success: false,
        message: 'Workout banner not found',
      });
    }

    const io = req.app.get('io');
    if (io) {
      io.emit('workout_banner_deleted', { id: banner._id, bannerId: banner.bannerId });
      io.emit('workout_banners_updated', await WorkoutBanner.find().sort({ sortOrder: 1 }));
    }

    res.status(200).json({
      success: true,
      message: 'Workout banner deleted successfully',
      data: banner,
    });
  } catch (error) {
    console.error('Error deleting workout banner:', error);
    res.status(500).json({
      success: false,
      message: 'Server Error deleting workout banner',
      error: error.message,
    });
  }
};

// @desc    Reorder workout banners
// @route   POST /api/workout-banners/reorder
// @access  Public / Admin
exports.reorderWorkoutBanners = async (req, res) => {
  try {
    const { bannerIds } = req.body;
    if (!Array.isArray(bannerIds)) {
      return res.status(400).json({
        success: false,
        message: 'bannerIds must be an array of banner identifiers',
      });
    }

    const bulkOps = bannerIds.map((id, index) => ({
      updateOne: {
        filter: { $or: [{ _id: id.match(/^[0-9a-fA-F]{24}$/) ? id : null }, { bannerId: id }] },
        update: { $set: { sortOrder: index + 1 } },
      },
    }));

    await WorkoutBanner.bulkWrite(bulkOps);

    const banners = await WorkoutBanner.find().sort({ sortOrder: 1 });

    const io = req.app.get('io');
    if (io) {
      io.emit('workout_banners_updated', banners);
    }

    res.status(200).json({
      success: true,
      message: 'Workout banners reordered successfully',
      data: banners,
    });
  } catch (error) {
    console.error('Error reordering workout banners:', error);
    res.status(500).json({
      success: false,
      message: 'Server Error reordering workout banners',
      error: error.message,
    });
  }
};
