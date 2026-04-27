import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/mood_model.dart';
import '../services/api_service.dart';

class MoodState {
  final MoodLog? latestMood;
  final List<MoodLog> history;
  final List<WeeklyMoodData> weeklyData;
  final bool isLoading;
  final String? error;

  MoodState({
    this.latestMood,
    this.history = const [],
    this.weeklyData = const [],
    this.isLoading = false,
    this.error,
  });

  MoodState copyWith({
    MoodLog? latestMood,
    List<MoodLog>? history,
    List<WeeklyMoodData>? weeklyData,
    bool? isLoading,
    String? error,
  }) {
    return MoodState(
      latestMood: latestMood ?? this.latestMood,
      history: history ?? this.history,
      weeklyData: weeklyData ?? this.weeklyData,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class MoodNotifier extends StateNotifier<MoodState> {
  final ApiService _api = ApiService();

  MoodNotifier() : super(MoodState());

  Future<bool> submitCheckin(MoodLog moodLog) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.submitMoodCheckin(moodLog.toJson());
      state = state.copyWith(latestMood: moodLog, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to save mood');
      return false;
    }
  }

  Future<void> fetchLatestMood() async {
    try {
      final response = await _api.getLatestMood();
      if (response.data['moodLog'] != null) {
        state = state.copyWith(latestMood: MoodLog.fromJson(response.data['moodLog']));
      }
    } catch (_) {}
  }

  Future<void> fetchMoodHistory({int days = 30}) async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await _api.getMoodHistory(days: days);
      final logs = (response.data['logs'] as List).map((e) => MoodLog.fromJson(e)).toList();
      state = state.copyWith(history: logs, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to load history');
    }
  }

  Future<void> fetchWeeklyData() async {
    try {
      final response = await _api.getWeeklyMood();
      final data = (response.data['weeklyData'] as List).map((e) => WeeklyMoodData.fromJson(e)).toList();
      state = state.copyWith(weeklyData: data);
    } catch (_) {}
  }
}

final moodProvider = StateNotifierProvider<MoodNotifier, MoodState>((ref) {
  return MoodNotifier();
});
