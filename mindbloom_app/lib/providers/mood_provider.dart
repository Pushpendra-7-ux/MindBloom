import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/mood_model.dart';
import '../models/mood_analytics_model.dart';
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

  MoodAnalytics calculateAnalytics({int days = 30}) {
    final now = DateTime.now();
    final filteredLogs = state.history.where((log) {
      if (days <= 0 || log.createdAt == null) return true;
      final diff = now.difference(log.createdAt!).inDays;
      return diff <= days;
    }).toList();

    if (filteredLogs.isEmpty) {
      return MoodAnalytics(
        totalLogs: 0,
        averageScore: 0.0,
        positiveCount: 0,
        neutralCount: 0,
        negativeCount: 0,
        streakDays: 0,
        topFeelings: {},
        filterDays: days,
      );
    }

    double totalScore = 0;
    int pos = 0;
    int neu = 0;
    int neg = 0;
    final Map<String, int> feelingCounts = {};

    for (final log in filteredLogs) {
      totalScore += log.moodScore;
      if (log.moodScore >= 8) {
        pos++;
      } else if (log.moodScore >= 4) {
        neu++;
      } else {
        neg++;
      }

      for (final feeling in log.feelings) {
        feelingCounts[feeling] = (feelingCounts[feeling] ?? 0) + 1;
      }
    }

    final sortedFeelingsList = feelingCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final Map<String, int> topFeelings = {};
    for (final entry in sortedFeelingsList.take(5)) {
      topFeelings[entry.key] = entry.value;
    }

    final dates = state.history
        .where((l) => l.createdAt != null)
        .map((l) => DateTime(l.createdAt!.year, l.createdAt!.month, l.createdAt!.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    int streak = 0;
    if (dates.isNotEmpty) {
      DateTime checkDate = DateTime(now.year, now.month, now.day);
      if (!dates.contains(checkDate)) {
        checkDate = checkDate.subtract(const Duration(days: 1));
      }
      while (dates.contains(checkDate)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      }
    }

    return MoodAnalytics(
      totalLogs: filteredLogs.length,
      averageScore: double.parse((totalScore / filteredLogs.length).toStringAsFixed(1)),
      positiveCount: pos,
      neutralCount: neu,
      negativeCount: neg,
      streakDays: streak,
      topFeelings: topFeelings,
      filterDays: days,
    );
  }
}

final moodProvider = StateNotifierProvider<MoodNotifier, MoodState>((ref) {
  return MoodNotifier();
});

