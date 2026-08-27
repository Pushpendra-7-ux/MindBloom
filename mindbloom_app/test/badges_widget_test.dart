import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mindbloom_app/screens/profile/profile_screen.dart';

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

  group('ProfileScreen - Wellness Milestones Widget Tests', () {
    testWidgets('ProfileScreen displays Wellness Milestones menu item', (tester) async {
      await pumpProfileScreen(tester);

      expect(find.text('Wellness Milestones'), findsOneWidget);
    });

    testWidgets('Tapping Wellness Milestones opens Badges Showcase sheet', (tester) async {
      await pumpProfileScreen(tester);

      await tester.tap(find.text('Wellness Milestones'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('Earn achievement badges as you build healthy daily wellness habits.'), findsOneWidget);
      expect(find.text('3-Day Pioneer'), findsOneWidget);
    });

    testWidgets('Tapping category filter chip filters badges in showcase sheet', (tester) async {
      await pumpProfileScreen(tester);

      await tester.tap(find.text('Wellness Milestones'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('Streaks'), findsOneWidget);
      await tester.tap(find.text('Streaks'), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('3-Day Pioneer'), findsOneWidget);
      expect(find.text('Hydration Hero'), findsNothing);
    });
  });
}
