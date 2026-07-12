import 'dart:math';

/// A helper class providing daily and shuffled gratitude prompts to inspire journaling.
class GratitudePrompts {
  GratitudePrompts._();

  static const List<String> _prompts = [
    'A friend or family member who made you smile recently.',
    'A small win or achievement you had this week.',
    'A favorite song, movie, or book that brings you joy.',
    'A comfortable spot in your home where you feel relaxed.',
    'A challenge you faced and how it helped you grow.',
    'A delicious meal or treat you enjoyed recently.',
    'A mistake you made that taught you a valuable lesson.',
    'A hobby, activity, or creative outlet that you love.',
    'A kind word or compliment someone gave you recently.',
    'A natural sight (sunrise, trees, rain) that you appreciate.',
    'A technology or tool that makes your life easier.',
    'A time when you felt proud of yourself.',
    'A teacher, mentor, or colleague who inspired you.',
    'A simple pleasure (warm tea, soft blanket, hot shower).',
    'A dream or goal you are excited to pursue.',
    'A personality trait of yours that you value.',
  ];

  /// Returns the prompt for today based on the day of the year.
  static String getTodayPrompt() {
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    return _prompts[dayOfYear % _prompts.length];
  }

  /// Returns a random prompt different from the current one.
  static String getRandomPrompt(String currentPrompt) {
    if (_prompts.length <= 1) return _prompts.first;
    
    final random = Random();
    String newPrompt;
    do {
      newPrompt = _prompts[random.nextInt(_prompts.length)];
    } while (newPrompt == currentPrompt);

    return newPrompt;
  }

  /// Returns the total list of available prompts.
  static List<String> get allPrompts => _prompts;
}
