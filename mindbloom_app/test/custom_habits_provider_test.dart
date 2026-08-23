import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mindbloom_app/providers/custom_habits_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('CustomHabitsNotifier - Unit Tests', () {
    test('initial state has empty habits and is not loading after init', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(customHabitsProvider);
      await Future.delayed(const Duration(milliseconds: 100));

      final state = container.read(customHabitsProvider);
      expect(state.habits, isEmpty);
      expect(state.isLoading, isFalse);
    });

    test('addCustomHabit adds habit item and persists to SharedPreferences', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(customHabitsProvider);
      await Future.delayed(const Duration(milliseconds: 50));

      final notifier = container.read(customHabitsProvider.notifier);
      await notifier.addCustomHabit('Morning Stretch', '🧘');

      final state = container.read(customHabitsProvider);
      expect(state.habits.length, equals(1));
      expect(state.habits.first.label, equals('Morning Stretch'));
      expect(state.habits.first.icon, equals('🧘'));

      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList('custom_habits') ?? [];
      expect(saved.length, equals(1));
      expect(saved.first.contains('Morning Stretch'), isTrue);
    });

    test('removeCustomHabit deletes habit item by id and updates persistence', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(customHabitsProvider);
      await Future.delayed(const Duration(milliseconds: 50));

      final notifier = container.read(customHabitsProvider.notifier);
      await notifier.addCustomHabit('Evening Walk', '🏃');
      var state = container.read(customHabitsProvider);
      final id = state.habits.first.id;

      await notifier.removeCustomHabit(id);
      state = container.read(customHabitsProvider);
      expect(state.habits, isEmpty);

      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList('custom_habits') ?? [];
      expect(saved, isEmpty);
    });
  });
}
