const Exercise = require('../models/Exercise');

exports.getAllExercises = async (req, res) => {
  try {
    const exercises = await Exercise.find().sort({ createdAt: -1 }).lean();
    res.json({
      success: true,
      count: exercises.length,
      data: exercises,
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

exports.getExerciseById = async (req, res) => {
  try {
    const exercise = await Exercise.findOne({ id: req.params.id });
    if (!exercise) return res.status(404).json({ success: false, message: 'Exercise not found' });
    res.json({ success: true, data: exercise });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

exports.createExercise = async (req, res) => {
  try {
    const payload = req.body;
    if (!payload.id) {
      payload.id = `ex_${Date.now()}`;
    }
    const exercise = await Exercise.create(payload);

    const io = req.app.get('socketio') || req.io;
    if (io) {
      io.emit('exercise_created', exercise);
    }

    res.status(201).json({ success: true, data: exercise });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

exports.updateExercise = async (req, res) => {
  try {
    const exercise = await Exercise.findOneAndUpdate(
      { id: req.params.id },
      { $set: req.body },
      { new: true }
    );
    if (!exercise) return res.status(404).json({ success: false, message: 'Exercise not found' });

    const io = req.app.get('socketio') || req.io;
    if (io) {
      io.emit('exercise_updated', exercise);
    }

    res.json({ success: true, data: exercise });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

exports.deleteExercise = async (req, res) => {
  try {
    const exercise = await Exercise.findOneAndDelete({ id: req.params.id });
    if (!exercise) return res.status(404).json({ success: false, message: 'Exercise not found' });

    const io = req.app.get('socketio') || req.io;
    if (io) {
      io.emit('exercise_deleted', { id: req.params.id });
    }

    res.json({ success: true, message: 'Exercise deleted' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};
