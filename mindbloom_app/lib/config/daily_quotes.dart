/// A curated collection of daily motivational quotes for mental wellness.
///
/// Quotes are organized by wellness themes and can be retrieved
/// based on the current day for a rotating daily experience.
class DailyQuotes {
  DailyQuotes._();

  static const List<Map<String, String>> _quotes = [
    {
      'text': 'You don\'t have to control your thoughts. You just have to stop letting them control you.',
      'author': 'Dan Millman',
    },
    {
      'text': 'Self-care is not selfish. You cannot serve from an empty vessel.',
      'author': 'Eleanor Brownn',
    },
    {
      'text': 'The greatest glory in living lies not in never falling, but in rising every time we fall.',
      'author': 'Nelson Mandela',
    },
    {
      'text': 'Happiness can be found even in the darkest of times, if one only remembers to turn on the light.',
      'author': 'Albus Dumbledore',
    },
    {
      'text': 'You are not your illness. You have a name, a history, a personality. Staying yourself is part of the battle.',
      'author': 'Julian Seifter',
    },
    {
      'text': 'There is hope, even when your brain tells you there isn\'t.',
      'author': 'John Green',
    },
    {
      'text': 'Mental health is not a destination, but a process. It\'s about how you drive, not where you\'re going.',
      'author': 'Noam Shpancer',
    },
    {
      'text': 'You are allowed to be both a masterpiece and a work in progress simultaneously.',
      'author': 'Sophia Bush',
    },
    {
      'text': 'Almost everything will work again if you unplug it for a few minutes, including you.',
      'author': 'Anne Lamott',
    },
    {
      'text': 'What mental health needs is more sunlight, more candor, and more unashamed conversation.',
      'author': 'Glenn Close',
    },
    {
      'text': 'Not until we are lost do we begin to understand ourselves.',
      'author': 'Henry David Thoreau',
    },
    {
      'text': 'The only journey is the one within.',
      'author': 'Rainer Maria Rilke',
    },
    {
      'text': 'Be patient with yourself. Nothing in nature blooms all year.',
      'author': 'Karen Salmansohn',
    },
    {
      'text': 'You, yourself, as much as anybody in the entire universe, deserve your love and affection.',
      'author': 'Buddha',
    },
    {
      'text': 'In the middle of difficulty lies opportunity.',
      'author': 'Albert Einstein',
    },
    {
      'text': 'Your present circumstances don\'t determine where you can go; they merely determine where you start.',
      'author': 'Nido Qubein',
    },
    {
      'text': 'Healing takes courage, and we all have courage, even if we have to dig a little to find it.',
      'author': 'Tori Amos',
    },
    {
      'text': 'The wound is the place where the Light enters you.',
      'author': 'Rumi',
    },
    {
      'text': 'Sometimes the people around you won\'t understand your journey. They don\'t need to, it\'s not for them.',
      'author': 'Joubert Botha',
    },
    {
      'text': 'Start where you are. Use what you have. Do what you can.',
      'author': 'Arthur Ashe',
    },
    {
      'text': 'Breathe. Let go. And remind yourself that this very moment is the only one you know you have for sure.',
      'author': 'Oprah Winfrey',
    },
    {
      'text': 'Owning our story and loving ourselves through that process is the bravest thing we\'ll ever do.',
      'author': 'Brené Brown',
    },
    {
      'text': 'It is during our darkest moments that we must focus to see the light.',
      'author': 'Aristotle',
    },
    {
      'text': 'You don\'t have to be positive all the time. It\'s perfectly okay to feel sad, angry, or anxious.',
      'author': 'Lori Deschene',
    },
    {
      'text': 'One small crack does not mean that you are broken; it means that you were put to the test and you didn\'t fall apart.',
      'author': 'Linda Poindexter',
    },
    {
      'text': 'Rest and self-care are so important. When you take time to replenish your spirit, it allows you to serve from the overflow.',
      'author': 'Eleanor Brownn',
    },
    {
      'text': 'Promise me you\'ll always remember: you\'re braver than you believe, stronger than you seem, and smarter than you think.',
      'author': 'A.A. Milne',
    },
    {
      'text': 'The strongest people are not those who show strength in front of us, but those who win battles we know nothing about.',
      'author': 'Jonathan Harnisch',
    },
    {
      'text': 'Your mental health is a priority. Your happiness is essential. Your self-care is a necessity.',
      'author': 'Unknown',
    },
    {
      'text': 'Every day begins with an act of courage and hope: getting out of bed.',
      'author': 'Mason Cooley',
    },
    {
      'text': 'Recovery is not one and done. It is a lifelong journey that takes place one day, one step at a time.',
      'author': 'Unknown',
    },
  ];

  /// Returns the quote for today based on the day of the year.
  /// Rotates through the collection so each day shows a different quote.
  static Map<String, String> getTodayQuote() {
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    return _quotes[dayOfYear % _quotes.length];
  }

  /// Returns a random quote from the collection.
  static Map<String, String> getRandomQuote() {
    final index = DateTime.now().millisecondsSinceEpoch % _quotes.length;
    return _quotes[index];
  }

  /// Returns the total number of available quotes.
  static int get totalQuotes => _quotes.length;
}
