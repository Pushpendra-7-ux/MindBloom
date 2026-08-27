import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mindbloom_app/screens/affirmations/affirmations_screen.dart';
import 'package:mindbloom_app/providers/affirmation_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('plugins.itrix.com.br/flutter_secure_storage');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (message) async => null);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpAffirmationsScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: AffirmationsScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
  }

  group('AffirmationsScreen - Favorites Filter Widget Tests', () {
    testWidgets('Category bar renders Favorites filter chip', (tester) async {
      await pumpAffirmationsScreen(tester);

      expect(find.text('Favorites'), findsOneWidget);
    });

    testWidgets('Tapping Favorites filter chip shows empty state when no items are favorited', (tester) async {
      await pumpAffirmationsScreen(tester);

      await tester.tap(find.text('Favorites'), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('No Favorited Affirmations Yet'), findsOneWidget);
      expect(find.text('Tap the heart icon on any affirmation to save it to your favorites.'), findsOneWidget);
    });

    testWidgets('Favoriting an affirmation and filtering by Favorites displays favorited affirmation', (tester) async {
      await pumpAffirmationsScreen(tester);

      final element = tester.element(find.byType(AffirmationsScreen));
      final container = ProviderScope.containerOf(element);

      // Favorite current affirmation
      await container.read(affirmationProvider.notifier).toggleFavorite();
      await tester.pump(const Duration(milliseconds: 300));

      // Tap Favorites filter chip
      await tester.tap(find.text('Favorites'), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('No Favorited Affirmations Yet'), findsNothing);
      expect(find.text('Favorite'), findsOneWidget);
    });
  });
}
