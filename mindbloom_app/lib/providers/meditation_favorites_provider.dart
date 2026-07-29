import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MeditationFavoritesState {
  final Set<String> favoriteTitles;
  final bool isLoading;

  const MeditationFavoritesState({
    this.favoriteTitles = const {},
    this.isLoading = false,
  });

  MeditationFavoritesState copyWith({
    Set<String>? favoriteTitles,
    bool? isLoading,
  }) {
    return MeditationFavoritesState(
      favoriteTitles: favoriteTitles ?? this.favoriteTitles,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class MeditationFavoritesNotifier
    extends StateNotifier<MeditationFavoritesState> {
  static const _storageKey = 'favorite_meditations';

  MeditationFavoritesNotifier()
      : super(const MeditationFavoritesState(isLoading: true)) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_storageKey) ?? [];
    state = MeditationFavoritesState(
      favoriteTitles: saved.toSet(),
      isLoading: false,
    );
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_storageKey, state.favoriteTitles.toList());
  }

  Future<void> toggleFavorite(String title) async {
    final updated = Set<String>.from(state.favoriteTitles);
    if (updated.contains(title)) {
      updated.remove(title);
    } else {
      updated.add(title);
    }
    state = state.copyWith(favoriteTitles: updated);
    await _save();
  }

  bool isFavorite(String title) => state.favoriteTitles.contains(title);
}

final meditationFavoritesProvider = StateNotifierProvider<
    MeditationFavoritesNotifier, MeditationFavoritesState>((ref) {
  return MeditationFavoritesNotifier();
});
