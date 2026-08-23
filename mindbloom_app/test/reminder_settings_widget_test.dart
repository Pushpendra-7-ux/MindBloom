import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mindbloom_app/screens/profile/profile_screen.dart';
import 'package:mindbloom_app/providers/reminder_settings_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('plugins.itrix.com.br/flutter_secure_storage');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (message) async => null);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpProfileScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: ProfileScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
  }

  group('ProfileScreen - Daily Reminders Settings Widget Tests', () {
    testWidgets('Tapping Notifications menu item opens Reminders Settings sheet', (tester) async {
      await pumpProfileScreen(tester);

      expect(find.text('Notifications'), findsOneWidget);
      await tester.tap(find.text('Notifications'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('Daily Reminders Settings'), findsOneWidget);
      expect(find.text('Hydration Reminders'), findsOneWidget);
      expect(find.text('Mood Check-in Reminders'), findsOneWidget);
      expect(find.text('Breathing Exercise Reminders'), findsOneWidget);
      expect(find.text('Preferred Check-in Time'), findsOneWidget);
    });

    testWidgets('Toggling Hydration Reminders switch updates state', (tester) async {
      await pumpProfileScreen(tester);

      await tester.tap(find.text('Notifications'), warnIfMissed: false);
      await tester.pumpAndSettle();

      final element = tester.element(find.byType(ProfileScreen));
      final container = ProviderScope.containerOf(element);

      expect(container.read(reminderSettingsProvider).waterRemindersEnabled, isTrue);

      final hydrationSwitch = find.widgetWithText(SwitchListTile, 'Hydration Reminders');
      await tester.tap(hydrationSwitch, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 300));

      expect(container.read(reminderSettingsProvider).waterRemindersEnabled, isFalse);
    });

    testWidgets('Displays preferred check-in time of 09:00 AM by default', (tester) async {
      await pumpProfileScreen(tester);

      await tester.tap(find.text('Notifications'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('09:00 AM'), findsOneWidget);
    });
  });
}
