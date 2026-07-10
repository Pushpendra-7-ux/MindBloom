import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mindbloom_app/models/breathing_session_model.dart';
import 'package:mindbloom_app/providers/breathing_history_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BreathingSession Model Tests', () {
    test('toJson and fromJson serialization preserves data', () {
      final session = BreathingSession(
        id: '123',
        programName: 'Box Breathing',
        programEmoji: '📦',
        durationSeconds: 240,
        roundsCompleted: 4,
        completedAt: DateTime.parse('2026-07-10T12:00:00Z'),
      );

      final jsonMap = session.toJson();
      final decoded = BreathingSession.fromJson(jsonMap);

      expect(decoded.id, equals(session.id));
      expect(decoded.programName, equals(session.programName));
      expect(decoded.programEmoji, equals(session.programEmoji));
      expect(decoded.durationSeconds, equals(session.durationSeconds));
      expect(decoded.roundsCompleted, equals(session.roundsCompleted));
      expect(decoded.completedAt, equals(session.completedAt));
    });

    test('formattedDuration helper returns correct values', () {
      final sessionShort = BreathingSession(
        id: '1',
        programName: 'Short',
        programEmoji: '⚡',
        durationSeconds: 45,
        roundsCompleted: 1,
        completedAt: DateTime.now(),
      );

      final sessionEven = BreathingSession(
        id: '2',
        programName: 'Even',
        programEmoji: '⚖️',
        durationSeconds: 120,
        roundsCompleted: 2,
        completedAt: DateTime.now(),
      );

      final sessionMixed = BreathingSession(
        id: '3',
        programName: 'Mixed',
        programEmoji: '🍃',
        durationSeconds: 155,
        roundsCompleted: 3,
        completedAt: DateTime.now(),
      );

      expect(sessionShort.formattedDuration, equals('45s'));
      expect(sessionEven.formattedDuration, equals('2m'));
      expect(sessionMixed.formattedDuration, equals('2m 35s'));
    });
  });

  group('BreathingHistoryNotifier / Provider Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Initial state is empty', () async {
      final notifier = BreathingHistoryNotifier();
      await Future.delayed(const Duration(milliseconds: 5));
      expect(notifier.state.sessions, isEmpty);
      expect(notifier.state.totalPracticeSeconds, equals(0));
      expect(notifier.state.formattedTotalTime, equals('0m'));
      expect(notifier.state.activeDays, equals(0));
    });

    test('Adding, removing, and clearing sessions updates state and computes stats', () async {
      final notifier = BreathingHistoryNotifier();
      await Future.delayed(const Duration(milliseconds: 5));

      // Add a session
      await notifier.addSession(
        programName: '4-7-8 Relax',
        programEmoji: '🍃',
        durationSeconds: 300,
        roundsCompleted: 4,
      );

      expect(notifier.state.sessions.length, equals(1));
      expect(notifier.state.sessions.first.programName, equals('4-7-8 Relax'));
      expect(notifier.state.totalPracticeSeconds, equals(300));
      expect(notifier.state.formattedTotalTime, equals('5m'));
      expect(notifier.state.activeDays, equals(1));

      // Add another session
      await notifier.addSession(
        programName: 'Box Breathing',
        programEmoji: '📦',
        durationSeconds: 240,
        roundsCompleted: 4,
      );

      expect(notifier.state.sessions.length, equals(2));
      expect(notifier.state.totalPracticeSeconds, equals(540));
      expect(notifier.state.formattedTotalTime, equals('9m'));

      final firstId = notifier.state.sessions.first.id;

      // Remove a session
      await notifier.removeSession(firstId);
      expect(notifier.state.sessions.length, equals(1));
      expect(notifier.state.totalPracticeSeconds, equals(300));

      // Clear all
      await notifier.clearHistory();
      expect(notifier.state.sessions, isEmpty);
      expect(notifier.state.totalPracticeSeconds, equals(0));
    });
  });
}
