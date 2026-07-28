import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mindbloom_app/widgets/sos_overlay.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('plugins.itrix.com.br/flutter_secure_storage');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (message) async => null);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpSOSOverlay(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SOSOverlay(),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
  }

  group('SOSOverlay - Custom Contacts Widgets', () {
    testWidgets('SOSOverlay renders Add Contact button', (tester) async {
      await pumpSOSOverlay(tester);

      expect(find.text('Add Contact'), findsOneWidget);
      expect(find.byIcon(Icons.person_add_rounded), findsOneWidget);
    });

    testWidgets('Tapping Add Contact opens emergency contact creation dialog', (tester) async {
      await pumpSOSOverlay(tester);

      await tester.tap(find.text('Add Contact'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Add Personal Contact'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Contact Name'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Phone Number'), findsOneWidget);
    });

    testWidgets('Form validation prevents submitting empty fields', (tester) async {
      await pumpSOSOverlay(tester);

      await tester.tap(find.text('Add Contact'));
      await tester.pump(const Duration(milliseconds: 300));

      // Tap Save without entering text
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Please enter a name'), findsOneWidget);
      expect(find.text('Please enter a phone number'), findsOneWidget);
    });

    testWidgets('Adding a valid personal contact adds it to top of list with relation badge', (tester) async {
      await pumpSOSOverlay(tester);

      await tester.tap(find.text('Add Contact'));
      await tester.pump(const Duration(milliseconds: 300));

      final nameField = find.ancestor(
        of: find.text('Contact Name'),
        matching: find.byType(TextFormField),
      );
      final numberField = find.ancestor(
        of: find.text('Phone Number'),
        matching: find.byType(TextFormField),
      );

      await tester.enterText(nameField, 'Dr. Marcus');
      await tester.enterText(numberField, '9988776655');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
      await tester.pump(const Duration(milliseconds: 300));

      // Dialog closed and contact appears in list
      expect(find.text('Dr. Marcus'), findsOneWidget);
      expect(find.text('9988776655'), findsOneWidget);
      expect(find.text('Personal'), findsOneWidget);
      expect(find.text('Emergency contact added! 💛'), findsOneWidget);
    });

    testWidgets('Deleting a custom contact removes it from the overlay list', (tester) async {
      await pumpSOSOverlay(tester);

      // Add contact first
      await tester.tap(find.text('Add Contact'));
      await tester.pump(const Duration(milliseconds: 300));

      final nameField = find.ancestor(
        of: find.text('Contact Name'),
        matching: find.byType(TextFormField),
      );
      final numberField = find.ancestor(
        of: find.text('Phone Number'),
        matching: find.byType(TextFormField),
      );

      await tester.enterText(nameField, 'Aunt May');
      await tester.enterText(numberField, '1234567890');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Aunt May'), findsOneWidget);

      // Tap delete button for custom contact
      await tester.tap(find.byTooltip('Delete contact'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Aunt May'), findsNothing);
    });
  });
}
