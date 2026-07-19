import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mindbloom_app/providers/affirmation_provider.dart';
import 'package:mindbloom_app/config/daily_affirmations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AffirmationNotifier - Custom Affirmations', () {
    test('initial state has no custom affirmations', () async {
      final container = ProviderContainer();
      // Trigger provider creation and wait for async _init to settle
      container.read(affirmationProvider);
      await Future.delayed(const Duration(milliseconds: 300));
      final state = container.read(affirmationProvider);
      expect(state.affirmations.length, equals(DailyAffirmations.totalAffirmations));
      expect(state.affirmations.any((a) => a['isCustom'] == 'true'), isFalse);
      container.dispose();
    });

    test('addCustomAffirmation adds to state and persists to SharedPreferences', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await Future.delayed(const Duration(milliseconds: 100));

      await container.read(affirmationProvider.notifier).addCustomAffirmation(
            'I am resilient and strong.',
            'Resilience',
          );

      final state = container.read(affirmationProvider);
      // Should have one more affirmation than predefined
      expect(state.affirmations.length, equals(DailyAffirmations.totalAffirmations + 1));
      final custom = state.affirmations.lastWhere((a) => a['isCustom'] == 'true');
      expect(custom['text'], equals('I am resilient and strong.'));
      expect(custom['category'], equals('Resilience'));

      // Verify persisted in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final rawList = prefs.getStringList('custom_affirmations') ?? [];
      expect(rawList.length, equals(1));
      final decoded = Map<String, String>.from(jsonDecode(rawList.first));
      expect(decoded['text'], equals('I am resilient and strong.'));
      expect(decoded['category'], equals('Resilience'));
      expect(decoded['isCustom'], equals('true'));
    });

    test('addCustomAffirmation auto-favorites the new affirmation', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await Future.delayed(const Duration(milliseconds: 100));

      await container.read(affirmationProvider.notifier).addCustomAffirmation(
            'I create my own joy every day.',
            'Self-Love',
          );

      final state = container.read(affirmationProvider);
      final customIdx = state.affirmations.indexWhere((a) => a['text'] == 'I create my own joy every day.');
      expect(customIdx, greaterThanOrEqualTo(0));
      expect(state.favoriteIndices.contains(customIdx), isTrue);
    });

    test('addCustomAffirmation shows new affirmation as current', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await Future.delayed(const Duration(milliseconds: 100));

      await container.read(affirmationProvider.notifier).addCustomAffirmation(
            'My mindset shapes my world.',
            'Growth',
          );

      final state = container.read(affirmationProvider);
      expect(state.current['text'], equals('My mindset shapes my world.'));
      expect(state.current['isCustom'], equals('true'));
    });

    test('getFavorites returns custom affirmation after adding', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await Future.delayed(const Duration(milliseconds: 100));

      await container.read(affirmationProvider.notifier).addCustomAffirmation(
            'I am grateful for who I am.',
            'Gratitude',
          );

      final favorites = container.read(affirmationProvider.notifier).getFavorites();
      expect(favorites.any((f) => f['text'] == 'I am grateful for who I am.'), isTrue);
    });

    test('deleteCustomAffirmation removes it from state', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await Future.delayed(const Duration(milliseconds: 100));

      await container.read(affirmationProvider.notifier).addCustomAffirmation(
            'I face challenges with courage.',
            'Resilience',
          );
      expect(
        container.read(affirmationProvider).affirmations.length,
        equals(DailyAffirmations.totalAffirmations + 1),
      );

      await container.read(affirmationProvider.notifier).deleteCustomAffirmation('I face challenges with courage.');

      final state = container.read(affirmationProvider);
      expect(state.affirmations.length, equals(DailyAffirmations.totalAffirmations));
      expect(state.affirmations.any((a) => a['text'] == 'I face challenges with courage.'), isFalse);
    });

    test('deleteCustomAffirmation removes it from favorites', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await Future.delayed(const Duration(milliseconds: 100));

      await container.read(affirmationProvider.notifier).addCustomAffirmation(
            'I trust the process of life.',
            'Calm',
          );

      // Verify it was auto-favorited
      var favorites = container.read(affirmationProvider.notifier).getFavorites();
      expect(favorites.any((f) => f['text'] == 'I trust the process of life.'), isTrue);

      await container.read(affirmationProvider.notifier).deleteCustomAffirmation('I trust the process of life.');

      favorites = container.read(affirmationProvider.notifier).getFavorites();
      expect(favorites.any((f) => f['text'] == 'I trust the process of life.'), isFalse);
    });

    test('deleteCustomAffirmation cleans SharedPreferences', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await Future.delayed(const Duration(milliseconds: 100));

      await container.read(affirmationProvider.notifier).addCustomAffirmation(
            'I shine my light brightly.',
            'Confidence',
          );

      var prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('custom_affirmations')?.length, equals(1));

      await container.read(affirmationProvider.notifier).deleteCustomAffirmation('I shine my light brightly.');

      prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('custom_affirmations')?.length ?? 0, equals(0));
    });

    test('multiple custom affirmations can be added independently', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await Future.delayed(const Duration(milliseconds: 100));

      await container.read(affirmationProvider.notifier).addCustomAffirmation('Custom one.', 'Growth');
      await container.read(affirmationProvider.notifier).addCustomAffirmation('Custom two.', 'Calm');

      final state = container.read(affirmationProvider);
      expect(state.affirmations.length, equals(DailyAffirmations.totalAffirmations + 2));
      expect(state.affirmations.where((a) => a['isCustom'] == 'true').length, equals(2));
    });
  });
}
