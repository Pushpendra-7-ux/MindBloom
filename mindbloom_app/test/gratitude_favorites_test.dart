import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mindbloom_app/providers/gratitude_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('GratitudeNotifier - Favorite Gratitudes Unit Tests', () {
    test('add creates entry with isFavorite false by default', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(gratitudeProvider);
      await Future.delayed(const Duration(milliseconds: 100));

      final notifier = container.read(gratitudeProvider.notifier);
      await notifier.add('Sunny morning walk');

      final state = container.read(gratitudeProvider);
      expect(state.entries.length, equals(1));
      expect(state.entries.first.text, equals('Sunny morning walk'));
      expect(state.entries.first.isFavorite, isFalse);
    });

    test('toggleFavorite toggles isFavorite boolean and updates favoriteEntries list', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(gratitudeProvider);
      await Future.delayed(const Duration(milliseconds: 50));

      final notifier = container.read(gratitudeProvider.notifier);
      await notifier.add('Coffee with a friend');
      var state = container.read(gratitudeProvider);
      final id = state.entries.first.id;

      expect(state.favoriteEntries, isEmpty);

      // Star the entry
      await notifier.toggleFavorite(id);
      state = container.read(gratitudeProvider);
      expect(state.entries.first.isFavorite, isTrue);
      expect(state.favoriteEntries.length, equals(1));
      expect(state.favoriteEntries.first.id, equals(id));

      // Un-star the entry
      await notifier.toggleFavorite(id);
      state = container.read(gratitudeProvider);
      expect(state.entries.first.isFavorite, isFalse);
      expect(state.favoriteEntries, isEmpty);
    });

    test('isFavorite status persists to SharedPreferences correctly', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(gratitudeProvider);
      await Future.delayed(const Duration(milliseconds: 50));

      final notifier = container.read(gratitudeProvider.notifier);
      await notifier.add('Good health and peace');
      final id = container.read(gratitudeProvider).entries.first.id;

      await notifier.toggleFavorite(id);

      // Check raw SharedPreferences data
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList('gratitude_entries') ?? [];
      expect(raw.length, equals(1));

      final jsonMap = Map<String, dynamic>.from(jsonDecode(raw.first));
      expect(jsonMap['isFavorite'], isTrue);
    });
  });
}
