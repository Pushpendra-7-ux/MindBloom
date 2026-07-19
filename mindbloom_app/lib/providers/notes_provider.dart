import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuickNote {
  final String id;
  final String text;
  final DateTime createdAt;

  QuickNote({
    required this.id,
    required this.text,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
      };

  factory QuickNote.fromJson(Map<String, dynamic> json) {
    return QuickNote(
      id: json['id'] as String,
      text: json['text'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class NotesState {
  final List<QuickNote> notes;
  final bool isLoading;

  const NotesState({
    this.notes = const [],
    this.isLoading = false,
  });

  NotesState copyWith({
    List<QuickNote>? notes,
    bool? isLoading,
  }) {
    return NotesState(
      notes: notes ?? this.notes,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class NotesNotifier extends StateNotifier<NotesState> {
  static const _storageKey = 'quick_notes';

  NotesNotifier() : super(const NotesState(isLoading: true)) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey) ?? [];
    final loaded = raw
        .map((s) => QuickNote.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    state = NotesState(notes: loaded, isLoading: false);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = state.notes.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_storageKey, raw);
  }

  Future<void> addNote(String text) async {
    final note = QuickNote(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text.trim(),
      createdAt: DateTime.now(),
    );
    state = state.copyWith(notes: [note, ...state.notes]);
    await _save();
  }

  Future<void> deleteNote(String id) async {
    state = state.copyWith(
      notes: state.notes.where((n) => n.id != id).toList(),
    );
    await _save();
  }
}

final notesProvider = StateNotifierProvider<NotesNotifier, NotesState>((ref) {
  return NotesNotifier();
});
