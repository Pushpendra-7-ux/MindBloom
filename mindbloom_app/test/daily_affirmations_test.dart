import 'package:flutter_test/flutter_test.dart';
import 'package:mindbloom_app/config/daily_affirmations.dart';

void main() {
  group('DailyAffirmations', () {
    test('getTodayAffirmation returns a non-empty map', () {
      final affirmation = DailyAffirmations.getTodayAffirmation();
      expect(affirmation, isNotEmpty);
      expect(affirmation['text'], isNotNull);
      expect(affirmation['text']!.isNotEmpty, isTrue);
      expect(affirmation['category'], isNotNull);
    });

    test('getAll returns all affirmations', () {
      final all = DailyAffirmations.getAll();
      expect(all.length, equals(DailyAffirmations.totalAffirmations));
      expect(all.length, greaterThanOrEqualTo(30));
    });

    test('totalAffirmations matches list length', () {
      expect(DailyAffirmations.totalAffirmations, equals(DailyAffirmations.getAll().length));
    });

    test('categories list is not empty', () {
      expect(DailyAffirmations.categories, isNotEmpty);
      expect(DailyAffirmations.categories.length, equals(6));
    });

    test('getByCategory returns only matching affirmations', () {
      for (final category in DailyAffirmations.categories) {
        final filtered = DailyAffirmations.getByCategory(category);
        expect(filtered, isNotEmpty, reason: '$category should have affirmations');
        for (final aff in filtered) {
          expect(aff['category'], equals(category));
        }
      }
    });

    test('getByCategory with unknown category returns empty list', () {
      final result = DailyAffirmations.getByCategory('NonExistent');
      expect(result, isEmpty);
    });

    test('every affirmation has a valid category', () {
      final all = DailyAffirmations.getAll();
      for (final aff in all) {
        expect(DailyAffirmations.categories, contains(aff['category']),
            reason: 'Affirmation "${aff['text']}" has invalid category "${aff['category']}"');
      }
    });

    test('each category has 5 affirmations', () {
      for (final category in DailyAffirmations.categories) {
        final count = DailyAffirmations.getByCategory(category).length;
        expect(count, equals(5), reason: '$category should have exactly 5 affirmations');
      }
    });

    test('getTodayAffirmation is deterministic within the same day', () {
      final first = DailyAffirmations.getTodayAffirmation();
      final second = DailyAffirmations.getTodayAffirmation();
      expect(first['text'], equals(second['text']));
      expect(first['category'], equals(second['category']));
    });
  });
}
