import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mindbloom_app/screens/tracker/tracker_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('plugins.itrix.com.br/flutter_secure_storage');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (message) async => null);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpTrackerScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: TrackerScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 3));
  }

  group('TrackerScreen - Custom Habits Widget Tests', () {
    testWidgets('Tapping Add Custom button opens creation dialog', (tester) async {
      await pumpTrackerScreen(tester);

      expect(find.text('Add Custom'), findsOneWidget);
      await tester.tap(find.text('Add Custom'), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('New Custom Habit'), findsOneWidget);
      expect(find.byKey(const Key('custom_habit_label_field')), findsOneWidget);
    });

    testWidgets('Form validation prevents submitting empty habit name', (tester) async {
      await pumpTrackerScreen(tester);

      await tester.tap(find.text('Add Custom'), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Add Habit'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Please enter a habit name'), findsOneWidget);
    });

    testWidgets('Adding a valid custom habit adds it to the habit list', (tester) async {
      await pumpTrackerScreen(tester);

      await tester.tap(find.text('Add Custom'), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 300));

      await tester.enterText(
        find.byKey(const Key('custom_habit_label_field')),
        'Evening Yoga',
      );
      await tester.tap(find.text('Add Habit'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Evening Yoga'), findsOneWidget);
      expect(find.byTooltip('Delete custom habit'), findsOneWidget);
    });

    testWidgets('Deleting custom habit removes it from tracker screen', (tester) async {
      await pumpTrackerScreen(tester);

      // Add custom habit
      await tester.tap(find.text('Add Custom'), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.enterText(
        find.byKey(const Key('custom_habit_label_field')),
        'Reading 20 mins',
      );
      await tester.tap(find.text('Add Habit'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Reading 20 mins'), findsOneWidget);

      // Delete habit
      final deleteIcon = find.byTooltip('Delete custom habit').first;
      await tester.tap(deleteIcon, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Reading 20 mins'), findsNothing);
    });
  });
}
