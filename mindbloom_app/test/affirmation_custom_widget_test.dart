import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mindbloom_app/screens/affirmations/affirmations_screen.dart';
import 'package:mindbloom_app/providers/affirmation_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mock flutter_secure_storage channel
  const channel = MethodChannel('plugins.itrix.com.br/flutter_secure_storage');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (message) async => null);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpAffirmationsScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        child: const MaterialApp(
          home: AffirmationsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('AffirmationsScreen - Custom Affirmation Widgets', () {
    testWidgets('AppBar contains "+" button for creating custom affirmations', (tester) async {
      await pumpAffirmationsScreen(tester);
      expect(find.byTooltip('Create Custom Affirmation'), findsOneWidget);
    });

    testWidgets('Tapping "+" opens the custom affirmation creation sheet', (tester) async {
      await pumpAffirmationsScreen(tester);
      await tester.tap(find.byTooltip('Create Custom Affirmation'));
      await tester.pumpAndSettle();
      expect(find.text('Create Your Affirmation'), findsOneWidget);
      expect(find.text('Choose a Category'), findsOneWidget);
      expect(find.text('Your Affirmation'), findsOneWidget);
      expect(find.text('Save Affirmation'), findsOneWidget);
    });

    testWidgets('Save Affirmation button shows validation error when empty', (tester) async {
      await pumpAffirmationsScreen(tester);
      await tester.tap(find.byTooltip('Create Custom Affirmation'));
      await tester.pumpAndSettle();

      // Tap save without entering text
      await tester.tap(find.text('Save Affirmation'));
      await tester.pumpAndSettle();

      expect(find.text('Please write an affirmation.'), findsOneWidget);
    });

    testWidgets('Save Affirmation shows error for text shorter than 10 chars', (tester) async {
      await pumpAffirmationsScreen(tester);
      await tester.tap(find.byTooltip('Create Custom Affirmation'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'Short');
      await tester.tap(find.text('Save Affirmation'));
      await tester.pumpAndSettle();

      expect(find.text('Affirmation must be at least 10 characters.'), findsOneWidget);
    });

    testWidgets('Valid custom affirmation saves and shows success snackbar', (tester) async {
      await pumpAffirmationsScreen(tester);
      await tester.tap(find.byTooltip('Create Custom Affirmation'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField),
        'I am a beacon of light and strength.',
      );
      await tester.tap(find.text('Save Affirmation'));
      await tester.pumpAndSettle();

      // Sheet should close and snackbar should appear
      expect(find.text('Create Your Affirmation'), findsNothing);
      expect(find.text('Custom affirmation saved!'), findsOneWidget);
    });

    testWidgets('Category chips are selectable in creation sheet', (tester) async {
      await pumpAffirmationsScreen(tester);
      await tester.tap(find.byTooltip('Create Custom Affirmation'));
      await tester.pumpAndSettle();

      // Tap the 'Calm' chip to select it
      final calmChip = find.widgetWithText(ChoiceChip, 'Calm');
      expect(calmChip, findsOneWidget);
      await tester.tap(calmChip);
      await tester.pumpAndSettle();

      // ChoiceChip should now be selected
      final chip = tester.widget<ChoiceChip>(calmChip);
      expect(chip.selected, isTrue);
    });

    testWidgets('Saved sheet shows delete icon for custom affirmations', (tester) async {
      await pumpAffirmationsScreen(tester);

      // First create a custom affirmation
      await tester.tap(find.byTooltip('Create Custom Affirmation'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'I embrace every new challenge with joy.');
      await tester.tap(find.text('Save Affirmation'));
      await tester.pumpAndSettle();

      // Open saved sheet
      await tester.tap(find.byTooltip('Saved Affirmations'));
      await tester.pumpAndSettle();

      // Verify custom affirmation entry shows with Custom badge and delete icon
      expect(find.text('✦ Custom'), findsOneWidget);
      expect(find.byTooltip('Delete custom affirmation'), findsOneWidget);
    });

    testWidgets('Deleting a custom affirmation removes it from the saved sheet', (tester) async {
      await pumpAffirmationsScreen(tester);

      // Create a custom affirmation
      await tester.tap(find.byTooltip('Create Custom Affirmation'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'I radiate warmth and kindness always.');
      await tester.tap(find.text('Save Affirmation'));
      await tester.pumpAndSettle();

      // Open saved sheet
      await tester.tap(find.byTooltip('Saved Affirmations'));
      await tester.pumpAndSettle();
      // Text appears in both main card and saved list, so findsWidgets is acceptable
      expect(find.text('I radiate warmth and kindness always.'), findsWidgets);

      // Tap delete
      await tester.tap(find.byTooltip('Delete custom affirmation'));
      await tester.pumpAndSettle();

      // After deletion it should not appear in the saved list
      expect(find.text('I radiate warmth and kindness always.'), findsNothing);
    });
  });
}
