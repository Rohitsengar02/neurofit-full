const WorkoutCategory = require('../models/WorkoutCategory');

exports.getAllWorkoutCategories = async (req, res) => {
  try {
    const categories = await WorkoutCategory.find().sort({ sortOrder: 1, createdAt: 1 }).lean();
    res.json({
      success: true,
      count: categories.length,
      data: categories,
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

exports.getWorkoutCategoryById = async (req, res) => {
  try {
    const category = await WorkoutCategory.findOne({ id: req.params.id });
    if (!category) return res.status(404).json({ success: false, message: 'Workout category not found' });
    res.json({ success: true, data: category });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

exports.createWorkoutCategory = async (req, res) => {
  try {
    const payload = req.body;
    if (!payload.id) {
      payload.id = `wcat_${Date.now()}`;
    }
    if (payload.sortOrder == null) {
      const highest = await WorkoutCategory.findOne().sort({ sortOrder: -1 });
      payload.sortOrder = highest ? (highest.sortOrder || 0) + 1 : 1;
    }

    const category = await WorkoutCategory.create(payload);

    const io = req.app.get('socketio') || req.io;
    if (io) {
      io.emit('workout_category_updated', { action: 'create', category });
    }

    res.status(201).json({ success: true, data: category });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

exports.updateWorkoutCategory = async (req, res) => {
  try {
    const category = await WorkoutCategory.findOneAndUpdate(
      { id: req.params.id },
      { $set: req.body },
      { new: true }
    );
    if (!category) return res.status(404).json({ success: false, message: 'Workout category not found' });

    const io = req.app.get('socketio') || req.io;
    if (io) {
      io.emit('workout_category_updated', { action: 'update', category });
    }

    res.json({ success: true, data: category });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

exports.toggleWorkoutCategoryStatus = async (req, res) => {
  try {
    const category = await WorkoutCategory.findOne({ id: req.params.id });
    if (!category) return res.status(404).json({ success: false, message: 'Workout category not found' });

    category.isActive = req.body.isActive !== undefined ? req.body.isActive : !category.isActive;
    await category.save();

    const io = req.app.get('socketio') || req.io;
    if (io) {
      io.emit('workout_category_updated', { action: 'toggle', category });
    }

    res.json({ success: true, data: category });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

exports.reorderWorkoutCategories = async (req, res) => {
  try {
    let ids = req.body.categoryIds;
    if (!ids && Array.isArray(req.body.categoryOrders)) {
      ids = req.body.categoryOrders.map((o) => o.id);
    }
    if (!Array.isArray(ids)) {
      return res.status(400).json({ success: false, message: 'categoryIds or categoryOrders must be an array' });
    }

    const bulkOps = ids.map((id, index) => ({
      updateOne: {
        filter: { id },
        update: { $set: { sortOrder: index + 1 } },
      },
    }));

    await WorkoutCategory.bulkWrite(bulkOps);

    const updated = await WorkoutCategory.find().sort({ sortOrder: 1 }).lean();

    const io = req.app.get('socketio') || req.io;
    if (io) {
      io.emit('workout_category_updated', { action: 'reorder', categories: updated });
    }

    res.json({ success: true, count: updated.length, data: updated });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

exports.deleteWorkoutCategory = async (req, res) => {
  try {
    const category = await WorkoutCategory.findOneAndDelete({ id: req.params.id });
    if (!category) return res.status(404).json({ success: false, message: 'Workout category not found' });

    const io = req.app.get('socketio') || req.io;
    if (io) {
      io.emit('workout_category_updated', { action: 'delete', categoryId: req.params.id });
    }

    res.json({ success: true, message: 'Workout category deleted' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};
