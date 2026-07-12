import 'package:flutter_test/flutter_test.dart';
import 'package:mindbloom_app/config/gratitude_prompts.dart';

void main() {
  group('GratitudePrompts Tests', () {
    test('allPrompts returns a non-empty list', () {
      expect(GratitudePrompts.allPrompts, isNotEmpty);
      expect(GratitudePrompts.allPrompts.length, greaterThanOrEqualTo(10));
    });

    test('getTodayPrompt returns a non-empty string', () {
      final prompt = GratitudePrompts.getTodayPrompt();
      expect(prompt, isNotEmpty);
      expect(GratitudePrompts.allPrompts, contains(prompt));
    });

    test('getTodayPrompt is deterministic within the same day', () {
      final first = GratitudePrompts.getTodayPrompt();
      final second = GratitudePrompts.getTodayPrompt();
      expect(first, equals(second));
    });

    test('getRandomPrompt returns a different prompt than the current one', () {
      final current = GratitudePrompts.allPrompts.first;
      final next = GratitudePrompts.getRandomPrompt(current);
      expect(next, isNotEmpty);
      expect(next, isNot(equals(current)));
      expect(GratitudePrompts.allPrompts, contains(next));
    });

    test('getRandomPrompt always avoids the current prompt', () {
      final current = GratitudePrompts.allPrompts[3];
      // Run 20 times to increase confidence
      for (int i = 0; i < 20; i++) {
        final result = GratitudePrompts.getRandomPrompt(current);
        expect(result, isNot(equals(current)));
      }
    });
  });
}
