const ExerciseCategory = require('../models/ExerciseCategory');

// @desc    Get all exercise categories
// @route   GET /api/exercise-categories
// @access  Public
exports.getExerciseCategories = async (req, res) => {
  try {
    const categories = await ExerciseCategory.find().sort({ sortOrder: 1, createdAt: -1 });
    res.status(200).json({
      success: true,
      count: categories.length,
      data: categories,
    });
  } catch (error) {
    console.error('Error fetching exercise categories:', error);
    res.status(500).json({
      success: false,
      message: 'Server Error fetching exercise categories',
      error: error.message,
    });
  }
};

// @desc    Create new exercise category
// @route   POST /api/exercise-categories
// @access  Public / Admin
exports.createExerciseCategory = async (req, res) => {
  try {
    const { name, description, imageUrl, mediaType, sortOrder, isActive } = req.body;
    if (!name) {
      return res.status(400).json({
        success: false,
        message: 'Name is required for exercise category',
      });
    }

    const categoryId = `excat_${Date.now()}_${Math.floor(Math.random() * 1000)}`;
    const slug = name.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)+/g, '');

    let detectedType = mediaType || 'image';
    if (imageUrl) {
      const lower = imageUrl.toLowerCase();
      if (lower.endsWith('.mp4') || lower.endsWith('.mov') || lower.endsWith('.webm')) {
        detectedType = 'video';
      } else if (lower.endsWith('.gif')) {
        detectedType = 'gif';
      }
    }

    const category = await ExerciseCategory.create({
      categoryId,
      name,
      slug,
      description: description || '',
      imageUrl: imageUrl || '',
      mediaType: detectedType,
      sortOrder: sortOrder || 0,
      isActive: isActive !== undefined ? isActive : true,
    });

    const io = req.app.get('io');
    if (io) {
      io.emit('exercise_category_created', category);
      io.emit('exercise_categories_updated', await ExerciseCategory.find().sort({ sortOrder: 1 }));
    }

    res.status(201).json({
      success: true,
      message: 'Exercise category created successfully',
      data: category,
    });
  } catch (error) {
    console.error('Error creating exercise category:', error);
    res.status(500).json({
      success: false,
      message: 'Server Error creating exercise category',
      error: error.message,
    });
  }
};

// @desc    Update exercise category
// @route   PUT /api/exercise-categories/:id
// @access  Public / Admin
exports.updateExerciseCategory = async (req, res) => {
  try {
    const { id } = req.params;
    const category = await ExerciseCategory.findOne({
      $or: [{ _id: id.match(/^[0-9a-fA-F]{24}$/) ? id : null }, { categoryId: id }],
    });

    if (!category) {
      return res.status(404).json({
        success: false,
        message: 'Exercise category not found',
      });
    }

    const fields = ['name', 'description', 'imageUrl', 'mediaType', 'sortOrder', 'isActive'];
    fields.forEach((f) => {
      if (req.body[f] !== undefined) {
        category[f] = req.body[f];
      }
    });

    if (req.body.name) {
      category.slug = req.body.name.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)+/g, '');
    }

    await category.save();

    const io = req.app.get('io');
    if (io) {
      io.emit('exercise_category_updated', category);
      io.emit('exercise_categories_updated', await ExerciseCategory.find().sort({ sortOrder: 1 }));
    }

    res.status(200).json({
      success: true,
      message: 'Exercise category updated successfully',
      data: category,
    });
  } catch (error) {
    console.error('Error updating exercise category:', error);
    res.status(500).json({
      success: false,
      message: 'Server Error updating exercise category',
      error: error.message,
    });
  }
};

// @desc    Delete exercise category
// @route   DELETE /api/exercise-categories/:id
// @access  Public / Admin
exports.deleteExerciseCategory = async (req, res) => {
  try {
    const { id } = req.params;
    const category = await ExerciseCategory.findOneAndDelete({
      $or: [{ _id: id.match(/^[0-9a-fA-F]{24}$/) ? id : null }, { categoryId: id }],
    });

    if (!category) {
      return res.status(404).json({
        success: false,
        message: 'Exercise category not found',
      });
    }

    const io = req.app.get('io');
    if (io) {
      io.emit('exercise_category_deleted', { id: category._id, categoryId: category.categoryId });
      io.emit('exercise_categories_updated', await ExerciseCategory.find().sort({ sortOrder: 1 }));
    }

    res.status(200).json({
      success: true,
      message: 'Exercise category deleted successfully',
      data: category,
    });
  } catch (error) {
    console.error('Error deleting exercise category:', error);
    res.status(500).json({
      success: false,
      message: 'Server Error deleting exercise category',
      error: error.message,
    });
  }
};
