import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mindbloom_app/providers/meditation_favorites_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('MeditationFavoritesNotifier - Favorites Unit Tests', () {
    test('initial state has empty favorite titles and is not loading after init', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(meditationFavoritesProvider);
      await Future.delayed(const Duration(milliseconds: 100));

      final state = container.read(meditationFavoritesProvider);
      expect(state.favoriteTitles, isEmpty);
      expect(state.isLoading, isFalse);
    });

    test('toggleFavorite adds and removes session titles and persists to SharedPreferences', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(meditationFavoritesProvider);
      await Future.delayed(const Duration(milliseconds: 50));

      final notifier = container.read(meditationFavoritesProvider.notifier);
      const title = 'Calm Morning';

      expect(notifier.isFavorite(title), isFalse);

      // Add to favorites
      await notifier.toggleFavorite(title);
      expect(notifier.isFavorite(title), isTrue);
      expect(container.read(meditationFavoritesProvider).favoriteTitles.contains(title), isTrue);

      // Check SharedPreferences persistence
      final prefs = await SharedPreferences.getInstance();
      var saved = prefs.getStringList('favorite_meditations') ?? [];
      expect(saved.contains(title), isTrue);

      // Remove from favorites
      await notifier.toggleFavorite(title);
      expect(notifier.isFavorite(title), isFalse);

      saved = prefs.getStringList('favorite_meditations') ?? [];
      expect(saved.contains(title), isFalse);
    });

    test('multiple session titles can be favorited independently', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(meditationFavoritesProvider);
      await Future.delayed(const Duration(milliseconds: 50));

      final notifier = container.read(meditationFavoritesProvider.notifier);
      await notifier.toggleFavorite('Stress Relief');
      await notifier.toggleFavorite('Body Scan');

      final state = container.read(meditationFavoritesProvider);
      expect(state.favoriteTitles.length, equals(2));
      expect(state.favoriteTitles.contains('Stress Relief'), isTrue);
      expect(state.favoriteTitles.contains('Body Scan'), isTrue);
    });
  });
}
