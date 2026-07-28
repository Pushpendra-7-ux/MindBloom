import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mindbloom_app/screens/dashboard/dashboard_screen.dart';
import 'package:mindbloom_app/providers/notes_provider.dart';
import 'package:mindbloom_app/providers/auth_provider.dart';
import 'package:mindbloom_app/providers/mood_provider.dart';
import 'package:mindbloom_app/models/user_model.dart';

class FakeAuthNotifier extends AuthNotifier {
  FakeAuthNotifier() : super() {
    state = AuthState(
      user: UserModel(id: '1', name: 'Alice', email: 'alice@example.com'),
      token: 'fake-token',
    );
  }

  @override
  Future<void> _loadStoredAuth() async {}
}

class FakeMoodNotifier extends MoodNotifier {
  FakeMoodNotifier() : super() {
    state = MoodState();
  }

  @override
  Future<void> fetchLatestMood() async {}

  @override
  Future<void> fetchWeeklyData() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('plugins.itrix.com.br/flutter_secure_storage');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (message) async => null);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpDashboardScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => FakeAuthNotifier()),
          moodProvider.overrideWith((ref) => FakeMoodNotifier()),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: DashboardScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('DashboardScreen - Quick Notes Widgets', () {
    testWidgets('Quick Notes Card displays correctly with header and empty state', (tester) async {
      await pumpDashboardScreen(tester);

      expect(find.text('Quick Notes'), findsOneWidget);
      expect(find.text('Jot down thoughts or reminders'), findsOneWidget);
      expect(find.text('No notes yet'), findsOneWidget);
      expect(find.text('Capture your fleeting thoughts here.'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(2)); // Gratitude + Notes
    });

    testWidgets('Adding a quick note works, displays in preview, and clears input', (tester) async {
      await pumpDashboardScreen(tester);

      final notesInput = find.widgetWithText(TextField, 'Type a quick note...');
      expect(notesInput, findsOneWidget);

      await tester.enterText(notesInput, 'Remind me to breathe.');
      await tester.tap(find.byTooltip('Save note'));
      await tester.pumpAndSettle();

      // Check input cleared and note shown in list preview
      expect(find.text('Remind me to breathe.'), findsOneWidget);
      expect(find.text('No notes yet'), findsNothing);
    });

    testWidgets('See all notes button appears when there are more than 3 notes and opens bottom sheet', (tester) async {
      await pumpDashboardScreen(tester);

      final notesInput = find.widgetWithText(TextField, 'Type a quick note...');

      // Add 4 notes
      for (int i = 1; i <= 4; i++) {
        await tester.enterText(notesInput, 'Note $i');
        await tester.tap(find.byTooltip('Save note'));
        await tester.pumpAndSettle();
      }

      // Check "See all notes" button appears
      final seeAllBtn = find.byTooltip('See all notes');
      expect(seeAllBtn, findsOneWidget);

      // Tap button and verify modal opens
      await tester.tap(seeAllBtn);
      await tester.pumpAndSettle();

      expect(find.text('Quick Notes History'), findsOneWidget);
      expect(find.text('Note 4'), findsWidgets);
      expect(find.text('Note 1'), findsWidgets);
    });

    testWidgets('Deleting a note in preview updates Dashboard list', (tester) async {
      await pumpDashboardScreen(tester);

      final notesInput = find.widgetWithText(TextField, 'Type a quick note...');
      await tester.enterText(notesInput, 'Note to delete');
      await tester.tap(find.byTooltip('Save note'));
      await tester.pumpAndSettle();

      expect(find.text('Note to delete'), findsOneWidget);

      // Tap delete icon
      await tester.tap(find.byIcon(Icons.delete_outline_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Note to delete'), findsNothing);
      expect(find.text('No notes yet'), findsOneWidget);
    });
  });
}
