import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../models/breathing_session_model.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class BreathingHistoryState {
  final List<BreathingSession> sessions;
  final bool isLoading;

  const BreathingHistoryState({
    this.sessions = const [],
    this.isLoading = false,
  });

  BreathingHistoryState copyWith({
    List<BreathingSession>? sessions,
    bool? isLoading,
  }) {
    return BreathingHistoryState(
      sessions: sessions ?? this.sessions,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  /// Sessions completed today only.
  List<BreathingSession> get todaySessions {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return sessions
        .where((s) => DateFormat('yyyy-MM-dd').format(s.completedAt) == today)
        .toList();
  }

  /// Total practice time across all sessions, in seconds.
  int get totalPracticeSeconds =>
      sessions.fold(0, (sum, s) => sum + s.durationSeconds);

  /// Human-readable total practice time.
  String get formattedTotalTime {
    final total = totalPracticeSeconds;
    final hours = total ~/ 3600;
    final minutes = (total % 3600) ~/ 60;
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }

  /// Number of unique days with at least one session.
  int get activeDays {
    final days = sessions
        .map((s) => DateFormat('yyyy-MM-dd').format(s.completedAt))
        .toSet();
    return days.length;
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class BreathingHistoryNotifier extends StateNotifier<BreathingHistoryState> {
  static const _storageKey = 'breathing_session_history';

  BreathingHistoryNotifier()
      : super(const BreathingHistoryState(isLoading: true)) {
    _load();
  }

  // ── Persistence ──────────────────────────────────────────────────────

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey) ?? [];
    final sessions = raw
        .map((s) =>
            BreathingSession.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
    state = BreathingHistoryState(sessions: sessions);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = state.sessions.map((s) => jsonEncode(s.toJson())).toList();
    await prefs.setStringList(_storageKey, raw);
  }

  // ── Public API ───────────────────────────────────────────────────────

  /// Record a new completed breathing session.
  Future<void> addSession({
    required String programName,
    required String programEmoji,
    required int durationSeconds,
    required int roundsCompleted,
  }) async {
    final session = BreathingSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      programName: programName,
      programEmoji: programEmoji,
      durationSeconds: durationSeconds,
      roundsCompleted: roundsCompleted,
      completedAt: DateTime.now(),
    );
    state = state.copyWith(sessions: [session, ...state.sessions]);
    await _save();
  }

  /// Remove a session by its [id].
  Future<void> removeSession(String id) async {
    state = state.copyWith(
      sessions: state.sessions.where((s) => s.id != id).toList(),
    );
    await _save();
  }

  /// Clear all session history.
  Future<void> clearHistory() async {
    state = state.copyWith(sessions: []);
    await _save();
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final breathingHistoryProvider =
    StateNotifierProvider<BreathingHistoryNotifier, BreathingHistoryState>(
        (ref) {
  return BreathingHistoryNotifier();
});
