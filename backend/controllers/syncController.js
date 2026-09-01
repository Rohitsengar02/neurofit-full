const { exec } = require('child_process');

exports.triggerSync = (req, res) => {
  exec('node scripts/syncFirebaseToMongo.js', (err, stdout, stderr) => {
    if (err) {
      return res.status(500).json({ success: false, error: err.message });
    }
    res.json({ success: true, output: stdout });
  });
};
