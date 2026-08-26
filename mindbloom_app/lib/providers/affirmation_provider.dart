import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/daily_affirmations.dart';

/// State for the affirmation feature.
class AffirmationState {
  final List<Map<String, String>> affirmations;
  final int currentIndex;
  final String? activeCategory;
  final Set<int> favoriteIndices;
  final bool showFavoritesOnly;

  const AffirmationState({
    this.affirmations = const [],
    this.currentIndex = 0,
    this.activeCategory,
    this.favoriteIndices = const {},
    this.showFavoritesOnly = false,
  });

  Map<String, String> get current =>
      affirmations.isNotEmpty ? affirmations[currentIndex] : {'text': '', 'category': ''};

  bool get isFavorited => favoriteIndices.contains(currentIndex);

  AffirmationState copyWith({
    List<Map<String, String>>? affirmations,
    int? currentIndex,
    String? activeCategory,
    Set<int>? favoriteIndices,
    bool? showFavoritesOnly,
    bool clearCategory = false,
  }) {
    return AffirmationState(
      affirmations: affirmations ?? this.affirmations,
      currentIndex: currentIndex ?? this.currentIndex,
      activeCategory: clearCategory ? null : (activeCategory ?? this.activeCategory),
      favoriteIndices: favoriteIndices ?? this.favoriteIndices,
      showFavoritesOnly: showFavoritesOnly ?? this.showFavoritesOnly,
    );
  }
}

class AffirmationNotifier extends StateNotifier<AffirmationState> {
  static const _favKey = 'favorited_affirmations';
  static const _customKey = 'custom_affirmations';

  List<Map<String, String>> _allAffirmations = [];

  AffirmationNotifier() : super(const AffirmationState()) {
    _init();
  }

  Future<void> _init() async {
    final predefined = DailyAffirmations.getAll();
    final prefs = await SharedPreferences.getInstance();
    
    // Load custom affirmations
    final customRaw = prefs.getStringList(_customKey) ?? [];
    final custom = customRaw.map((raw) => Map<String, String>.from(jsonDecode(raw))).toList();

    _allAffirmations = [...predefined, ...custom];

    final saved = prefs.getStringList(_favKey) ?? [];
    final favIndices = <int>{};
    for (final raw in saved) {
      final idx = int.tryParse(raw);
      if (idx != null && idx >= 0 && idx < _allAffirmations.length) {
        favIndices.add(idx);
      }
    }

    // Start on today's affirmation
    final today = DailyAffirmations.getTodayAffirmation();
    final todayIndex = _allAffirmations.indexWhere((a) => a['text'] == today['text']);

    state = AffirmationState(
      affirmations: _allAffirmations,
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
        affirmations: _allAffirmations,
        currentIndex: 0,
        favoriteIndices: state.favoriteIndices,
        showFavoritesOnly: false,
      );
    } else {
      state = state.copyWith(
        affirmations: _allAffirmations.where((a) => a['category'] == category).toList(),
        currentIndex: 0,
        activeCategory: category,
        showFavoritesOnly: false,
      );
    }
  }

  /// Filter to show only favorited affirmations.
  void filterFavorites() {
    final favList = getFavorites();
    state = AffirmationState(
      affirmations: favList,
      currentIndex: 0,
      favoriteIndices: state.favoriteIndices,
      showFavoritesOnly: true,
    );
  }

  /// Toggle favorite status for the current affirmation.
  Future<void> toggleFavorite() async {
    // Find the global index (in case we're filtered)
    final currentText = state.current['text'];
    final globalIdx = _allAffirmations.indexWhere((a) => a['text'] == currentText);
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
    return state.favoriteIndices
        .where((i) => i < _allAffirmations.length)
        .map((i) => _allAffirmations[i])
        .toList();
  }

  /// Add a custom user affirmation.
  Future<void> addCustomAffirmation(String text, String category) async {
    final prefs = await SharedPreferences.getInstance();
    final customRaw = prefs.getStringList(_customKey) ?? [];
    
    final newCustom = {
      'text': text.trim(),
      'category': category,
      'isCustom': 'true',
    };
    
    customRaw.add(jsonEncode(newCustom));
    await prefs.setStringList(_customKey, customRaw);

    // Re-load all affirmations
    await _init();

    // Find the index of this new affirmation in _allAffirmations
    final newIdx = _allAffirmations.indexWhere((a) => a['text'] == newCustom['text']);
    if (newIdx >= 0) {
      // Favorite it automatically
      final favs = Set<int>.from(state.favoriteIndices);
      favs.add(newIdx);
      state = state.copyWith(
        favoriteIndices: favs,
        currentIndex: newIdx,
        clearCategory: true,
      );
      
      await prefs.setStringList(_favKey, favs.map((i) => i.toString()).toList());
    }
  }

  /// Delete a custom user affirmation.
  Future<void> deleteCustomAffirmation(String text) async {
    final prefs = await SharedPreferences.getInstance();
    final customRaw = prefs.getStringList(_customKey) ?? [];
    final updatedCustom = <String>[];
    for (final raw in customRaw) {
      final map = Map<String, String>.from(jsonDecode(raw));
      if (map['text'] != text) {
        updatedCustom.add(raw);
      }
    }
    await prefs.setStringList(_customKey, updatedCustom);

    // Rebuild the favorites list by mapping remaining items
    final remainingCustom = updatedCustom.map((raw) => Map<String, String>.from(jsonDecode(raw))).toList();
    final predefined = DailyAffirmations.getAll();
    final combined = [...predefined, ...remainingCustom];

    // Find the current favorites and filter out the deleted one
    final currentFavs = getFavorites().where((f) => f['text'] != text).toList();
    final newFavIndices = <int>{};
    for (final fav in currentFavs) {
      final idx = combined.indexWhere((a) => a['text'] == fav['text']);
      if (idx >= 0) {
        newFavIndices.add(idx);
      }
    }

    await prefs.setStringList(_favKey, newFavIndices.map((i) => i.toString()).toList());
    await _init();
  }
}

final affirmationProvider =
    StateNotifierProvider<AffirmationNotifier, AffirmationState>((ref) {
  return AffirmationNotifier();
});
