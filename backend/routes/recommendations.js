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
        recommendations: getFallbackRecommendations(moodScore, feelings, activities, category),
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
          recommendations: getFallbackRecommendations(moodScore, feelings, activities, category),
          source: 'fallback',
          rawAI: text
        });
      }
    }

    res.json({
      recommendations: getFallbackRecommendations(moodScore, feelings, activities, category),
      source: 'fallback'
    });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Richer, multi-dimensional database of recommendations
const allBooks = {
  high: [
    { title: "Atomic Habits", author: "James Clear", description: "Channel your positive energy into building systems.", icon: "book" },
    { title: "Flow", author: "Mihaly Csikszentmihalyi", description: "The psychology of optimal experience.", icon: "book" },
    { title: "Essentialism", author: "Greg McKeown", description: "The disciplined pursuit of less, done better.", icon: "book" },
    { title: "Thinking, Fast and Slow", author: "Daniel Kahneman", description: "Learn how your brain processes decisions and thoughts.", icon: "book" },
    { title: "The 5AM Club", author: "Robin Sharma", description: "Own your morning, elevate your life.", icon: "book" },
    { title: "Grit: The Power of Passion", author: "Angela Duckworth", description: "Learn why passion and resilience beat talent.", icon: "book" },
    { title: "Drive", author: "Daniel H. Pink", description: "Understand what truly motivates you to excel.", icon: "book" },
    { title: "The Power of Habit", author: "Charles Duhigg", description: "The science of habit formation and change.", icon: "book" }
  ],
  neutral: [
    { title: "The Happiness Project", author: "Gretchen Rubin", description: "A year-long experiment in becoming happier.", icon: "book" },
    { title: "Tiny Beautiful Things", author: "Cheryl Strayed", description: "Advice on love and life from Dear Sugar.", icon: "book" },
    { title: "Daring Greatly", author: "Brené Brown", description: "How the courage to be vulnerable transforms everything.", icon: "book" },
    { title: "Factfulness", author: "Hans Rosling", description: "Ten reasons we're wrong about the world.", icon: "book" },
    { title: "Mindset", author: "Carol S. Dweck", description: "The new psychology of success and growth.", icon: "book" },
    { title: "Big Magic", author: "Elizabeth Gilbert", description: "Creative living beyond fear.", icon: "book" },
    { title: "Quiet", author: "Susan Cain", description: "The power of introverts in a world that can't stop talking.", icon: "book" },
    { title: "The Art of Happiness", author: "Dalai Lama", description: "A handbook for living with mindfulness and peace.", icon: "book" }
  ],
  low: [
    { title: "The Power of Now", author: "Eckhart Tolle", description: "Learn to live in the present moment and reduce anxiety.", icon: "book" },
    { title: "Don't Sweat the Small Stuff", author: "Richard Carlson", description: "Keep from letting little things take over your life.", icon: "book" },
    { title: "The Anxiety and Phobia Workbook", author: "Edmund Bourne", description: "Practical exercises to overcome anxiety.", icon: "book" },
    { title: "Man's Search for Meaning", author: "Viktor E. Frankl", description: "Finding meaning even in the darkest of times.", icon: "book" },
    { title: "Reasons to Stay Alive", author: "Matt Haig", description: "A true story of surviving depression.", icon: "book" },
    { title: "The Upward Spiral", author: "Alex Korb", description: "Using neuroscience to reverse the course of depression.", icon: "book" },
    { title: "Feeling Good", author: "David D. Burns", description: "The new mood therapy for cognitive behavior.", icon: "book" },
    { title: "Self-Compassion", author: "Kristin Neff", description: "The proven power of being kind to yourself.", icon: "book" }
  ]
};

const allPhysical = {
  high: [
    { title: "Cardio Burst", duration: "20 minutes", description: "High energy workout to capitalize on your mood.", icon: "fitness" },
    { title: "Dance Session", duration: "15 minutes", description: "Free movement to boost endorphins even higher.", icon: "fitness" },
    { title: "HIIT Workout", duration: "15 minutes", description: "Burn quick energy and improve stamina.", icon: "fitness" },
    { title: "Quick Jog", duration: "20 minutes", description: "Get outside and run off that extra enthusiasm.", icon: "fitness" },
    { title: "Power Yoga", duration: "25 minutes", description: "Dynamic yoga poses for strength and flexibility.", icon: "fitness" }
  ],
  neutral: [
    { title: "Morning Walk", duration: "20 minutes", description: "Gentle walk to boost serotonin.", icon: "fitness" },
    { title: "Light Stretching", duration: "10 minutes", description: "Maintain mobility and blood flow.", icon: "fitness" },
    { title: "Core Work", duration: "10 minutes", description: "Quick core stability exercises.", icon: "fitness" },
    { title: "Vinyasa Flow", duration: "15 minutes", description: "A balanced yoga flow for mind and body.", icon: "fitness" },
    { title: "Brisk Walk", duration: "30 minutes", description: "Elevate your heart rate gently.", icon: "fitness" }
  ],
  low: [
    { title: "Yoga Nidra", duration: "15 minutes", description: "Gentle, restorative sequence for deep relaxation.", icon: "fitness" },
    { title: "Nature Walk", duration: "25 minutes", description: "Walk in a green area to naturally lower cortisol.", icon: "fitness" },
    { title: "Child's Pose & Cat-Cow", duration: "5 minutes", description: "Grounding stretch to release spine and back tension.", icon: "fitness" },
    { title: "Bed Stretching", duration: "10 minutes", description: "Soft stretches you can do without leaving your bed.", icon: "fitness" },
    { title: "Gentle Joint Rotation", duration: "8 minutes", description: "Slow movements to relieve joint stiffness.", icon: "fitness" }
  ]
};

const allMindSpirit = {
  high: [
    { title: "Gratitude Journaling", duration: "5 minutes", description: "Document what's making you happy today.", icon: "spa" },
    { title: "Future Self Visualization", duration: "10 minutes", description: "Use this good energy to visualize your future goals.", icon: "spa" },
    { title: "Positive Affirmations", duration: "5 minutes", description: "Speak power into your already great day.", icon: "spa" },
    { title: "Loving-Kindness Meditation", duration: "10 minutes", description: "Extend your positive vibes to loved ones and the world.", icon: "spa" }
  ],
  neutral: [
    { title: "Guided Meditation", duration: "10 minutes", description: "Focus on breath and body awareness for inner calm.", icon: "spa" },
    { title: "Brain Dump", duration: "5 minutes", description: "Clear your mind by writing down everything you're thinking.", icon: "spa" },
    { title: "Mindful Eating", duration: "1 meal", description: "Eat one meal with zero distractions.", icon: "spa" },
    { title: "5-4-3-2-1 Sensory Walk", duration: "10 minutes", description: "Notice 5 things you can see, 4 you can touch...", icon: "spa" }
  ],
  low: [
    { title: "Deep Breathing (4-7-8)", duration: "5 minutes", description: "Breathing technique for instant heartbeat regulation.", icon: "spa" },
    { title: "Progressive Muscle Relaxation", duration: "12 minutes", description: "Relax muscles one by one to release physical stress.", icon: "spa" },
    { title: "Self-Compassion Pause", duration: "5 minutes", description: "Acknowledge difficulty and offer yourself kindness.", icon: "spa" },
    { title: "Square Breathing", duration: "3 minutes", description: "Inhale 4, hold 4, exhale 4, hold 4.", icon: "spa" }
  ]
};

const allLifestyle = {
  high: [
    { title: "Connect with a Friend", frequency: "Today", description: "Share your positive energy with a friend.", icon: "lifestyle" },
    { title: "Creative Hobby", frequency: "1 hour", description: "Use your momentum to create something new.", icon: "lifestyle" },
    { title: "Learn a Skill", frequency: "20 mins", description: "Read an article or watch a tutorial on something new.", icon: "lifestyle" },
    { title: "Acts of Kindness", frequency: "Today", description: "Do something nice for someone unexpectedly.", icon: "lifestyle" }
  ],
  neutral: [
    { title: "Sleep Routine Check", frequency: "Every night", description: "Establish a calming bedtime ritual for better rest.", icon: "lifestyle" },
    { title: "Hydration Goal", frequency: "Daily", description: "Aim for 8 glasses of water to keep your brain clear.", icon: "lifestyle" },
    { title: "Tidy Space", frequency: "10 mins", description: "Clean your immediate environment for mental clarity.", icon: "lifestyle" },
    { title: "Screen Break", frequency: "Every 2 hours", description: "Look away from screens for 5 minutes.", icon: "lifestyle" }
  ],
  low: [
    { title: "Digital Detox", frequency: "1 hour daily", description: "Disconnect from screens before bed to reduce mental fatigue.", icon: "lifestyle" },
    { title: "Herbal Tea Ritual", frequency: "Evening", description: "Chamomile or peppermint tea to soothe nerves.", icon: "lifestyle" },
    { title: "Warm Bath/Shower", frequency: "Tonight", description: "Wash the day away and physically relax tense muscles.", icon: "lifestyle" },
    { title: "Say No to Obligations", frequency: "Today", description: "Cancel one non-essential task to protect your peace.", icon: "lifestyle" }
  ]
};

// Feeling-specific target recommendations
const feelingSpecificRecs = {
  anxious: {
    books: [{ title: "First, We Make the Beast Beautiful", author: "Sarah Wilson", description: "A unique, comforting perspective on living with anxiety.", icon: "book" }],
    physical: [{ title: "Slow Flow Stretch", duration: "10 minutes", description: "Calm your nervous system with gentle movement.", icon: "fitness" }],
    mindSpirit: [{ title: "Grounding (5-4-3-2-1)", duration: "5 minutes", description: "Identify objects around you to pull yourself out of anxious loops.", icon: "spa" }],
    lifestyle: [{ title: "Warm Decaf Drink", frequency: "As needed", description: "Avoid caffeine; sip herbal tea or warm water to stay centered.", icon: "lifestyle" }]
  },
  stressed: {
    books: [{ title: "Burnout: The Secret to Unlocking the Stress Cycle", author: "Emily Nagoski", description: "Identify stress and how to complete the physical cycle.", icon: "book" }],
    physical: [{ title: "Stress-Relief Jog", duration: "15 minutes", description: "Shake off cortisol and adrenaline through physical exertion.", icon: "fitness" }],
    mindSpirit: [{ title: "Vagus Nerve Stimulation", duration: "3 minutes", description: "Deep belly breathing to trigger the relaxation response.", icon: "spa" }],
    lifestyle: [{ title: "Offload Tasks", frequency: "Today", description: "Delegate or postpone at least two minor tasks from your to-do list.", icon: "lifestyle" }]
  },
  tired: {
    books: [{ title: "Why We Sleep", author: "Matthew Walker", description: "Unlocking the immense biological power of sleep and dreams.", icon: "book" }],
    physical: [{ title: "Lie on the Floor with Legs Up the Wall", duration: "10 minutes", description: "Restores circulation and relieves lower body fatigue.", icon: "fitness" }],
    mindSpirit: [{ title: "Guided Sleep Meditation", duration: "15 minutes", description: "Allow yourself to drift off or rest without expectations.", icon: "spa" }],
    lifestyle: [{ title: "Early Bedtime", frequency: "Tonight", description: "Go to bed 30-45 minutes earlier than usual.", icon: "lifestyle" }]
  },
  lonely: {
    books: [{ title: "Together: The Healing Power of Human Connection", author: "Vivek H. Murthy", description: "A warm reflection on why relationship is our greatest drug.", icon: "book" }],
    physical: [{ title: "Group Class or Gym Walk", duration: "30 minutes", description: "Simply walking in spaces where other people are active.", icon: "fitness" }],
    mindSpirit: [{ title: "Loving-Kindness Meditation", duration: "8 minutes", description: "Send wishes of safety and happiness to someone you miss.", icon: "spa" }],
    lifestyle: [{ title: "Send a Warm Text", frequency: "Today", description: "Message a friend or family member just to check in on them.", icon: "lifestyle" }]
  }
};

// Category-specific target recommendations
const categorySpecificRecs = {
  student: {
    books: [{ title: "Make It Stick: The Science of Successful Learning", author: "Peter Brown", description: "How to learn and retain information with less stress.", icon: "book" }],
    lifestyle: [{ title: "Focus Block Strategy", frequency: "25 min intervals", description: "Use Pomodoro technique to study without mental burnout.", icon: "lifestyle" }]
  },
  professional: {
    books: [{ title: "Designing Your Life", author: "Bill Burnett", description: "Build a meaningful, sustainable career using design thinking.", icon: "book" }],
    lifestyle: [{ title: "Strict Work Boundaries", frequency: "Daily", description: "Turn off work notifications after 6:00 PM.", icon: "lifestyle" }]
  },
  parent: {
    books: [{ title: "The Whole-Brain Child", author: "Daniel J. Siegel", description: "12 parenting strategies to foster emotional health.", icon: "book" }],
    lifestyle: [{ title: "Parental Time-out", frequency: "5 minutes", description: "Take a micro-break for quiet breathing alone.", icon: "lifestyle" }]
  },
  senior: {
    books: [{ title: "Successful Aging", author: "Daniel J. Levitin", description: "A neuroscientist explores longevity and cognitive health.", icon: "book" }],
    physical: [{ title: "Joint Mobility Practice", duration: "12 minutes", description: "Gentle motions to keep joints active and oiled.", icon: "fitness" }]
  }
};

// Helper function to pick N random items
function getRandomItems(array, n) {
  const shuffled = [...array].sort(() => 0.5 - Math.random());
  return shuffled.slice(0, n);
}

function getFallbackRecommendations(moodScore, feelings = [], activities = [], category = 'general') {
  const score = parseInt(moodScore) || 5;
  const safeFeelings = Array.isArray(feelings) ? feelings : [];
  const safeActivities = Array.isArray(activities) ? activities : [];

  const isLow = safeFeelings.includes('stressed') || safeFeelings.includes('anxious') || safeFeelings.includes('sad') || safeFeelings.includes('tired') || score <= 4;
  const isHigh = (safeFeelings.includes('happy') || safeFeelings.includes('energetic') || safeFeelings.includes('motivated') || score >= 8) && !isLow;

  let baseCategory = 'neutral';
  let summary = "";

  if (isLow) {
    baseCategory = 'low';
    summary = "It sounds like you're carrying a lot right now. Remember to be gentle with yourself. These recommendations focus on grounding you and reducing stress.";
  } else if (isHigh) {
    baseCategory = 'high';
    summary = "You're in a great space! Keep up the positive momentum. These recommendations are designed to help you harness this energy and build lasting habits.";
  } else {
    baseCategory = 'neutral';
    summary = "You're doing okay! It's a balanced day. These recommendations can help you maintain your equilibrium and gently improve your mental wellness.";
  }

  // Build pools initialized with base mood recommendations
  let booksPool = [...allBooks[baseCategory]];
  let physicalPool = [...allPhysical[baseCategory]];
  let mindSpiritPool = [...allMindSpirit[baseCategory]];
  let lifestylePool = [...allLifestyle[baseCategory]];

  // Inject feeling-specific recommendations
  safeFeelings.forEach(feeling => {
    const key = feeling.toLowerCase();
    if (feelingSpecificRecs[key]) {
      if (feelingSpecificRecs[key].books) booksPool.push(...feelingSpecificRecs[key].books);
      if (feelingSpecificRecs[key].physical) physicalPool.push(...feelingSpecificRecs[key].physical);
      if (feelingSpecificRecs[key].mindSpirit) mindSpiritPool.push(...feelingSpecificRecs[key].mindSpirit);
      if (feelingSpecificRecs[key].lifestyle) lifestylePool.push(...feelingSpecificRecs[key].lifestyle);
    }
  });

  // Inject category-specific recommendations
  const userCat = (category || 'general').toLowerCase();
  if (categorySpecificRecs[userCat]) {
    if (categorySpecificRecs[userCat].books) booksPool.push(...categorySpecificRecs[userCat].books);
    if (categorySpecificRecs[userCat].physical) physicalPool.push(...categorySpecificRecs[userCat].physical);
    if (categorySpecificRecs[userCat].mindSpirit) mindSpiritPool.push(...categorySpecificRecs[userCat].mindSpirit);
    if (categorySpecificRecs[userCat].lifestyle) lifestylePool.push(...categorySpecificRecs[userCat].lifestyle);
  }

  // Shuffle pools and pick 3 unique recommendations
  return {
    books: getRandomItems(booksPool, 3),
    physical: getRandomItems(physicalPool, 3),
    mindSpirit: getRandomItems(mindSpiritPool, 3),
    lifestyle: getRandomItems(lifestylePool, 3),
    summary: summary
  };
}

module.exports = router;
