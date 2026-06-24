import 'package:flutter_test/flutter_test.dart';
import 'package:mindbloom_app/models/tracker_model.dart';

void main() {
  group('GoalItem Tests', () {
    test('GoalItem.fromJson parses correctly', () {
      final json = {'title': 'Drink 8 cups of water', 'completed': true};
      final goal = GoalItem.fromJson(json);

      expect(goal.title, equals('Drink 8 cups of water'));
      expect(goal.completed, isTrue);
    });

    test('GoalItem.toJson serializes correctly', () {
      final goal = GoalItem(title: 'Read a book', completed: false);
      final json = goal.toJson();

      expect(json['title'], equals('Read a book'));
      expect(json['completed'], isFalse);
    });
  });

  group('TrackerModel Tests', () {
    test('TrackerModel.fromJson parses correctly with habits and goals', () {
      final json = {
        '_id': 'tracker_123',
        'date': '2026-06-24T00:00:00.000Z',
        'habits': {
          'meditation': true,
          'exercise': false,
          'journaling': true,
        },
        'goals': [
          {'title': 'Complete coding assignment', 'completed': true},
          {'title': 'Go for a walk', 'completed': false},
        ],
        'notes': 'Had a productive day!',
      };

      final tracker = TrackerModel.fromJson(json);

      expect(tracker.id, equals('tracker_123'));
      expect(tracker.date.year, equals(2026));
      expect(tracker.date.month, equals(6));
      expect(tracker.date.day, equals(24));
      expect(tracker.habits['meditation'], isTrue);
      expect(tracker.habits['exercise'], isFalse);
      expect(tracker.habits['journaling'], isTrue);
      expect(tracker.goals.length, equals(2));
      expect(tracker.goals[0].title, equals('Complete coding assignment'));
      expect(tracker.goals[0].completed, isTrue);
      expect(tracker.goals[1].title, equals('Go for a walk'));
      expect(tracker.goals[1].completed, isFalse);
      expect(tracker.notes, equals('Had a productive day!'));
    });

    test('TrackerModel.toJson serializes correctly', () {
      final date = DateTime(2026, 6, 24);
      final tracker = TrackerModel(
        id: 'tracker_999',
        date: date,
        habits: {
          'meditation': false,
          'exercise': true,
        },
        goals: [
          GoalItem(title: 'Meditation goal', completed: true),
        ],
        notes: 'Feeling good',
      );

      final json = tracker.toJson();

      expect(json['date'], equals(date.toIso8601String()));
      expect(json['habits']['meditation'], isFalse);
      expect(json['habits']['exercise'], isTrue);
      expect(json['goals'].length, equals(1));
      expect(json['goals'][0]['title'], equals('Meditation goal'));
      expect(json['goals'][0]['completed'], isTrue);
      expect(json['notes'], equals('Feeling good'));
    });

    test('copyWith preserves properties and copies correctly', () {
      final tracker = TrackerModel(
        date: DateTime(2026, 6, 24),
        habits: {'meditation': true},
        goals: [GoalItem(title: 'Goal A')],
        notes: 'Notes A',
      );

      final updated = tracker.copyWith(
        notes: 'Notes B',
        goals: [GoalItem(title: 'Goal B', completed: true)],
      );

      expect(updated.notes, equals('Notes B'));
      expect(updated.goals.length, equals(1));
      expect(updated.goals[0].title, equals('Goal B'));
      expect(updated.goals[0].completed, isTrue);
      expect(updated.habits['meditation'], isTrue); // preserved
    });

    test('habitProgress calculates fraction correctly', () {
      final tracker = TrackerModel(
        date: DateTime(2026, 6, 24),
        habits: {
          'meditation': true,  // 1
          'exercise': true,    // 2
          'journaling': false, // 3
          'hydration': false,  // 4
          'sleep': false,      // 5
          'socializing': false,// 6
          'reading': false,    // 7
          'gratitude': false,  // 8
        },
      );

      expect(tracker.completedHabits, equals(2));
      expect(tracker.totalHabits, equals(8));
      expect(tracker.habitProgress, equals(2 / 8));
    });
  });
}
