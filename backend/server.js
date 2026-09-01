const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');
const dotenv = require('dotenv');
const connectDB = require('./config/db');
const firebaseAdmin = require('./config/firebaseAdmin');

dotenv.config();
connectDB();

const app = express();
const server = http.createServer(app);

const io = new Server(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST', 'PUT', 'DELETE'],
  },
});

app.use(cors());
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true, limit: '50mb' }));

// Live Request Logger Middleware
app.use((req, res, next) => {
  const time = new Date().toLocaleTimeString();
  console.log(`[${time}] 📥 ${req.method} ${req.originalUrl}`);
  if (req.method === 'POST' || req.method === 'PUT') {
    console.log('📦 Body:', JSON.stringify(req.body, null, 2));
  }
  next();
});

// Pass socket.io instance to request
app.use((req, res, next) => {
  req.io = io;
  next();
});

io.on('connection', (socket) => {
  console.log(`🔌 Client connected to Socket.io: ${socket.id}`);

  socket.on('join_user_room', (uid) => {
    socket.join(`user_${uid}`);
    console.log(`👤 Socket ${socket.id} joined room: user_${uid}`);
  });

  socket.on('disconnect', () => {
    console.log(`❌ Client disconnected: ${socket.id}`);
  });
});

// API Routes
app.use('/api/products', require('./routes/productRoutes'));
app.use('/api/categories', require('./routes/categoryRoutes'));
app.use('/api/banners', require('./routes/bannerRoutes'));
app.use('/api/layout', require('./routes/layoutRoutes'));
app.use('/api/orders', require('./routes/orderRoutes'));
app.use('/api/users', require('./routes/userRoutes'));
app.use('/api/sync', require('./routes/syncRoutes'));
app.use('/api/admin', require('./routes/adminRoutes'));
app.use('/api/discounts', require('./routes/discountRoutes'));
app.use('/api/subcategories', require('./routes/subCategoryRoutes'));

app.get('/', (req, res) => {
  res.send('⚡ NeuroFit Real-Time Express + Socket.io Backend API with MongoDB Atlas is Live!');
});

const PORT = process.env.PORT || 5000;
server.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Real-Time NeuroFit Server listening on port ${PORT} (0.0.0.0 - All Network Interfaces)`);
});
