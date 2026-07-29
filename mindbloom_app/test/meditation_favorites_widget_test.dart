import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mindbloom_app/screens/meditation/meditation_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('plugins.itrix.com.br/flutter_secure_storage');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (message) async => null);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpMeditationScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: MeditationScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
  }

  group('MeditationScreen - Favorite Meditations Widget Tests', () {
    testWidgets('Session cards display favorite heart buttons', (tester) async {
      await pumpMeditationScreen(tester);

      expect(find.text('Calm Morning'), findsOneWidget);
      expect(find.byTooltip('Add to favorites'), findsWidgets);
    });

    testWidgets('Tapping heart button toggles favorite state', (tester) async {
      await pumpMeditationScreen(tester);

      final calmMorningHeart = find.widgetWithIcon(IconButton, Icons.favorite_border_rounded).first;
      await tester.tap(calmMorningHeart);
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byTooltip('Remove from favorites'), findsOneWidget);
    });

    testWidgets('Tapping Favorites filter chip shows empty state when no favorites exist', (tester) async {
      await pumpMeditationScreen(tester);

      final favoritesChip = find.text('Favorites');
      await tester.tap(favoritesChip);
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('No favorite sessions yet'), findsOneWidget);
      expect(find.text('Calm Morning'), findsNothing);
    });

    testWidgets('Tapping Favorites filter chip displays only favorited sessions', (tester) async {
      await pumpMeditationScreen(tester);

      // Favorite Calm Morning
      final firstHeart = find.byTooltip('Add to favorites').first;
      await tester.tap(firstHeart);
      await tester.pump(const Duration(milliseconds: 300));

      // Filter by favorites
      final favoritesChip = find.text('Favorites');
      await tester.tap(favoritesChip);
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Calm Morning'), findsOneWidget);
      expect(find.text('Stress Relief'), findsNothing);
    });
  });
}
