import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mindbloom_app/providers/affirmation_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AffirmationNotifier - Favorites Filter Unit Tests', () {
    test('filterFavorites filters state affirmations to favorited items only', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(affirmationProvider);
      await Future.delayed(const Duration(milliseconds: 100));

      final notifier = container.read(affirmationProvider.notifier);

      // Initially no favorites
      expect(container.read(affirmationProvider).favoriteIndices, isEmpty);

      // Favorite current item
      await notifier.toggleFavorite();
      final favCount = container.read(affirmationProvider).favoriteIndices.length;
      expect(favCount, equals(1));

      // Filter by favorites
      notifier.filterFavorites();
      final state = container.read(affirmationProvider);
      expect(state.showFavoritesOnly, isTrue);
      expect(state.affirmations.length, equals(1));
    });

    test('filterByCategory resets showFavoritesOnly to false', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(affirmationProvider);
      await Future.delayed(const Duration(milliseconds: 100));

      final notifier = container.read(affirmationProvider.notifier);
      notifier.filterFavorites();
      expect(container.read(affirmationProvider).showFavoritesOnly, isTrue);

      notifier.filterByCategory('Calm');
      final state = container.read(affirmationProvider);
      expect(state.showFavoritesOnly, isFalse);
      expect(state.activeCategory, equals('Calm'));
    });

    test('filterFavorites with no favorited items results in empty list', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(affirmationProvider);
      await Future.delayed(const Duration(milliseconds: 100));

      final notifier = container.read(affirmationProvider.notifier);
      notifier.filterFavorites();

      final state = container.read(affirmationProvider);
      expect(state.showFavoritesOnly, isTrue);
      expect(state.affirmations, isEmpty);
    });
  });
}
