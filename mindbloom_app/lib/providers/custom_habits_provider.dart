import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomHabitItem {
  final String id;
  final String label;
  final String icon;

  CustomHabitItem({
    required this.id,
    required this.label,
    required this.icon,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'icon': icon,
      };

  factory CustomHabitItem.fromJson(Map<String, dynamic> json) {
    return CustomHabitItem(
      id: json['id'] as String,
      label: json['label'] as String,
      icon: json['icon'] as String? ?? '⭐',
    );
  }
}

class CustomHabitsState {
  final List<CustomHabitItem> habits;
  final bool isLoading;

  const CustomHabitsState({
    this.habits = const [],
    this.isLoading = false,
  });

  CustomHabitsState copyWith({
    List<CustomHabitItem>? habits,
    bool? isLoading,
  }) {
    return CustomHabitsState(
      habits: habits ?? this.habits,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class CustomHabitsNotifier extends StateNotifier<CustomHabitsState> {
  static const _storageKey = 'custom_habits';

  CustomHabitsNotifier() : super(const CustomHabitsState(isLoading: true)) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey) ?? [];
    final items = raw
        .map((s) => CustomHabitItem.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
    state = CustomHabitsState(habits: items, isLoading: false);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = state.habits.map((h) => jsonEncode(h.toJson())).toList();
    await prefs.setStringList(_storageKey, raw);
  }

  Future<void> addCustomHabit(String label, String icon) async {
    final item = CustomHabitItem(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      label: label.trim(),
      icon: icon.trim().isEmpty ? '⭐' : icon.trim(),
    );
    state = state.copyWith(habits: [...state.habits, item]);
    await _save();
  }

  Future<void> removeCustomHabit(String id) async {
    state = state.copyWith(
      habits: state.habits.where((h) => h.id != id).toList(),
    );
    await _save();
  }
}

final customHabitsProvider =
    StateNotifierProvider<CustomHabitsNotifier, CustomHabitsState>((ref) {
  return CustomHabitsNotifier();
});
