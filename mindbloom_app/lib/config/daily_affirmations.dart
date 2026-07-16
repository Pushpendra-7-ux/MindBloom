/// A curated collection of daily positive affirmations for mental wellness.
///
/// Affirmations are organized by wellness categories and can be retrieved
/// based on the current day for a rotating daily experience, or filtered
/// by category for targeted self-care.
class DailyAffirmations {
  DailyAffirmations._();

  /// All available affirmation categories.
  static const List<String> categories = [
    'Self-Love',
    'Resilience',
    'Gratitude',
    'Calm',
    'Growth',
    'Confidence',
  ];

  static const List<Map<String, String>> _affirmations = [
    // Self-Love
    {
      'text': 'I am worthy of love and kindness, especially from myself.',
      'category': 'Self-Love',
    },
    {
      'text': 'I honour my own needs and give myself permission to rest.',
      'category': 'Self-Love',
    },
    {
      'text': 'I am enough, exactly as I am in this moment.',
      'category': 'Self-Love',
    },
    {
      'text': 'My self-worth is not defined by my productivity.',
      'category': 'Self-Love',
    },
    {
      'text': 'I choose to treat myself with the same compassion I give to others.',
      'category': 'Self-Love',
    },

    // Resilience
    {
      'text': 'I have survived every difficult day so far, and I will survive this one too.',
      'category': 'Resilience',
    },
    {
      'text': 'Challenges help me grow stronger and more compassionate.',
      'category': 'Resilience',
    },
    {
      'text': 'I am allowed to take things one step at a time.',
      'category': 'Resilience',
    },
    {
      'text': 'My struggles do not define me; my courage does.',
      'category': 'Resilience',
    },
    {
      'text': 'I trust myself to navigate whatever comes my way.',
      'category': 'Resilience',
    },

    // Gratitude
    {
      'text': 'I am grateful for the small moments of joy in my day.',
      'category': 'Gratitude',
    },
    {
      'text': 'There is always something to be thankful for, even on hard days.',
      'category': 'Gratitude',
    },
    {
      'text': 'I appreciate the people who bring warmth into my life.',
      'category': 'Gratitude',
    },
    {
      'text': 'Every breath is a gift, and I choose to savour it.',
      'category': 'Gratitude',
    },
    {
      'text': 'I notice and celebrate the good that already exists around me.',
      'category': 'Gratitude',
    },

    // Calm
    {
      'text': 'I release tension and welcome peace into my mind and body.',
      'category': 'Calm',
    },
    {
      'text': 'I give myself permission to slow down and just breathe.',
      'category': 'Calm',
    },
    {
      'text': 'This moment is temporary; I can ride it out with grace.',
      'category': 'Calm',
    },
    {
      'text': 'I am safe, I am grounded, and I am in control of my breath.',
      'category': 'Calm',
    },
    {
      'text': 'Peace begins with a single deep breath, and I choose it now.',
      'category': 'Calm',
    },

    // Growth
    {
      'text': 'Every day I am learning, growing, and becoming a better version of myself.',
      'category': 'Growth',
    },
    {
      'text': 'I embrace change as an opportunity for personal evolution.',
      'category': 'Growth',
    },
    {
      'text': 'My mistakes are lessons, not failures.',
      'category': 'Growth',
    },
    {
      'text': 'I am a work in progress, and that is perfectly okay.',
      'category': 'Growth',
    },
    {
      'text': 'I celebrate how far I have come, not just how far I have to go.',
      'category': 'Growth',
    },

    // Confidence
    {
      'text': 'I believe in my ability to figure things out.',
      'category': 'Confidence',
    },
    {
      'text': 'My voice matters and deserves to be heard.',
      'category': 'Confidence',
    },
    {
      'text': 'I am capable of achieving great things at my own pace.',
      'category': 'Confidence',
    },
    {
      'text': 'I trust the unique path that my life is taking.',
      'category': 'Confidence',
    },
    {
      'text': 'I radiate confidence, self-respect, and inner harmony.',
      'category': 'Confidence',
    },
  ];

  /// Returns the affirmation for today based on the day of the year.
  /// Rotates through the collection so each day shows a different affirmation.
  static Map<String, String> getTodayAffirmation() {
    final dayOfYear = DateTime.now()
        .difference(DateTime(DateTime.now().year, 1, 1))
        .inDays;
    return _affirmations[dayOfYear % _affirmations.length];
  }

  /// Returns all affirmations.
  static List<Map<String, String>> getAll() => List.unmodifiable(_affirmations);

  /// Returns affirmations filtered by [category].
  static List<Map<String, String>> getByCategory(String category) {
    return _affirmations
        .where((a) => a['category'] == category)
        .toList(growable: false);
  }

  /// Returns the total number of available affirmations.
  static int get totalAffirmations => _affirmations.length;
}
