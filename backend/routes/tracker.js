const express = require('express');
const Tracker = require('../models/Tracker');
const auth = require('../middleware/auth');

const router = express.Router();

// POST /api/tracker
router.post('/', auth, async (req, res) => {
  try {
    const { date, habits, goals, notes } = req.body;
    const trackDate = date ? new Date(date) : new Date();
    trackDate.setHours(0, 0, 0, 0);

    // Upsert - update if exists for same day, create if not
    const tracker = await Tracker.findOneAndUpdate(
      { user: req.user.id, date: trackDate },
      { habits, goals, notes },
      { new: true, upsert: true }
    );

    res.json({ message: 'Tracker updated', tracker });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// GET /api/tracker
router.get('/', auth, async (req, res) => {
  try {
    const { days = 7 } = req.query;
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - parseInt(days));
    startDate.setHours(0, 0, 0, 0);

    const trackers = await Tracker.find({
      user: req.user.id,
      date: { $gte: startDate }
    }).sort({ date: -1 });

    res.json({ trackers });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// GET /api/tracker/today
router.get('/today', auth, async (req, res) => {
  try {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    let tracker = await Tracker.findOne({ user: req.user.id, date: today });
    
    if (!tracker) {
      tracker = new Tracker({
        user: req.user.id,
        date: today,
        habits: {},
        goals: [],
        notes: ''
      });
      await tracker.save();
    }

    res.json({ tracker });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

module.exports = router;
