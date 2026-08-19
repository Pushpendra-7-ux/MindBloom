import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

// ---------------------------------------------------------------------------
// Model
// ---------------------------------------------------------------------------

/// A single gratitude journal entry.
class GratitudeEntry {
  final String id;
  final String text;
  final DateTime createdAt;
  final bool isFavorite;

  GratitudeEntry({
    required this.id,
    required this.text,
    required this.createdAt,
    this.isFavorite = false,
  });

  GratitudeEntry copyWith({
    String? id,
    String? text,
    DateTime? createdAt,
    bool? isFavorite,
  }) {
    return GratitudeEntry(
      id: id ?? this.id,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
        'isFavorite': isFavorite,
      };

  factory GratitudeEntry.fromJson(Map<String, dynamic> json) {
    return GratitudeEntry(
      id: json['id'] as String,
      text: json['text'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isFavorite: json['isFavorite'] as bool? ?? false,
    );
  }
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class GratitudeState {
  final List<GratitudeEntry> entries;
  final bool isLoading;

  const GratitudeState({
    this.entries = const [],
    this.isLoading = false,
  });

  GratitudeState copyWith({
    List<GratitudeEntry>? entries,
    bool? isLoading,
  }) {
    return GratitudeState(
      entries: entries ?? this.entries,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  /// Entries logged today only.
  List<GratitudeEntry> get todayEntries {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return entries
        .where((e) => DateFormat('yyyy-MM-dd').format(e.createdAt) == today)
        .toList();
  }

  /// Entries marked as favorites.
  List<GratitudeEntry> get favoriteEntries {
    return entries.where((e) => e.isFavorite).toList();
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class GratitudeNotifier extends StateNotifier<GratitudeState> {
  static const _storageKey = 'gratitude_entries';

  GratitudeNotifier() : super(const GratitudeState(isLoading: true)) {
    _load();
  }

  // ── Persistence helpers ──────────────────────────────────────────────

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey) ?? [];
    final entries = raw
        .map((s) => GratitudeEntry.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    state = GratitudeState(entries: entries);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = state.entries.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_storageKey, raw);
  }

  // ── Public API ───────────────────────────────────────────────────────

  /// Add a new gratitude entry with the given [text].
  Future<void> add(String text) async {
    final entry = GratitudeEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text.trim(),
      createdAt: DateTime.now(),
    );
    state = state.copyWith(entries: [entry, ...state.entries]);
    await _save();
  }

  /// Remove an entry by its [id].
  Future<void> remove(String id) async {
    state = state.copyWith(
      entries: state.entries.where((e) => e.id != id).toList(),
    );
    await _save();
  }

  /// Toggle the favorite status of an entry by its [id].
  Future<void> toggleFavorite(String id) async {
    final updated = state.entries.map((e) {
      if (e.id == id) {
        return e.copyWith(isFavorite: !e.isFavorite);
      }
      return e;
    }).toList();
    state = state.copyWith(entries: updated);
    await _save();
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final gratitudeProvider =
    StateNotifierProvider<GratitudeNotifier, GratitudeState>((ref) {
  return GratitudeNotifier();
});
