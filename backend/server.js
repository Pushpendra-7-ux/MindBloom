const express = require('express');
const cors = require('cors');
require('dotenv').config();

const connectDB = require('./config/db');

const app = express();

// Middleware
app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Connect to MongoDB
connectDB();

// Routes
app.use('/api/auth', require('./routes/auth'));
app.use('/api/mood', require('./routes/mood'));
app.use('/api/recommendations', require('./routes/recommendations'));
app.use('/api/appointments', require('./routes/appointments'));
app.use('/api/tracker', require('./routes/tracker'));

// Health check
app.get('/', (req, res) => {
  res.json({ 
    message: 'MindBloom API is running 🌸',
    version: '1.0.0',
    endpoints: [
      'POST /api/auth/signup',
      'POST /api/auth/login',
      'GET  /api/auth/me',
      'PUT  /api/auth/profile',
      'PUT  /api/auth/category',
      'POST /api/mood/checkin',
      'GET  /api/mood/history',
      'GET  /api/mood/weekly',
      'GET  /api/mood/latest',
      'POST /api/recommendations/generate',
      'POST /api/appointments',
      'GET  /api/appointments',
      'PUT  /api/appointments/:id',
      'DELETE /api/appointments/:id',
      'POST /api/tracker',
      'GET  /api/tracker',
      'GET  /api/tracker/today'
    ]
  });
});

// Global error handler
app.use((err, req, res, next) => {
  console.error('Unhandled error:', err);
  res.status(500).json({ message: 'Internal server error' });
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`🌸 MindBloom API running on http://0.0.0.0:${PORT}`);
});
