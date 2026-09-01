const mongoose = require('mongoose');

const connectDB = async () => {
  const uri = process.env.MONGO_URI || 'mongodb+srv://rohitsengar02_db_user:HtQBKwZ4zHyDnSKS@neurofitapp.pfpotec.mongodb.net/neurofit?retryWrites=true&w=majority';
  try {
    const conn = await mongoose.connect(uri, {
      serverSelectionTimeoutMS: 15000,
    });
    console.log(`✅ MongoDB Atlas Connected: ${conn.connection.host} (DB: ${conn.connection.name})`);
  } catch (err) {
    console.error('❌ Error connecting to MongoDB:', err.message);
    console.log('💡 Tip: If you see whitelist error, ensure 0.0.0.0/0 is Active in Atlas Network Access and your cluster is not paused.');
  }
};

module.exports = connectDB;
