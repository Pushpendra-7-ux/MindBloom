const mongoose = require('mongoose');

const appointmentSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  doctorName: {
    type: String,
    required: true,
    trim: true
  },
  specialty: {
    type: String,
    required: true,
    enum: ['psychiatrist', 'psychologist', 'therapist', 'counselor', 'general']
  },
  clinicName: {
    type: String,
    trim: true,
    default: ''
  },
  date: {
    type: Date,
    required: true
  },
  time: {
    type: String,
    required: true
  },
  duration: {
    type: Number,
    default: 60 // minutes
  },
  status: {
    type: String,
    enum: ['scheduled', 'completed', 'cancelled', 'rescheduled'],
    default: 'scheduled'
  },
  notes: {
    type: String,
    maxlength: 500,
    default: ''
  },
  reminder: {
    type: Boolean,
    default: true
  }
}, {
  timestamps: true
});

appointmentSchema.index({ user: 1, date: -1 });

module.exports = mongoose.model('Appointment', appointmentSchema);
