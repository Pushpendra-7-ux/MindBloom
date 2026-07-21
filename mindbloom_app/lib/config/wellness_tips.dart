class WellnessTips {
  WellnessTips._();

  static const List<String> categories = [
    'Sleep',
    'Nutrition',
    'Exercise',
    'Mindfulness',
    'Social',
    'Digital Detox',
  ];

  static const Map<String, String> categoryIcons = {
    'Sleep': '😴',
    'Nutrition': '🥗',
    'Exercise': '🏃',
    'Mindfulness': '🧘',
    'Social': '👥',
    'Digital Detox': '📵',
  };

  static const List<Map<String, String>> tips = [
    // Sleep
    {'text': 'Keep a consistent sleep schedule — go to bed and wake up at the same time every day, even on weekends.', 'category': 'Sleep'},
    {'text': 'Avoid screens for at least 30 minutes before bedtime. Blue light disrupts melatonin production.', 'category': 'Sleep'},
    {'text': 'Keep your bedroom cool (around 18°C / 65°F) for optimal sleep quality.', 'category': 'Sleep'},
    {'text': 'Try a 4-7-8 breathing pattern before sleep: inhale 4s, hold 7s, exhale 8s.', 'category': 'Sleep'},
    {'text': 'Avoid caffeine after 2 PM — it has a half-life of 5-6 hours and can significantly impact sleep.', 'category': 'Sleep'},

    // Nutrition
    {'text': 'Drink a full glass of water first thing in the morning to kickstart your metabolism.', 'category': 'Nutrition'},
    {'text': 'Eat the rainbow — aim for at least 5 different colored fruits and vegetables each day.', 'category': 'Nutrition'},
    {'text': 'Omega-3 fatty acids (found in fish, walnuts, and flaxseed) support brain health and mood regulation.', 'category': 'Nutrition'},
    {'text': 'Eating slowly and mindfully can improve digestion and help you recognize when you\'re full.', 'category': 'Nutrition'},
    {'text': 'Dark chocolate (70%+ cacao) contains flavonoids that can boost mood and cognitive function.', 'category': 'Nutrition'},

    // Exercise
    {'text': 'Just 20 minutes of walking can reduce anxiety by up to 20%. Start with a short stroll today.', 'category': 'Exercise'},
    {'text': 'Try "exercise snacking" — short 2-3 minute bursts of movement throughout the day add up.', 'category': 'Exercise'},
    {'text': 'Stretching for 10 minutes in the morning reduces cortisol levels and improves flexibility.', 'category': 'Exercise'},
    {'text': 'Dancing for just 10 minutes releases endorphins comparable to 30 minutes of jogging.', 'category': 'Exercise'},
    {'text': 'Spending time exercising outdoors provides a double benefit — movement plus vitamin D from sunlight.', 'category': 'Exercise'},

    // Mindfulness
    {'text': 'Practice the 5-4-3-2-1 grounding technique: notice 5 things you see, 4 you touch, 3 you hear, 2 you smell, 1 you taste.', 'category': 'Mindfulness'},
    {'text': 'Even 5 minutes of meditation a day can reduce stress and improve focus within just 2 weeks.', 'category': 'Mindfulness'},
    {'text': 'Try "box breathing" during stressful moments: inhale 4s, hold 4s, exhale 4s, hold 4s.', 'category': 'Mindfulness'},
    {'text': 'Writing down 3 things you\'re grateful for each night rewires your brain toward positivity.', 'category': 'Mindfulness'},
    {'text': 'A body scan meditation — slowly focusing attention from toes to head — can relieve physical tension.', 'category': 'Mindfulness'},
    {'text': 'Labeling your emotions ("I feel anxious") activates the prefrontal cortex and reduces emotional intensity.', 'category': 'Mindfulness'},

    // Social
    {'text': 'A genuine 20-second hug releases oxytocin, reducing stress hormones and blood pressure.', 'category': 'Social'},
    {'text': 'Volunteering just 2 hours per week is linked to lower rates of depression and increased life satisfaction.', 'category': 'Social'},
    {'text': 'Make eye contact and put away your phone during conversations — it deepens connection.', 'category': 'Social'},
    {'text': 'Send a thoughtful message to someone you haven\'t spoken to in a while. Reconnection boosts mood for both people.', 'category': 'Social'},
    {'text': 'Laughing for 15 minutes a day can burn up to 40 calories and significantly boost your immune system.', 'category': 'Social'},

    // Digital Detox
    {'text': 'Turn off non-essential notifications. The average person checks their phone 96 times a day — reduce the triggers.', 'category': 'Digital Detox'},
    {'text': 'Try a "phone-free hour" after waking up. Starting the day without screens reduces morning anxiety.', 'category': 'Digital Detox'},
    {'text': 'Use the 20-20-20 rule: every 20 minutes, look at something 20 feet away for 20 seconds to reduce eye strain.', 'category': 'Digital Detox'},
    {'text': 'Designate one meal per day as a screen-free meal. It improves digestion and mindful eating.', 'category': 'Digital Detox'},
    {'text': 'Keep your phone out of the bedroom. Using an alarm clock instead improves sleep quality dramatically.', 'category': 'Digital Detox'},
  ];

  /// Total number of tips available.
  static int get totalTips => tips.length;

  /// Returns a deterministic tip for today based on the current date.
  static Map<String, String> getTodayTip() {
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    return tips[dayOfYear % tips.length];
  }

  /// Returns the tip at the given index (wrapping around if needed).
  static Map<String, String> getTipAt(int index) {
    return tips[index % tips.length];
  }

  /// Returns the emoji icon for a given category.
  static String getIcon(String category) {
    return categoryIcons[category] ?? '💡';
  }
}
