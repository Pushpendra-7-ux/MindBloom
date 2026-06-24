import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../models/tracker_model.dart';
import '../../services/api_service.dart';
import '../../widgets/custom_card.dart';

class TrackerScreen extends ConsumerStatefulWidget {
  const TrackerScreen({super.key});

  @override
  ConsumerState<TrackerScreen> createState() => _TrackerScreenState();
}

class _TrackerScreenState extends ConsumerState<TrackerScreen> {
  TrackerModel? _tracker;
  bool _isLoading = true;
  final TextEditingController _goalController = TextEditingController();

  static const Map<String, Map<String, dynamic>> _habitInfo = {
    'meditation': {'icon': '🧘', 'label': 'Meditation', 'color': AppColors.primaryPurple},
    'exercise': {'icon': '🏋️', 'label': 'Exercise', 'color': AppColors.softGreen},
    'journaling': {'icon': '📝', 'label': 'Journaling', 'color': AppColors.warmAmber},
    'hydration': {'icon': '💧', 'label': 'Hydration', 'color': AppColors.calmBlue},
    'sleep': {'icon': '😴', 'label': 'Good Sleep', 'color': AppColors.primaryPurple},
    'socializing': {'icon': '👥', 'label': 'Socializing', 'color': AppColors.coral},
    'reading': {'icon': '📚', 'label': 'Reading', 'color': AppColors.warmAmber},
    'gratitude': {'icon': '🙏', 'label': 'Gratitude', 'color': AppColors.softGreen},
  };

  @override
  void initState() {
    super.initState();
    _loadTracker();
  }

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }

  Future<void> _loadTracker() async {
    try {
      final response = await ApiService().getTodayTracker();
      setState(() {
        _tracker = TrackerModel.fromJson(response.data['tracker']);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _tracker = TrackerModel(date: DateTime.now());
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleHabit(String habit) async {
    if (_tracker == null) return;
    final newHabits = Map<String, bool>.from(_tracker!.habits);
    newHabits[habit] = !(newHabits[habit] ?? false);
    setState(() {
      _tracker = _tracker!.copyWith(habits: newHabits);
    });
    try {
      await ApiService().updateTracker(_tracker!.toJson());
    } catch (_) {}
  }

  Future<void> _addGoal() async {
    if (_goalController.text.trim().isEmpty) return;
    final goals = List<GoalItem>.from(_tracker!.goals);
    goals.add(GoalItem(title: _goalController.text.trim()));
    setState(() {
      _tracker = _tracker!.copyWith(goals: goals);
    });
    _goalController.clear();
    try {
      await ApiService().updateTracker(_tracker!.toJson());
    } catch (_) {}
  }

  Future<void> _toggleGoal(int index) async {
    if (_tracker == null || index < 0 || index >= _tracker!.goals.length) return;
    final goals = List<GoalItem>.from(_tracker!.goals);
    final goal = goals[index];
    goals[index] = GoalItem(title: goal.title, completed: !goal.completed);
    setState(() {
      _tracker = _tracker!.copyWith(goals: goals);
    });
    try {
      await ApiService().updateTracker(_tracker!.toJson());
    } catch (_) {}
  }

  Future<void> _deleteGoal(int index) async {
    if (_tracker == null || index < 0 || index >= _tracker!.goals.length) return;
    final goals = List<GoalItem>.from(_tracker!.goals);
    goals.removeAt(index);
    setState(() {
      _tracker = _tracker!.copyWith(goals: goals);
    });
    try {
      await ApiService().updateTracker(_tracker!.toJson());
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final tracker = _tracker!;
    final progress = tracker.habitProgress;

    return Scaffold(
      appBar: AppBar(title: const Text('Daily Tracker')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress card
            CustomCard(
              gradient: AppColors.primaryGradient,
              child: Row(
                children: [
                  SizedBox(
                    width: 70,
                    height: 70,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 6,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          valueColor: const AlwaysStoppedAnimation(Colors.white),
                          strokeCap: StrokeCap.round,
                        ),
                        Text(
                          '${(progress * 100).round()}%',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Today's Progress",
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(
                          '${tracker.completedHabits}/${tracker.totalHabits} habits completed',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Habits
            Text('Daily Habits', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            ...tracker.habits.entries.map((entry) {
              final info = _habitInfo[entry.key];
              if (info == null) return const SizedBox();
              return GestureDetector(
                onTap: () => _toggleHabit(entry.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: entry.value
                        ? (info['color'] as Color).withValues(alpha: 0.1)
                        : Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: entry.value
                          ? (info['color'] as Color)
                          : Colors.black.withValues(alpha: 0.08),
                      width: entry.value ? 1.5 : 0.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(info['icon'] as String, style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          info['label'] as String,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: entry.value ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: entry.value ? info['color'] as Color : Colors.transparent,
                          border: Border.all(
                            color: entry.value ? info['color'] as Color : Colors.black.withValues(alpha: 0.2),
                            width: 2,
                          ),
                        ),
                        child: entry.value
                            ? const Icon(Icons.check, color: Colors.white, size: 16)
                            : null,
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 24),

            // Daily Goals
            Text('Daily Goals', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _goalController,
                    decoration: const InputDecoration(hintText: 'Add a goal...'),
                    onFieldSubmitted: (_) => _addGoal(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _addGoal,
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.softGreen,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (tracker.goals.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text('No goals for today. Add one above!', style: Theme.of(context).textTheme.bodySmall),
                ),
              )
            else
              ...tracker.goals.asMap().entries.map((entry) {
                final goal = entry.value;
                return Dismissible(
                  key: ValueKey('${goal.title}_${entry.key}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.delete_rounded, color: AppColors.error),
                  ),
                  onDismissed: (_) => _deleteGoal(entry.key),
                  child: GestureDetector(
                    onTap: () => _toggleGoal(entry.key),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            goal.completed ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                            color: goal.completed ? AppColors.softGreen : AppColors.textSecondary,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              goal.title,
                              style: TextStyle(
                                decoration: goal.completed ? TextDecoration.lineThrough : null,
                                color: goal.completed ? AppColors.textSecondary : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
