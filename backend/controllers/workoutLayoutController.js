const WorkoutLayoutSection = require('../models/WorkoutLayoutSection');

exports.getAllWorkoutLayoutSections = async (req, res) => {
  try {
    const sections = await WorkoutLayoutSection.find().sort({ displayOrder: 1, sortOrder: 1, createdAt: 1 }).lean();
    res.json({
      success: true,
      count: sections.length,
      data: sections,
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

exports.getWorkoutLayoutSectionById = async (req, res) => {
  try {
    const section = await WorkoutLayoutSection.findOne({
      $or: [{ id: req.params.id }, { sectionId: req.params.id }],
    });
    if (!section) {
      return res.status(404).json({ success: false, message: 'Workout layout section not found' });
    }
    res.json({ success: true, data: section });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

exports.createWorkoutLayoutSection = async (req, res) => {
  try {
    const payload = req.body;
    if (!payload.id) {
      payload.id = payload.sectionId || `section_${Date.now()}`;
    }
    payload.sectionId = payload.id;

    if (payload.sortOrder == null) {
      const highest = await WorkoutLayoutSection.findOne().sort({ sortOrder: -1 });
      payload.sortOrder = highest ? (highest.sortOrder || 0) + 1 : 1;
      payload.displayOrder = payload.sortOrder;
    }

    const section = await WorkoutLayoutSection.create(payload);

    const io = req.app.get('socketio') || req.io;
    if (io) {
      io.emit('workout_layout_updated', { action: 'create', section });
    }

    res.status(201).json({ success: true, data: section });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

exports.updateWorkoutLayoutSection = async (req, res) => {
  try {
    const section = await WorkoutLayoutSection.findOneAndUpdate(
      { $or: [{ id: req.params.id }, { sectionId: req.params.id }] },
      { $set: req.body },
      { new: true }
    );
    if (!section) {
      return res.status(404).json({ success: false, message: 'Workout layout section not found' });
    }

    const io = req.app.get('socketio') || req.io;
    if (io) {
      io.emit('workout_layout_updated', { action: 'update', section });
    }

    res.json({ success: true, data: section });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

exports.toggleWorkoutLayoutSectionStatus = async (req, res) => {
  try {
    const section = await WorkoutLayoutSection.findOne({
      $or: [{ id: req.params.id }, { sectionId: req.params.id }],
    });
    if (!section) {
      return res.status(404).json({ success: false, message: 'Workout layout section not found' });
    }

    section.isActive = req.body.isActive !== undefined ? req.body.isActive : !section.isActive;
    await section.save();

    const io = req.app.get('socketio') || req.io;
    if (io) {
      io.emit('workout_layout_updated', { action: 'toggle', section });
    }

    res.json({ success: true, data: section });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

exports.reorderWorkoutLayoutSections = async (req, res) => {
  try {
    let ids = req.body.sectionIds;
    if (!ids && Array.isArray(req.body.sectionOrders)) {
      ids = req.body.sectionOrders.map((o) => o.id);
    }
    if (!Array.isArray(ids)) {
      return res.status(400).json({ success: false, message: 'sectionIds or sectionOrders must be an array' });
    }

    const bulkOps = ids.map((id, index) => ({
      updateOne: {
        filter: { $or: [{ id }, { sectionId: id }] },
        update: { $set: { sortOrder: index + 1, displayOrder: index + 1 } },
      },
    }));

    await WorkoutLayoutSection.bulkWrite(bulkOps);

    const updated = await WorkoutLayoutSection.find().sort({ sortOrder: 1 }).lean();

    const io = req.app.get('socketio') || req.io;
    if (io) {
      io.emit('workout_layout_updated', { action: 'reorder', sections: updated });
    }

    res.json({ success: true, count: updated.length, data: updated });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

exports.deleteWorkoutLayoutSection = async (req, res) => {
  try {
    const section = await WorkoutLayoutSection.findOneAndDelete({
      $or: [{ id: req.params.id }, { sectionId: req.params.id }],
    });
    if (!section) {
      return res.status(404).json({ success: false, message: 'Workout layout section not found' });
    }

    const io = req.app.get('socketio') || req.io;
    if (io) {
      io.emit('workout_layout_updated', { action: 'delete', sectionId: req.params.id });
    }

    res.json({ success: true, message: 'Workout layout section removed' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};
