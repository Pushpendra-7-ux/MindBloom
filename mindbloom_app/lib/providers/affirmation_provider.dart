import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/daily_affirmations.dart';

/// State for the affirmation feature.
class AffirmationState {
  final List<Map<String, String>> affirmations;
  final int currentIndex;
  final String? activeCategory;
  final Set<int> favoriteIndices;

  const AffirmationState({
    this.affirmations = const [],
    this.currentIndex = 0,
    this.activeCategory,
    this.favoriteIndices = const {},
  });

  Map<String, String> get current =>
      affirmations.isNotEmpty ? affirmations[currentIndex] : {'text': '', 'category': ''};

  bool get isFavorited => favoriteIndices.contains(currentIndex);

  AffirmationState copyWith({
    List<Map<String, String>>? affirmations,
    int? currentIndex,
    String? activeCategory,
    Set<int>? favoriteIndices,
    bool clearCategory = false,
  }) {
    return AffirmationState(
      affirmations: affirmations ?? this.affirmations,
      currentIndex: currentIndex ?? this.currentIndex,
      activeCategory: clearCategory ? null : (activeCategory ?? this.activeCategory),
      favoriteIndices: favoriteIndices ?? this.favoriteIndices,
    );
  }
}

class AffirmationNotifier extends StateNotifier<AffirmationState> {
  static const _favKey = 'favorited_affirmations';

  AffirmationNotifier() : super(const AffirmationState()) {
    _init();
  }

  Future<void> _init() async {
    final all = DailyAffirmations.getAll();
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_favKey) ?? [];
    final favIndices = <int>{};
    for (final raw in saved) {
      final idx = int.tryParse(raw);
      if (idx != null && idx >= 0 && idx < all.length) {
        favIndices.add(idx);
      }
    }

    // Start on today's affirmation
    final today = DailyAffirmations.getTodayAffirmation();
    final todayIndex = all.indexWhere((a) => a['text'] == today['text']);

    state = AffirmationState(
      affirmations: all,
      currentIndex: todayIndex >= 0 ? todayIndex : 0,
      favoriteIndices: favIndices,
    );
  }

  /// Move to the next affirmation in the current list.
  void next() {
    if (state.affirmations.isEmpty) return;
    final nextIdx = (state.currentIndex + 1) % state.affirmations.length;
    state = state.copyWith(currentIndex: nextIdx);
  }

  /// Move to the previous affirmation.
  void previous() {
    if (state.affirmations.isEmpty) return;
    final prevIdx = (state.currentIndex - 1 + state.affirmations.length) %
        state.affirmations.length;
    state = state.copyWith(currentIndex: prevIdx);
  }

  /// Filter affirmations by category, or clear filter if null.
  void filterByCategory(String? category) {
    if (category == null) {
      state = AffirmationState(
        affirmations: DailyAffirmations.getAll(),
        currentIndex: 0,
        favoriteIndices: state.favoriteIndices,
      );
    } else {
      state = state.copyWith(
        affirmations: DailyAffirmations.getByCategory(category),
        currentIndex: 0,
        activeCategory: category,
      );
    }
  }

  /// Toggle favorite status for the current affirmation.
  Future<void> toggleFavorite() async {
    // Find the global index (in case we're filtered)
    final currentText = state.current['text'];
    final allAffirmations = DailyAffirmations.getAll();
    final globalIdx = allAffirmations.indexWhere((a) => a['text'] == currentText);
    if (globalIdx < 0) return;

    final favs = Set<int>.from(state.favoriteIndices);
    if (favs.contains(globalIdx)) {
      favs.remove(globalIdx);
    } else {
      favs.add(globalIdx);
    }
    state = state.copyWith(favoriteIndices: favs);

    // Persist
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_favKey, favs.map((i) => i.toString()).toList());
  }

  /// Get all favorited affirmation texts.
  List<Map<String, String>> getFavorites() {
    final all = DailyAffirmations.getAll();
    return state.favoriteIndices
        .where((i) => i < all.length)
        .map((i) => all[i])
        .toList();
  }
}

final affirmationProvider =
    StateNotifierProvider<AffirmationNotifier, AffirmationState>((ref) {
  return AffirmationNotifier();
});
