import 'package:flutter_test/flutter_test.dart';
import 'package:mindbloom_app/models/mood_analytics_model.dart';
import 'package:mindbloom_app/models/mood_model.dart';
import 'package:mindbloom_app/providers/mood_provider.dart';

void main() {
  group('MoodAnalytics Unit Tests', () {
    test('calculateAnalytics returns default empty state when history is empty', () {
      final notifier = MoodNotifier();
      final analytics = notifier.calculateAnalytics(days: 30);

      expect(analytics.totalLogs, equals(0));
      expect(analytics.averageScore, equals(0.0));
      expect(analytics.positiveCount, equals(0));
      expect(analytics.neutralCount, equals(0));
      expect(analytics.negativeCount, equals(0));
      expect(analytics.positivePercentage, equals(0.0));
      expect(analytics.streakDays, equals(0));
      expect(analytics.topFeelings.isEmpty, isTrue);
      expect(analytics.summaryLabel, equals('No Logs Yet'));
    });

    test('calculateAnalytics correctly evaluates average score and percentage distribution', () {
      final notifier = MoodNotifier();
      final now = DateTime.now();

      final logs = [
        MoodLog(moodScore: 9, emoji: '🤩', feelings: ['Grateful', 'Energetic'], createdAt: now),
        MoodLog(moodScore: 8, emoji: '😊', feelings: ['Grateful', 'Calm'], createdAt: now.subtract(const Duration(days: 1))),
        MoodLog(moodScore: 5, emoji: '😐', feelings: ['Tired'], createdAt: now.subtract(const Duration(days: 2))),
        MoodLog(moodScore: 2, emoji: '😫', feelings: ['Anxious', 'Tired'], createdAt: now.subtract(const Duration(days: 3))),
      ];

      notifier.state = notifier.state.copyWith(history: logs);
      final analytics = notifier.calculateAnalytics(days: 30);

      expect(analytics.totalLogs, equals(4));
      // (9 + 8 + 5 + 2) / 4 = 24 / 4 = 6.0
      expect(analytics.averageScore, equals(6.0));
      expect(analytics.positiveCount, equals(2)); // 9, 8
      expect(analytics.neutralCount, equals(1));  // 5
      expect(analytics.negativeCount, equals(1)); // 2
      expect(analytics.positivePercentage, equals(50.0));
      expect(analytics.neutralPercentage, equals(25.0));
      expect(analytics.negativePercentage, equals(25.0));
      expect(analytics.summaryLabel, equals('Generally Balanced 😌'));
    });

    test('calculateAnalytics respects time period filter (days parameter)', () {
      final notifier = MoodNotifier();
      final now = DateTime.now();

      final logs = [
        MoodLog(moodScore: 10, emoji: '🤩', createdAt: now.subtract(const Duration(days: 2))),
        MoodLog(moodScore: 4, emoji: '😐', createdAt: now.subtract(const Duration(days: 12))),
        MoodLog(moodScore: 2, emoji: '😔', createdAt: now.subtract(const Duration(days: 40))),
      ];

      notifier.state = notifier.state.copyWith(history: logs);

      final analytics7d = notifier.calculateAnalytics(days: 7);
      expect(analytics7d.totalLogs, equals(1));
      expect(analytics7d.averageScore, equals(10.0));

      final analytics30d = notifier.calculateAnalytics(days: 30);
      expect(analytics30d.totalLogs, equals(2));
      expect(analytics30d.averageScore, equals(7.0));

      final analyticsAll = notifier.calculateAnalytics(days: 0);
      expect(analyticsAll.totalLogs, equals(3));
    });

    test('calculateAnalytics aggregates and ranks top feeling tags correctly', () {
      final notifier = MoodNotifier();
      final now = DateTime.now();

      final logs = [
        MoodLog(moodScore: 8, emoji: '😊', feelings: ['Joyful', 'Peaceful', 'Grateful'], createdAt: now),
        MoodLog(moodScore: 9, emoji: '🤩', feelings: ['Joyful', 'Grateful'], createdAt: now.subtract(const Duration(days: 1))),
        MoodLog(moodScore: 7, emoji: '😌', feelings: ['Peaceful', 'Grateful'], createdAt: now.subtract(const Duration(days: 2))),
      ];

      notifier.state = notifier.state.copyWith(history: logs);
      final analytics = notifier.calculateAnalytics(days: 30);

      expect(analytics.topFeelings['Grateful'], equals(3));
      expect(analytics.topFeelings['Joyful'], equals(2));
      expect(analytics.topFeelings['Peaceful'], equals(2));
    });

    test('calculateAnalytics computes active checkin streak days accurately', () {
      final notifier = MoodNotifier();
      final now = DateTime.now();

      final logs = [
        MoodLog(moodScore: 8, emoji: '😊', createdAt: now),
        MoodLog(moodScore: 7, emoji: '😌', createdAt: now.subtract(const Duration(days: 1))),
        MoodLog(moodScore: 9, emoji: '🤩', createdAt: now.subtract(const Duration(days: 2))),
      ];

      notifier.state = notifier.state.copyWith(history: logs);
      final analytics = notifier.calculateAnalytics(days: 30);

      expect(analytics.streakDays, equals(3));
    });
  });
}
