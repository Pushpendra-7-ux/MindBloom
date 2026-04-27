const mongoose = require('mongoose');

const trackerSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  date: {
    type: Date,
    required: true
  },
  habits: {
    meditation: { type: Boolean, default: false },
    exercise: { type: Boolean, default: false },
    journaling: { type: Boolean, default: false },
    hydration: { type: Boolean, default: false },
    sleep: { type: Boolean, default: false },
    socializing: { type: Boolean, default: false },
    reading: { type: Boolean, default: false },
    gratitude: { type: Boolean, default: false }
  },
  goals: [{
    title: { type: String, required: true },
    completed: { type: Boolean, default: false }
  }],
  notes: {
    type: String,
    maxlength: 500,
    default: ''
  }
}, {
  timestamps: true
});

trackerSchema.index({ user: 1, date: -1 });

module.exports = mongoose.model('Tracker', trackerSchema);
