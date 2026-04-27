const mongoose = require('mongoose');
require('dotenv').config();
const User = require('./models/User');
const MoodLog = require('./models/MoodLog');

async function seedData() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ MongoDB Connected');

    // Find the latest authenticated user to seed data for
    const user = await User.findOne().sort({ createdAt: -1 });
    
    if (!user) {
      console.log('❌ No user found. Please sign up in the app first.');
      process.exit(1);
    }

    console.log(`👤 Found user: ${user.name}`);

    // Clear existing mock data if necessary
    await MoodLog.deleteMany({ user: user._id });
    console.log('🗑️  Cleared existing mood logs for user');

    const today = new Date();
    const feelingsPool = [['tired', 'stressed'], ['calm', 'grateful'], ['happy', 'energetic'], ['sad', 'anxious'], ['hopeful', 'motivated']];
    const activitiesPool = [['work', 'exercise'], ['socializing', 'reading'], ['gaming', 'music'], ['socializing', 'journaling']];

    // Create 7 logs for the past 7 days
    for (let i = 6; i >= 0; i--) {
      const date = new Date(today);
      date.setDate(today.getDate() - i);
      
      // Randomize mood slightly but keep it somewhat realistic (trend upward or downward)
      const baseMood = 5 + Math.floor(Math.random() * 4); // Random mood between 5 and 8
      
      const log = new MoodLog({
        user: user._id,
        moodScore: baseMood,
        emoji: baseMood > 7 ? '😄' : baseMood > 5 ? '🙂' : '😐',
        feelings: feelingsPool[Math.floor(Math.random() * feelingsPool.length)],
        activities: activitiesPool[Math.floor(Math.random() * activitiesPool.length)],
        journal: `Test journal entry for day ${7 - i}`,
        sleepHours: 6 + Math.floor(Math.random() * 3),
        createdAt: date
      });

      await log.save();
    }

    console.log('🌱 Successfully seeded 7 days of mood data!');
    
    // Update streak and wellness score
    user.streak.current = 7;
    user.streak.longest = 7;
    user.streak.lastCheckIn = today;
    user.wellnessScore = 75; // Dummy positive score
    
    await user.save();
    console.log('🔥 Updated user streak and wellness score!');

    process.exit(0);
  } catch (err) {
    console.error('❌ Error seeding data:', err);
    process.exit(1);
  }
}

seedData();
