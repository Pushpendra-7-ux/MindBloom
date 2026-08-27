import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/badge_model.dart';

class BadgesState {
  final List<MindbloomBadge> badges;
  final bool isLoading;

  const BadgesState({
    this.badges = const [],
    this.isLoading = false,
  });

  int get totalUnlocked => badges.where((b) => b.isUnlocked).length;

  BadgesState copyWith({
    List<MindbloomBadge>? badges,
    bool? isLoading,
  }) {
    return BadgesState(
      badges: badges ?? this.badges,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class BadgesNotifier extends StateNotifier<BadgesState> {
  static const _storageKey = 'wellness_badges';

  static final List<MindbloomBadge> defaultBadges = [
    const MindbloomBadge(
      id: 'streak_3',
      title: '3-Day Pioneer',
      description: 'Logged into MindBloom 3 days in a row',
      icon: '🔥',
      category: BadgeCategory.streak,
      requiredCount: 3,
    ),
    const MindbloomBadge(
      id: 'streak_7',
      title: 'Week Warrior',
      description: 'Maintained a 7-day wellness streak',
      icon: '⚡',
      category: BadgeCategory.streak,
      requiredCount: 7,
    ),
    const MindbloomBadge(
      id: 'mood_5',
      title: 'Emotional Explorer',
      description: 'Logged 5 mood check-ins',
      icon: '📊',
      category: BadgeCategory.mindfulness,
      requiredCount: 5,
    ),
    const MindbloomBadge(
      id: 'gratitude_3',
      title: 'Grateful Soul',
      description: 'Saved 3 gratitude journal entries',
      icon: '🌸',
      category: BadgeCategory.gratitude,
      requiredCount: 3,
    ),
    const MindbloomBadge(
      id: 'water_4',
      title: 'Hydration Hero',
      description: 'Drank 4 or more glasses of water in a day',
      icon: '💧',
      category: BadgeCategory.hydration,
      requiredCount: 4,
    ),
    const MindbloomBadge(
      id: 'custom_habit_1',
      title: 'Habit Creator',
      description: 'Created your first custom wellness habit',
      icon: '✨',
      category: BadgeCategory.habits,
      requiredCount: 1,
    ),
  ];

  BadgesNotifier() : super(const BadgesState(isLoading: true)) {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_storageKey) ?? [];

    if (rawList.isEmpty) {
      state = BadgesState(badges: defaultBadges, isLoading: false);
      return;
    }

    final savedBadgesMap = <String, MindbloomBadge>{};
    for (final raw in rawList) {
      try {
        final b = MindbloomBadge.fromJson(jsonDecode(raw) as Map<String, dynamic>);
        savedBadgesMap[b.id] = b;
      } catch (_) {}
    }

    final mergedBadges = defaultBadges.map((def) {
      final saved = savedBadgesMap[def.id];
      if (saved != null) {
        return def.copyWith(
          isUnlocked: saved.isUnlocked,
          unlockedAt: saved.unlockedAt,
        );
      }
      return def;
    }).toList();

    state = BadgesState(badges: mergedBadges, isLoading: false);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = state.badges.map((b) => jsonEncode(b.toJson())).toList();
    await prefs.setStringList(_storageKey, rawList);
  }

  Future<void> unlockBadge(String badgeId) async {
    final updated = state.badges.map((b) {
      if (b.id == badgeId && !b.isUnlocked) {
        return b.copyWith(isUnlocked: true, unlockedAt: DateTime.now());
      }
      return b;
    }).toList();

    state = state.copyWith(badges: updated);
    await _save();
  }
}

final badgesProvider = StateNotifierProvider<BadgesNotifier, BadgesState>((ref) {
  return BadgesNotifier();
});
