const WorkoutProgram = require('../models/WorkoutProgram');

exports.getAllPrograms = async (req, res) => {
  try {
    const programs = await WorkoutProgram.find().sort({ sortOrder: 1, createdAt: -1 }).lean();
    res.json({
      success: true,
      count: programs.length,
      data: programs,
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

exports.getProgramById = async (req, res) => {
  try {
    const program = await WorkoutProgram.findOne({ id: req.params.id });
    if (!program) return res.status(404).json({ success: false, message: 'Program not found' });
    res.json({ success: true, data: program });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

exports.createProgram = async (req, res) => {
  try {
    const payload = req.body;
    if (!payload.id) {
      payload.id = `prog_${Date.now()}`;
    }
    const program = await WorkoutProgram.create(payload);

    const io = req.app.get('socketio') || req.io;
    if (io) {
      io.emit('program_created', program);
    }

    res.status(201).json({ success: true, data: program });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

exports.updateProgram = async (req, res) => {
  try {
    const program = await WorkoutProgram.findOneAndUpdate(
      { id: req.params.id },
      { $set: req.body },
      { new: true }
    );
    if (!program) return res.status(404).json({ success: false, message: 'Program not found' });

    const io = req.app.get('socketio') || req.io;
    if (io) {
      io.emit('program_updated', program);
    }

    res.json({ success: true, data: program });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

exports.deleteProgram = async (req, res) => {
  try {
    const program = await WorkoutProgram.findOneAndDelete({ id: req.params.id });
    if (!program) return res.status(404).json({ success: false, message: 'Program not found' });

    const io = req.app.get('socketio') || req.io;
    if (io) {
      io.emit('program_deleted', { id: req.params.id });
    }

    res.json({ success: true, message: 'Program deleted' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};
