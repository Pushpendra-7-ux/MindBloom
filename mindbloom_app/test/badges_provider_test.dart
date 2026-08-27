import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mindbloom_app/providers/badges_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('BadgesNotifier - Unit Tests', () {
    test('initial state loads default badges and totalUnlocked starts at 0', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(badgesProvider);
      await Future.delayed(const Duration(milliseconds: 100));

      final state = container.read(badgesProvider);
      expect(state.badges, isNotEmpty);
      expect(state.totalUnlocked, equals(0));
      expect(state.isLoading, isFalse);
    });

    test('unlockBadge marks badge as unlocked and persists to SharedPreferences', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(badgesProvider);
      await Future.delayed(const Duration(milliseconds: 50));

      final notifier = container.read(badgesProvider.notifier);
      await notifier.unlockBadge('streak_3');

      final state = container.read(badgesProvider);
      expect(state.totalUnlocked, equals(1));
      expect(state.badges.firstWhere((b) => b.id == 'streak_3').isUnlocked, isTrue);

      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList('wellness_badges') ?? [];
      expect(saved, isNotEmpty);
      expect(saved.first.contains('streak_3'), isTrue);
    });

    test('evaluateMilestones unlocks eligible badges based on criteria', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(badgesProvider);
      await Future.delayed(const Duration(milliseconds: 50));

      final notifier = container.read(badgesProvider.notifier);

      final unlocked = await notifier.evaluateMilestones(
        streak: 3,
        moodLogs: 5,
        gratitudeLogs: 3,
        waterCups: 4,
        customHabits: 1,
      );

      expect(unlocked, contains('streak_3'));
      expect(unlocked, contains('mood_5'));
      expect(unlocked, contains('gratitude_3'));
      expect(unlocked, contains('water_4'));
      expect(unlocked, contains('custom_habit_1'));

      final state = container.read(badgesProvider);
      expect(state.totalUnlocked, equals(5));
    });
  });
}
