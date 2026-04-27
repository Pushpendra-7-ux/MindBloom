const express = require('express');
const auth = require('../middleware/auth');
const fetch = require('node-fetch');

const router = express.Router();

// POST /api/recommendations/generate
router.post('/generate', auth, async (req, res) => {
  try {
    const { moodScore, feelings, activities, category } = req.body;

    const prompt = `You are a mental wellness AI assistant. Based on the following user data, provide personalized wellness recommendations.

User Info:
- Mood Score: ${moodScore}/10
- Current Feelings: ${feelings ? feelings.join(', ') : 'not specified'}
- Recent Activities: ${activities ? activities.join(', ') : 'not specified'}
- User Category: ${category || 'general'}

Please provide recommendations in EXACTLY this JSON format (no markdown, no code blocks, just raw JSON):
{
  "books": [
    {"title": "Book Title", "author": "Author Name", "description": "Why this book helps", "icon": "book"},
    {"title": "Book Title", "author": "Author Name", "description": "Why this book helps", "icon": "book"},
    {"title": "Book Title", "author": "Author Name", "description": "Why this book helps", "icon": "book"}
  ],
  "physical": [
    {"title": "Activity Name", "duration": "Duration", "description": "How this helps", "icon": "fitness"},
    {"title": "Activity Name", "duration": "Duration", "description": "How this helps", "icon": "fitness"},
    {"title": "Activity Name", "duration": "Duration", "description": "How this helps", "icon": "fitness"}
  ],
  "mindSpirit": [
    {"title": "Practice Name", "duration": "Duration", "description": "Benefits", "icon": "spa"},
    {"title": "Practice Name", "duration": "Duration", "description": "Benefits", "icon": "spa"},
    {"title": "Practice Name", "duration": "Duration", "description": "Benefits", "icon": "spa"}
  ],
  "lifestyle": [
    {"title": "Habit Name", "frequency": "How often", "description": "Why it helps", "icon": "lifestyle"},
    {"title": "Habit Name", "frequency": "How often", "description": "Why it helps", "icon": "lifestyle"},
    {"title": "Habit Name", "frequency": "How often", "description": "Why it helps", "icon": "lifestyle"}
  ],
  "summary": "A brief encouraging message about their current state and path forward"
}

Make recommendations specific and actionable. Be warm and encouraging.`;

    const apiKey = process.env.GEMINI_API_KEY;
    
    if (!apiKey || apiKey === 'YOUR_GEMINI_API_KEY_HERE') {
      // Return fallback recommendations if no API key
      return res.json({
        recommendations: getFallbackRecommendations(moodScore),
        source: 'fallback'
      });
    }

    const response = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${apiKey}`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          contents: [{ parts: [{ text: prompt }] }],
          generationConfig: {
            temperature: 0.7,
            maxOutputTokens: 2048
          }
        })
      }
    );

    const data = await response.json();

    if (data.candidates && data.candidates[0]) {
      let text = data.candidates[0].content.parts[0].text;
      // Clean up markdown formatting if present
      text = text.replace(/```json\n?/g, '').replace(/```\n?/g, '').trim();
      
      try {
        const recommendations = JSON.parse(text);
        return res.json({ recommendations, source: 'gemini' });
      } catch (parseError) {
        return res.json({
          recommendations: getFallbackRecommendations(moodScore),
          source: 'fallback',
          rawAI: text
        });
      }
    }

    res.json({
      recommendations: getFallbackRecommendations(moodScore),
      source: 'fallback'
    });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

const allBooks = {
  high: [
    { title: "Atomic Habits", author: "James Clear", description: "Channel your positive energy into building systems", icon: "book" },
    { title: "Flow", author: "Mihaly Csikszentmihalyi", description: "The psychology of optimal experience", icon: "book" },
    { title: "Essentialism", author: "Greg McKeown", description: "The disciplined pursuit of less, done better", icon: "book" },
    { title: "Thinking, Fast and Slow", author: "Daniel Kahneman", description: "Learn how your brain processes good and bad days", icon: "book" },
    { title: "The 5AM Club", author: "Robin Sharma", description: "Own your morning, elevate your life", icon: "book" }
  ],
  neutral: [
    { title: "The Happiness Project", author: "Gretchen Rubin", description: "A year-long experiment in becoming happier", icon: "book" },
    { title: "Tiny Beautiful Things", author: "Cheryl Strayed", description: "Advice on love and life from Dear Sugar", icon: "book" },
    { title: "Daring Greatly", author: "Brené Brown", description: "How the courage to be vulnerable transforms everything", icon: "book" },
    { title: "Factfulness", author: "Hans Rosling", description: "Ten reasons we're wrong about the world", icon: "book" },
    { title: "Mindset", author: "Carol S. Dweck", description: "The new psychology of success", icon: "book" }
  ],
  low: [
    { title: "The Power of Now", author: "Eckhart Tolle", description: "Learn to live in the present moment and reduce anxiety", icon: "book" },
    { title: "Don't Sweat the Small Stuff", author: "Richard Carlson", description: "Learn how to keep from letting little things take over your life", icon: "book" },
    { title: "The Anxiety and Phobia Workbook", author: "Edmund Bourne", description: "Practical exercises to overcome anxiety", icon: "book" },
    { title: "Man's Search for Meaning", author: "Viktor E. Frankl", description: "Finding meaning even in the darkest of times", icon: "book" },
    { title: "Reasons to Stay Alive", author: "Matt Haig", description: "A true story of surviving depression", icon: "book" },
    { title: "The Upward Spiral", author: "Alex Korb", description: "Using neuroscience to reverse the course of depression", icon: "book" }
  ]
};

const allPhysical = {
  high: [
    { title: "Cardio Burst", duration: "20 minutes", description: "High energy workout to capitalize on your mood", icon: "fitness" },
    { title: "Dance Session", duration: "15 minutes", description: "Free movement to boost endorphins even higher", icon: "fitness" },
    { title: "HIIT Workout", duration: "15 minutes", description: "Burn quick energy and improve stamina", icon: "fitness" },
    { title: "Quick Jog", duration: "20 minutes", description: "Get outside and run off that extra enthusiasm", icon: "fitness" }
  ],
  neutral: [
    { title: "Morning Walk", duration: "20 minutes", description: "Gentle walk to boost serotonin", icon: "fitness" },
    { title: "Light Stretching", duration: "10 minutes", description: "Maintain mobility and blood flow", icon: "fitness" },
    { title: "Core Work", duration: "10 minutes", description: "Quick core stability exercises", icon: "fitness" },
    { title: "Vinyasa Flow", duration: "15 minutes", description: "A balanced yoga flow for mind and body", icon: "fitness" }
  ],
  low: [
    { title: "Yoga NIidra", duration: "15 minutes", description: "Gentle, restorative sequence for deep relaxation", icon: "fitness" },
    { title: "Nature Walk", duration: "25 minutes", description: "Walk in a green area to naturally lower cortisol", icon: "fitness" },
    { title: "Child's Pose", duration: "5 minutes", description: "Grounding stretch to release lower back tension", icon: "fitness" },
    { title: "Bed Stretching", duration: "10 minutes", description: "Soft stretches you can do without leaving your bed", icon: "fitness" }
  ]
};

const allMindSpirit = {
  high: [
    { title: "Gratitude Journaling", duration: "5 minutes", description: "Document what's making you happy today", icon: "spa" },
    { title: "Visualization", duration: "10 minutes", description: "Use this good energy to visualize your future goals", icon: "spa" },
    { title: "Affirmations", duration: "5 minutes", description: "Speak power into your already great day", icon: "spa" }
  ],
  neutral: [
    { title: "Guided Meditation", duration: "10 minutes", description: "Focus on breath and body awareness for inner calm", icon: "spa" },
    { title: "Brain Dump", duration: "5 minutes", description: "Clear your mind by writing down everything you're thinking about", icon: "spa" },
    { title: "Mindful Eating", duration: "1 meal", description: "Eat one meal with zero distractions", icon: "spa" },
    { title: "Sensory Walk", duration: "10 minutes", description: "Notice 5 things you can see, 4 you can touch...", icon: "spa" }
  ],
  low: [
    { title: "Deep Breathing", duration: "5 minutes", description: "4-7-8 breathing technique for instant heartbeat regulation", icon: "spa" },
    { title: "Body Scan", duration: "10 minutes", description: "Relax muscles one by one to release physical stress", icon: "spa" },
    { title: "Self-Compassion", duration: "5 minutes", description: "Write yourself a letter of forgiveness and patience", icon: "spa" },
    { title: "Square Breathing", duration: "3 minutes", description: "Inhale 4, hold 4, exhale 4, hold 4", icon: "spa" }
  ]
};

const allLifestyle = {
  high: [
    { title: "Connect with Others", frequency: "Today", description: "Share your positive energy with a friend", icon: "lifestyle" },
    { title: "Creative Hobby", frequency: "1 hour", description: "Use your momentum to create something new", icon: "lifestyle" },
    { title: "Learn a Skill", frequency: "20 mins", description: "Read an article or watch a tutorial on something new", icon: "lifestyle" }
  ],
  neutral: [
    { title: "Sleep Routine", frequency: "Every night", description: "Establish a calming bedtime ritual for better rest", icon: "lifestyle" },
    { title: "Hydration Goal", frequency: "Daily", description: "Aim for 8 glasses of water to keep your brain clear", icon: "lifestyle" },
    { title: "Tidy Space", frequency: "10 mins", description: "Clean your immediate environment", icon: "lifestyle" }
  ],
  low: [
    { title: "Digital Detox", frequency: "1 hour daily", description: "Disconnect from screens before bed to reduce mental fatigue", icon: "lifestyle" },
    { title: "Herbal Tea Ritual", frequency: "Evening", description: "Chamomile or peppermint tea to soothe nerves", icon: "lifestyle" },
    { title: "Warm Bath/Shower", frequency: "Tonight", description: "Wash the day away and physically relax tense muscles", icon: "lifestyle" },
    { title: "Say No", frequency: "Today", description: "Cancel one non-essential obligation to protect your peace", icon: "lifestyle" }
  ]
};

// Helper function to pick N random items
function getRandomItems(array, n) {
  const shuffled = [...array].sort(() => 0.5 - Math.random());
  return shuffled.slice(0, n);
}

function getFallbackRecommendations(moodScore, feelings = []) {
  const score = parseInt(moodScore) || 5;
  const isStressed = feelings.includes('stressed') || feelings.includes('anxious') || score <= 4;
  const isHappy = feelings.includes('happy') || feelings.includes('energetic') || score >= 8;

  let category = 'neutral';
  let summary = "";

  if (isStressed) {
    category = 'low';
    summary = "It sounds like you're carrying a lot right now. Remember to be gentle with yourself. These recommendations focus on grounding you and reducing stress.";
  } else if (isHappy) {
    category = 'high';
    summary = "You're in a great space! Keep up the positive momentum. These recommendations are designed to help you harness this energy and build lasting habits.";
  } else {
    category = 'neutral';
    summary = "You're doing okay! It's a balanced day. These recommendations can help you maintain your equilibrium and gently improve your mental wellness.";
  }

  return {
    books: getRandomItems(allBooks[category], 3),
    physical: getRandomItems(allPhysical[category], 3),
    mindSpirit: getRandomItems(allMindSpirit[category], 3),
    lifestyle: getRandomItems(allLifestyle[category], 3),
    summary: summary
  };
}

module.exports = router;
