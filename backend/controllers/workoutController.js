const Workout = require('../models/Workout');

exports.getAllWorkouts = async (req, res) => {
  try {
    const workouts = await Workout.find().sort({ createdAt: -1 }).lean();
    res.json({
      success: true,
      count: workouts.length,
      data: workouts,
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

exports.getWorkoutById = async (req, res) => {
  try {
    const workout = await Workout.findOne({ id: req.params.id });
    if (!workout) return res.status(404).json({ success: false, message: 'Workout not found' });
    res.json({ success: true, data: workout });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

exports.createWorkout = async (req, res) => {
  try {
    const payload = req.body;
    if (!payload.id) {
      payload.id = `workout_${Date.now()}`;
    }
    const workout = await Workout.create(payload);

    const io = req.app.get('io') || req.app.get('socketio') || req.io;
    if (io) {
      const allWorkouts = await Workout.find().sort({ createdAt: -1 }).lean();
      io.emit('workout_created', workout);
      io.emit('workouts_updated', allWorkouts);
    }

    res.status(201).json({ success: true, data: workout });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

exports.updateWorkout = async (req, res) => {
  try {
    const workout = await Workout.findOneAndUpdate(
      { id: req.params.id },
      { $set: req.body },
      { new: true }
    );
    if (!workout) return res.status(404).json({ success: false, message: 'Workout not found' });

    const io = req.app.get('io') || req.app.get('socketio') || req.io;
    if (io) {
      const allWorkouts = await Workout.find().sort({ createdAt: -1 }).lean();
      io.emit('workout_updated', workout);
      io.emit('workouts_updated', allWorkouts);
    }

    res.json({ success: true, data: workout });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

exports.deleteWorkout = async (req, res) => {
  try {
    const workout = await Workout.findOneAndDelete({ id: req.params.id });
    if (!workout) return res.status(404).json({ success: false, message: 'Workout not found' });

    const io = req.app.get('io') || req.app.get('socketio') || req.io;
    if (io) {
      const allWorkouts = await Workout.find().sort({ createdAt: -1 }).lean();
      io.emit('workout_deleted', { id: req.params.id });
      io.emit('workouts_updated', allWorkouts);
    }

    res.json({ success: true, message: 'Workout deleted' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};
