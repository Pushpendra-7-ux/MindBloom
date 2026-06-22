import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class WaterState {
  final int cups;
  final int goal;
  final String date;

  WaterState({required this.cups, required this.goal, required this.date});

  WaterState copyWith({int? cups, int? goal, String? date}) {
    return WaterState(
      cups: cups ?? this.cups,
      goal: goal ?? this.goal,
      date: date ?? this.date,
    );
  }
}

final waterProvider = StateNotifierProvider<WaterNotifier, WaterState>((ref) {
  return WaterNotifier();
});

class WaterNotifier extends StateNotifier<WaterState> {
  WaterNotifier() : super(WaterState(cups: 0, goal: 8, date: '')) {
    _loadState();
  }

  String _getTodayString() => DateFormat('yyyy-MM-dd').format(DateTime.now());

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _getTodayString();
    
    final savedDate = prefs.getString('water_date') ?? '';
    final goal = prefs.getInt('water_goal') ?? 8;
    
    if (savedDate == today) {
      final cups = prefs.getInt('water_cups') ?? 0;
      state = WaterState(cups: cups, goal: goal, date: today);
    } else {
      await prefs.setString('water_date', today);
      await prefs.setInt('water_cups', 0);
      state = WaterState(cups: 0, goal: goal, date: today);
    }
  }

  Future<void> increment() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _getTodayString();
    
    int cups = state.cups;
    if (state.date != today) {
      cups = 0;
      await prefs.setString('water_date', today);
    }
    
    final newCups = cups + 1;
    await prefs.setInt('water_cups', newCups);
    state = state.copyWith(cups: newCups, date: today);
  }

  Future<void> decrement() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _getTodayString();
    
    int cups = state.cups;
    if (state.date != today) {
      cups = 0;
      await prefs.setString('water_date', today);
    }
    
    if (cups <= 0) return;
    
    final newCups = cups - 1;
    await prefs.setInt('water_cups', newCups);
    state = state.copyWith(cups: newCups, date: today);
  }
}
