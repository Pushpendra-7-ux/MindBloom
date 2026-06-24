import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mindbloom_app/providers/gratitude_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GratitudeEntry model', () {
    test('toJson / fromJson round-trip preserves data', () {
      final entry = GratitudeEntry(
        id: '42',
        text: 'sunny day',
        createdAt: DateTime(2026, 6, 23, 10, 30),
      );

      final json = entry.toJson();
      final restored = GratitudeEntry.fromJson(json);

      expect(restored.id, equals('42'));
      expect(restored.text, equals('sunny day'));
      expect(restored.createdAt, equals(DateTime(2026, 6, 23, 10, 30)));
    });
  });

  group('GratitudeNotifier', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('initial state has empty entries', () async {
      final notifier = GratitudeNotifier();
      // Allow async _load to complete
      await Future.delayed(const Duration(milliseconds: 50));
      expect(notifier.state.entries, isEmpty);
      expect(notifier.state.isLoading, isFalse);
    });

    test('add() creates a new entry at the front', () async {
      final notifier = GratitudeNotifier();
      await Future.delayed(const Duration(milliseconds: 50));

      await notifier.add('warm coffee');
      expect(notifier.state.entries.length, equals(1));
      expect(notifier.state.entries.first.text, equals('warm coffee'));
    });

    test('add() trims whitespace from text', () async {
      final notifier = GratitudeNotifier();
      await Future.delayed(const Duration(milliseconds: 50));

      await notifier.add('  sunshine  ');
      expect(notifier.state.entries.first.text, equals('sunshine'));
    });

    test('add() multiple entries preserves order (newest first)', () async {
      final notifier = GratitudeNotifier();
      await Future.delayed(const Duration(milliseconds: 50));

      await notifier.add('first');
      await notifier.add('second');
      expect(notifier.state.entries.length, equals(2));
      expect(notifier.state.entries[0].text, equals('second'));
      expect(notifier.state.entries[1].text, equals('first'));
    });

    test('remove() deletes entry by id', () async {
      final notifier = GratitudeNotifier();
      await Future.delayed(const Duration(milliseconds: 50));

      await notifier.add('to keep');
      await notifier.add('to remove');

      final removeId = notifier.state.entries.first.id; // 'to remove'
      await notifier.remove(removeId);

      expect(notifier.state.entries.length, equals(1));
      expect(notifier.state.entries.first.text, equals('to keep'));
    });

    test('todayEntries only returns entries created today', () async {
      final notifier = GratitudeNotifier();
      await Future.delayed(const Duration(milliseconds: 50));

      await notifier.add('today entry');
      // All entries we add via add() use DateTime.now(), so they are today's
      expect(notifier.state.todayEntries.length, equals(1));
      expect(notifier.state.todayEntries.first.text, equals('today entry'));
    });

    test('entries persist across instances via SharedPreferences', () async {
      final notifier1 = GratitudeNotifier();
      await Future.delayed(const Duration(milliseconds: 50));

      await notifier1.add('persistent');

      // Create a second instance — it should load from SharedPreferences
      final notifier2 = GratitudeNotifier();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(notifier2.state.entries.length, equals(1));
      expect(notifier2.state.entries.first.text, equals('persistent'));
    });
  });
}
