import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReminderSettingsState {
  final bool waterRemindersEnabled;
  final bool checkinRemindersEnabled;
  final bool breathingRemindersEnabled;
  final String preferredCheckinTime;
  final bool isLoading;

  const ReminderSettingsState({
    this.waterRemindersEnabled = true,
    this.checkinRemindersEnabled = true,
    this.breathingRemindersEnabled = true,
    this.preferredCheckinTime = '09:00 AM',
    this.isLoading = false,
  });

  ReminderSettingsState copyWith({
    bool? waterRemindersEnabled,
    bool? checkinRemindersEnabled,
    bool? breathingRemindersEnabled,
    String? preferredCheckinTime,
    bool? isLoading,
  }) {
    return ReminderSettingsState(
      waterRemindersEnabled:
          waterRemindersEnabled ?? this.waterRemindersEnabled,
      checkinRemindersEnabled:
          checkinRemindersEnabled ?? this.checkinRemindersEnabled,
      breathingRemindersEnabled:
          breathingRemindersEnabled ?? this.breathingRemindersEnabled,
      preferredCheckinTime: preferredCheckinTime ?? this.preferredCheckinTime,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  Map<String, dynamic> toJson() => {
        'waterRemindersEnabled': waterRemindersEnabled,
        'checkinRemindersEnabled': checkinRemindersEnabled,
        'breathingRemindersEnabled': breathingRemindersEnabled,
        'preferredCheckinTime': preferredCheckinTime,
      };

  factory ReminderSettingsState.fromJson(Map<String, dynamic> json) {
    return ReminderSettingsState(
      waterRemindersEnabled: json['waterRemindersEnabled'] as bool? ?? true,
      checkinRemindersEnabled: json['checkinRemindersEnabled'] as bool? ?? true,
      breathingRemindersEnabled:
          json['breathingRemindersEnabled'] as bool? ?? true,
      preferredCheckinTime:
          json['preferredCheckinTime'] as String? ?? '09:00 AM',
      isLoading: false,
    );
  }
}

class ReminderSettingsNotifier extends StateNotifier<ReminderSettingsState> {
  static const _storageKey = 'reminder_settings';

  ReminderSettingsNotifier()
      : super(const ReminderSettingsState(isLoading: true)) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        state = ReminderSettingsState.fromJson(decoded);
        return;
      } catch (_) {}
    }
    state = const ReminderSettingsState(isLoading: false);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(state.toJson()));
  }

  Future<void> toggleWaterReminders() async {
    state =
        state.copyWith(waterRemindersEnabled: !state.waterRemindersEnabled);
    await _save();
  }

  Future<void> toggleCheckinReminders() async {
    state = state.copyWith(
        checkinRemindersEnabled: !state.checkinRemindersEnabled);
    await _save();
  }

  Future<void> toggleBreathingReminders() async {
    state = state.copyWith(
        breathingRemindersEnabled: !state.breathingRemindersEnabled);
    await _save();
  }

  Future<void> setPreferredCheckinTime(String time) async {
    state = state.copyWith(preferredCheckinTime: time);
    await _save();
  }
}

final reminderSettingsProvider = StateNotifierProvider<
    ReminderSettingsNotifier, ReminderSettingsState>((ref) {
  return ReminderSettingsNotifier();
});
