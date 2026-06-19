import 'package:flutter_test/flutter_test.dart';
import 'package:mindbloom_app/config/daily_quotes.dart';

void main() {
  group('DailyQuotes Tests', () {
    test('totalQuotes should return positive number of quotes', () {
      expect(DailyQuotes.totalQuotes, greaterThan(0));
    });

    test('getTodayQuote returns a quote with non-empty text and author', () {
      final quote = DailyQuotes.getTodayQuote();
      expect(quote, isNotNull);
      expect(quote['text'], isNotEmpty);
      expect(quote['author'], isNotEmpty);
    });

    test('getRandomQuote returns a quote with non-empty text and author', () {
      final quote = DailyQuotes.getRandomQuote();
      expect(quote, isNotNull);
      expect(quote['text'], isNotEmpty);
      expect(quote['author'], isNotEmpty);
    });
  });
}
