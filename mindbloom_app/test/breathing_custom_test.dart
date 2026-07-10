import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mindbloom_app/models/breathing_model.dart';
import 'package:mindbloom_app/screens/breathing/breathing_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BreathingProgram Model Tests', () {
    test('createCustom creates program with correct phases and durations', () {
      final custom = BreathingProgram.createCustom(
        inhale: 3,
        hold: 2,
        exhale: 4,
        holdEmpty: 1,
      );

      expect(custom.id, equals('custom'));
      expect(custom.name, equals('Custom Breath'));
      expect(custom.phases.length, equals(4));
      expect(custom.phases[0].name, equals('Breathe In'));
      expect(custom.phases[0].duration, equals(3));
      expect(custom.phases[1].name, equals('Hold'));
      expect(custom.phases[1].duration, equals(2));
      expect(custom.phases[2].name, equals('Breathe Out'));
      expect(custom.phases[2].duration, equals(4));
      expect(custom.phases[3].name, equals('Hold Empty'));
      expect(custom.phases[3].duration, equals(1));
    });

    test('createCustom omits hold or holdEmpty if duration is 0', () {
      final custom = BreathingProgram.createCustom(
        inhale: 4,
        hold: 0,
        exhale: 4,
        holdEmpty: 0,
      );

      expect(custom.phases.length, equals(2));
      expect(custom.phases[0].name, equals('Breathe In'));
      expect(custom.phases[1].name, equals('Breathe Out'));
    });

    test('toJson and fromJson roundtrip serialization works', () {
      final original = BreathingProgram.createCustom(
        inhale: 5,
        hold: 3,
        exhale: 5,
        holdEmpty: 2,
      );

      final jsonMap = original.toJson();
      final decoded = BreathingProgram.fromJson(jsonMap);

      expect(decoded.id, equals(original.id));
      expect(decoded.name, equals(original.name));
      expect(decoded.description, equals(original.description));
      expect(decoded.emoji, equals(original.emoji));
      expect(decoded.phases.length, equals(original.phases.length));
      expect(decoded.phases[0].name, equals(original.phases[0].name));
      expect(decoded.phases[0].duration, equals(original.phases[0].duration));
      expect(decoded.phases[0].color.value, equals(original.phases[0].color.value));
    });
  });

  group('BreathingScreen Widget Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('Tapping Custom Program opens bottom sheet and saves custom routine', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: BreathingScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap the "+ Custom" card. The card contains the text "Custom Program"
      final customCard = find.text('Custom Program');
      expect(customCard, findsOneWidget);
      await tester.tap(customCard);
      await tester.pumpAndSettle();

      // Bottom sheet should be visible now
      expect(find.text('Custom Breathing'), findsOneWidget);
      expect(find.textContaining('Total cycle:'), findsOneWidget);

      // Verify sliders exist
      expect(find.byType(Slider), findsNWidgets(4));

      // Tap Save & Use button
      final saveButton = find.text('Save & Use');
      expect(saveButton, findsOneWidget);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Bottom sheet should close
      expect(find.text('Custom Breathing'), findsNothing);

      // Verify custom breath is selected in UI
      expect(find.text('Custom Breath'), findsWidgets);

      // Check SharedPreferences to see if it saved
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('breathing_custom_program'), isNotNull);
      expect(prefs.getString('breathing_selected_program_id'), equals('custom'));
    });
  });
}
