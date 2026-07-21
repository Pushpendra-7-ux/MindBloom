import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/wellness_tips.dart';

class TipsState {
  final int currentIndex;
  final Set<int> savedIndices;
  final bool isLoading;

  const TipsState({
    this.currentIndex = 0,
    this.savedIndices = const {},
    this.isLoading = false,
  });

  Map<String, String> get currentTip => WellnessTips.getTipAt(currentIndex);

  TipsState copyWith({
    int? currentIndex,
    Set<int>? savedIndices,
    bool? isLoading,
  }) {
    return TipsState(
      currentIndex: currentIndex ?? this.currentIndex,
      savedIndices: savedIndices ?? this.savedIndices,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class TipsNotifier extends StateNotifier<TipsState> {
  static const _storageKey = 'saved_tips';

  TipsNotifier() : super(const TipsState(isLoading: true)) {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_storageKey) ?? [];
    final savedSet = saved.map((s) => int.tryParse(s)).whereType<int>().toSet();

    // Pick today's tip deterministically
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    final todayIndex = dayOfYear % WellnessTips.totalTips;

    state = TipsState(
      currentIndex: todayIndex,
      savedIndices: savedSet,
      isLoading: false,
    );
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _storageKey,
      state.savedIndices.map((i) => i.toString()).toList(),
    );
  }

  void nextTip() {
    final next = (state.currentIndex + 1) % WellnessTips.totalTips;
    state = state.copyWith(currentIndex: next);
  }

  Future<void> toggleSave(int index) async {
    final updated = Set<int>.from(state.savedIndices);
    if (updated.contains(index)) {
      updated.remove(index);
    } else {
      updated.add(index);
    }
    state = state.copyWith(savedIndices: updated);
    await _save();
  }

  bool isSaved(int index) => state.savedIndices.contains(index);

  List<Map<String, String>> getSavedTips() {
    final sorted = state.savedIndices.toList()..sort();
    return sorted.map((i) => WellnessTips.getTipAt(i)).toList();
  }

  List<int> getSavedIndices() {
    return state.savedIndices.toList()..sort();
  }
}

final tipsProvider = StateNotifierProvider<TipsNotifier, TipsState>((ref) {
  return TipsNotifier();
});
