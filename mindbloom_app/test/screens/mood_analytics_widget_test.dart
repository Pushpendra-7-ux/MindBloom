import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindbloom_app/models/mood_analytics_model.dart';
import 'package:mindbloom_app/models/mood_model.dart';
import 'package:mindbloom_app/providers/mood_provider.dart';
import 'package:mindbloom_app/screens/mood_history/mood_history_screen.dart';
import 'package:mindbloom_app/widgets/mood_analytics_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TestMoodNotifier extends MoodNotifier {
  TestMoodNotifier(MoodState initialState) {
    state = initialState;
  }

  @override
  Future<void> fetchMoodHistory({int days = 30}) async {
    // Keep test state intact without setting isLoading = true
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('MoodAnalyticsCard Widget Tests', () {
    testWidgets('renders empty state placeholder when totalLogs is 0', (tester) async {
      const emptyAnalytics = MoodAnalytics(
        totalLogs: 0,
        averageScore: 0.0,
        positiveCount: 0,
        neutralCount: 0,
        negativeCount: 0,
        streakDays: 0,
        topFeelings: {},
        filterDays: 30,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MoodAnalyticsCard(
              analytics: emptyAnalytics,
              onPeriodChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Mood Insights'), findsOneWidget);
      expect(find.text('Log your mood to unlock personalized trend analytics.'), findsOneWidget);
    });

    testWidgets('renders key metrics, distribution breakdown, and frequent feelings', (tester) async {
      const analytics = MoodAnalytics(
        totalLogs: 5,
        averageScore: 8.4,
        positiveCount: 4,
        neutralCount: 1,
        negativeCount: 0,
        streakDays: 4,
        topFeelings: {'Grateful': 3, 'Energized': 2},
        filterDays: 30,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MoodAnalyticsCard(
                analytics: analytics,
                onPeriodChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Mood Insights'), findsOneWidget);
      expect(find.text('8.4/10'), findsOneWidget);
      expect(find.text('🔥 4 days'), findsOneWidget);
      expect(find.text('📝 5'), findsOneWidget);
      expect(find.text('Mood Distribution'), findsOneWidget);
      expect(find.text('Frequent Feelings & Triggers'), findsOneWidget);
      expect(find.text('Grateful (3)'), findsOneWidget);
      expect(find.text('Energized (2)'), findsOneWidget);
    });

    testWidgets('tapping period pill triggers onPeriodChanged callback', (tester) async {
      int selectedDays = 30;

      const analytics = MoodAnalytics(
        totalLogs: 2,
        averageScore: 7.0,
        positiveCount: 1,
        neutralCount: 1,
        negativeCount: 0,
        streakDays: 1,
        topFeelings: {'Calm': 1},
        filterDays: 30,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MoodAnalyticsCard(
              analytics: analytics,
              onPeriodChanged: (days) => selectedDays = days,
            ),
          ),
        ),
      );

      await tester.tap(find.text('7D'));
      await tester.pumpAndSettle();

      expect(selectedDays, equals(7));

      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();

      expect(selectedDays, equals(0));
    });

    testWidgets('MoodHistoryScreen displays MoodAnalyticsCard and filters list on feeling tap', (tester) async {
      final now = DateTime.now();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            moodProvider.overrideWith((ref) {
              return TestMoodNotifier(
                MoodState(
                  isLoading: false,
                  history: [
                    MoodLog(moodScore: 9, emoji: '🤩', feelings: ['Grateful'], journal: 'Great day', createdAt: now),
                    MoodLog(moodScore: 3, emoji: '😫', feelings: ['Stressed'], journal: 'Busy workday', createdAt: now.subtract(const Duration(days: 1))),
                  ],
                ),
              );
            }),
          ],
          child: const MaterialApp(
            home: MoodHistoryScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Mood Insights'), findsOneWidget);
      expect(find.text('Grateful (1)'), findsOneWidget);

      // Tap top feeling chip to filter history search
      await tester.tap(find.text('Grateful (1)'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Great day'), findsOneWidget);
      expect(find.text('Busy workday'), findsNothing);
    });
  });
}
