const mongoose = require('mongoose');

const moodLogSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  moodScore: {
    type: Number,
    required: true,
    min: 1,
    max: 10
  },
  emoji: {
    type: String,
    required: true
  },
  feelings: [{
    type: String,
    enum: [
      'happy', 'sad', 'anxious', 'calm', 'stressed',
      'energetic', 'tired', 'grateful', 'angry', 'hopeful',
      'lonely', 'loved', 'confused', 'motivated', 'overwhelmed'
    ]
  }],
  activities: [{
    type: String,
    enum: [
      'exercise', 'meditation', 'reading', 'socializing',
      'work', 'sleep', 'nature', 'music', 'cooking',
      'journaling', 'therapy', 'gaming', 'studying', 'walking'
    ]
  }],
  journal: {
    type: String,
    maxlength: 1000,
    default: ''
  },
  sleepHours: {
    type: Number,
    min: 0,
    max: 24,
    default: 0
  },
  waterIntake: {
    type: Number,
    min: 0,
    max: 20,
    default: 0
  },
  exerciseMinutes: {
    type: Number,
    min: 0,
    max: 300,
    default: 0
  }
}, {
  timestamps: true
});

// Index for efficient queries
moodLogSchema.index({ user: 1, createdAt: -1 });

module.exports = mongoose.model('MoodLog', moodLogSchema);
