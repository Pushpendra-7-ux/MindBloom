import 'package:flutter_test/flutter_test.dart';
import 'package:mindbloom_app/models/meditation_model.dart';

void main() {
  group('MeditationSession Model Tests', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 'session_123',
        'title': 'Custom Silent Meditation',
        'durationSeconds': 600,
        'date': '2026-07-02T10:00:00.000Z',
        'isCustom': true,
      };

      final session = MeditationSession.fromJson(json);

      expect(session.id, equals('session_123'));
      expect(session.title, equals('Custom Silent Meditation'));
      expect(session.durationSeconds, equals(600));
      expect(session.date.year, equals(2026));
      expect(session.date.month, equals(7));
      expect(session.date.day, equals(2));
      expect(session.isCustom, isTrue);
    });

    test('toJson serializes correctly', () {
      final date = DateTime(2026, 7, 2, 10, 0);
      final session = MeditationSession(
        id: 'session_999',
        title: 'Calm Morning preset',
        durationSeconds: 900,
        date: date,
        isCustom: false,
      );

      final json = session.toJson();

      expect(json['id'], equals('session_999'));
      expect(json['title'], equals('Calm Morning preset'));
      expect(json['durationSeconds'], equals(900));
      expect(json['date'], equals(date.toIso8601String()));
      expect(json['isCustom'], isFalse);
    });

    test('History duration summation logic', () {
      final history = [
        MeditationSession(
          id: '1',
          title: 'Custom',
          durationSeconds: 300,
          date: DateTime.now(),
        ),
        MeditationSession(
          id: '2',
          title: 'Morning Calm',
          durationSeconds: 600,
          date: DateTime.now(),
        ),
      ];

      final totalSeconds = history.fold<int>(0, (sum, item) => sum + item.durationSeconds);
      expect(totalSeconds, equals(900));
      expect(totalSeconds ~/ 60, equals(15));
    });
  });
}
