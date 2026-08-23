import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mindbloom_app/providers/reminder_settings_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ReminderSettingsNotifier - Unit Tests', () {
    test('initial state has default reminder settings enabled and 09:00 AM check-in time', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(reminderSettingsProvider);
      await Future.delayed(const Duration(milliseconds: 100));

      final state = container.read(reminderSettingsProvider);
      expect(state.waterRemindersEnabled, isTrue);
      expect(state.checkinRemindersEnabled, isTrue);
      expect(state.breathingRemindersEnabled, isTrue);
      expect(state.preferredCheckinTime, equals('09:00 AM'));
      expect(state.isLoading, isFalse);
    });

    test('toggling reminder options updates state and persists to SharedPreferences', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(reminderSettingsProvider);
      await Future.delayed(const Duration(milliseconds: 50));

      final notifier = container.read(reminderSettingsProvider.notifier);

      // Toggle water reminders
      await notifier.toggleWaterReminders();
      expect(container.read(reminderSettingsProvider).waterRemindersEnabled, isFalse);

      // Toggle checkin reminders
      await notifier.toggleCheckinReminders();
      expect(container.read(reminderSettingsProvider).checkinRemindersEnabled, isFalse);

      // Toggle breathing reminders
      await notifier.toggleBreathingReminders();
      expect(container.read(reminderSettingsProvider).breathingRemindersEnabled, isFalse);

      // Verify SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('reminder_settings');
      expect(raw, isNotNull);
      final jsonMap = Map<String, dynamic>.from(jsonDecode(raw!));
      expect(jsonMap['waterRemindersEnabled'], isFalse);
      expect(jsonMap['checkinRemindersEnabled'], isFalse);
      expect(jsonMap['breathingRemindersEnabled'], isFalse);
    });

    test('setPreferredCheckinTime updates preferred check-in time and persists', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(reminderSettingsProvider);
      await Future.delayed(const Duration(milliseconds: 50));

      final notifier = container.read(reminderSettingsProvider.notifier);
      await notifier.setPreferredCheckinTime('08:30 PM');

      expect(container.read(reminderSettingsProvider).preferredCheckinTime, equals('08:30 PM'));

      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('reminder_settings');
      expect(raw, isNotNull);
      final jsonMap = Map<String, dynamic>.from(jsonDecode(raw!));
      expect(jsonMap['preferredCheckinTime'], equals('08:30 PM'));
    });
  });
}
