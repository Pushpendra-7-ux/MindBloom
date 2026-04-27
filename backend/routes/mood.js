const express = require('express');
const MoodLog = require('../models/MoodLog');
const User = require('../models/User');
const auth = require('../middleware/auth');

const router = express.Router();

// POST /api/mood/checkin
router.post('/checkin', auth, async (req, res) => {
  try {
    const { moodScore, emoji, feelings, activities, journal, sleepHours, waterIntake, exerciseMinutes } = req.body;

    const moodLog = new MoodLog({
      user: req.user.id,
      moodScore,
      emoji,
      feelings: feelings || [],
      activities: activities || [],
      journal: journal || '',
      sleepHours: sleepHours || 0,
      waterIntake: waterIntake || 0,
      exerciseMinutes: exerciseMinutes || 0
    });

    await moodLog.save();

    // Update user streak
    const user = await User.findById(req.user.id);
    const now = new Date();
    const lastCheckIn = user.streak.lastCheckIn;
    
    if (lastCheckIn) {
      const diffHours = (now - new Date(lastCheckIn)) / (1000 * 60 * 60);
      if (diffHours <= 48) {
        user.streak.current += 1;
      } else {
        user.streak.current = 1;
      }
    } else {
      user.streak.current = 1;
    }

    if (user.streak.current > user.streak.longest) {
      user.streak.longest = user.streak.current;
    }
    user.streak.lastCheckIn = now;

    // Calculate wellness score based on recent moods
    const recentLogs = await MoodLog.find({ user: req.user.id })
      .sort({ createdAt: -1 })
      .limit(7);
    
    if (recentLogs.length > 0) {
      const avgMood = recentLogs.reduce((sum, log) => sum + log.moodScore, 0) / recentLogs.length;
      user.wellnessScore = Math.round(avgMood * 10);
    }

    await user.save();

    res.status(201).json({
      message: 'Mood logged successfully',
      moodLog,
      streak: user.streak,
      wellnessScore: user.wellnessScore
    });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// GET /api/mood/history
router.get('/history', auth, async (req, res) => {
  try {
    const { days = 30, limit = 50 } = req.query;
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - parseInt(days));

    const logs = await MoodLog.find({
      user: req.user.id,
      createdAt: { $gte: startDate }
    })
    .sort({ createdAt: -1 })
    .limit(parseInt(limit));

    res.json({ logs });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// GET /api/mood/weekly
router.get('/weekly', auth, async (req, res) => {
  try {
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - 7);

    const logs = await MoodLog.find({
      user: req.user.id,
      createdAt: { $gte: startDate }
    }).sort({ createdAt: 1 });

    const weeklyData = [];
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    
    for (let i = 6; i >= 0; i--) {
      const date = new Date();
      date.setDate(date.getDate() - i);
      const dayLogs = logs.filter(log => {
        const logDate = new Date(log.createdAt);
        return logDate.toDateString() === date.toDateString();
      });
      
      weeklyData.push({
        day: days[date.getDay()],
        date: date.toISOString().split('T')[0],
        avgMood: dayLogs.length > 0 
          ? Math.round(dayLogs.reduce((s, l) => s + l.moodScore, 0) / dayLogs.length * 10) / 10
          : null,
        count: dayLogs.length
      });
    }

    res.json({ weeklyData });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// GET /api/mood/latest
router.get('/latest', auth, async (req, res) => {
  try {
    const latest = await MoodLog.findOne({ user: req.user.id })
      .sort({ createdAt: -1 });
    res.json({ moodLog: latest });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

module.exports = router;
