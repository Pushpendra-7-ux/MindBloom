const express = require('express');
const Appointment = require('../models/Appointment');
const auth = require('../middleware/auth');

const router = express.Router();

// POST /api/appointments
router.post('/', auth, async (req, res) => {
  try {
    const { doctorName, specialty, clinicName, date, time, duration, notes } = req.body;

    const appointment = new Appointment({
      user: req.user.id,
      doctorName,
      specialty,
      clinicName,
      date,
      time,
      duration: duration || 60,
      notes: notes || ''
    });

    await appointment.save();
    res.status(201).json({ message: 'Appointment created', appointment });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// GET /api/appointments
router.get('/', auth, async (req, res) => {
  try {
    const { status, upcoming } = req.query;
    const query = { user: req.user.id };
    
    if (status) query.status = status;
    if (upcoming === 'true') query.date = { $gte: new Date() };

    const appointments = await Appointment.find(query).sort({ date: 1 });
    res.json({ appointments });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// PUT /api/appointments/:id
router.put('/:id', auth, async (req, res) => {
  try {
    const appointment = await Appointment.findOneAndUpdate(
      { _id: req.params.id, user: req.user.id },
      req.body,
      { new: true }
    );
    if (!appointment) {
      return res.status(404).json({ message: 'Appointment not found' });
    }
    res.json({ message: 'Appointment updated', appointment });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// DELETE /api/appointments/:id
router.delete('/:id', auth, async (req, res) => {
  try {
    const appointment = await Appointment.findOneAndDelete({
      _id: req.params.id,
      user: req.user.id
    });
    if (!appointment) {
      return res.status(404).json({ message: 'Appointment not found' });
    }
    res.json({ message: 'Appointment deleted' });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

module.exports = router;
