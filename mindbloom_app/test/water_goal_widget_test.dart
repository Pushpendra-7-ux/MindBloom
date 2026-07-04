import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mindbloom_app/screens/dashboard/dashboard_screen.dart';
import 'package:mindbloom_app/providers/water_provider.dart';
import 'package:mindbloom_app/providers/auth_provider.dart';
import 'package:mindbloom_app/providers/mood_provider.dart';
import 'package:mindbloom_app/models/user_model.dart';

// Fake implementations to prevent network/shared_prefs dependencies during testing
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

  // Setup mock channels for flutter_secure_storage
  const channel = MethodChannel('plugins.itrix.com.br/flutter_secure_storage');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (message) async {
    return null;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Hydration tracker settings button opens goal edit dialog', (WidgetTester tester) async {
    // Set window size to ensure widgets (including charts) lay out properly
    tester.view.physicalSize = const Size(800, 1600);
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

    // Verify hydration widget shows standard text (e.g. 8 cups)
    expect(find.text('Hydration Tracker 💧'), findsOneWidget);
    expect(find.text('0 / 8 cups'), findsOneWidget);

    // Tap the settings icon to open custom goal dialog
    final settingsButton = find.byTooltip('Change goal');
    expect(settingsButton, findsOneWidget);
    await tester.tap(settingsButton);
    await tester.pumpAndSettle();

    // Verify dialog opened
    expect(find.text('Daily Water Goal'), findsOneWidget);

    // Find the text field inside dialog
    final textFormField = find.byType(TextFormField);
    expect(textFormField, findsOneWidget);
    
    // Check validation of empty/null
    await tester.enterText(textFormField, '');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Required'), findsOneWidget);

    // Check validation of out-of-bounds
    await tester.enterText(textFormField, '3');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('4-20 cups'), findsOneWidget);

    // Tap plus button twice to change it from 3 to 5
    final plusButton = find.byIcon(Icons.add);
    await tester.tap(plusButton);
    await tester.pump();
    await tester.tap(plusButton);
    await tester.pump();
    expect(find.text('5'), findsOneWidget);

    // Save the new goal
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // Verify dialog is closed and new goal is updated in UI
    expect(find.text('Daily Water Goal'), findsNothing);
    expect(find.text('0 / 5 cups'), findsOneWidget);
    
    // Verify success SnackBar is shown
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Daily water goal updated to 5 cups! 💧'), findsOneWidget);
  });
}
