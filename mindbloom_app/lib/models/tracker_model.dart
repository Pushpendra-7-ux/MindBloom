class TrackerModel {
  final String? id;
  final DateTime date;
  final Map<String, bool> habits;
  final List<GoalItem> goals;
  final String notes;

  TrackerModel({
    this.id,
    required this.date,
    Map<String, bool>? habits,
    this.goals = const [],
    this.notes = '',
  }) : habits = habits ?? {
    'meditation': false,
    'exercise': false,
    'journaling': false,
    'hydration': false,
    'sleep': false,
    'socializing': false,
    'reading': false,
    'gratitude': false,
  };

  factory TrackerModel.fromJson(Map<String, dynamic> json) {
    return TrackerModel(
      id: json['_id'] ?? json['id'],
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      habits: Map<String, bool>.from(json['habits'] ?? {}),
      goals: (json['goals'] as List? ?? []).map((e) => GoalItem.fromJson(e)).toList(),
      notes: json['notes'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'habits': habits,
    'goals': goals.map((g) => g.toJson()).toList(),
    'notes': notes,
  };

  TrackerModel copyWith({
    Map<String, bool>? habits,
    List<GoalItem>? goals,
    String? notes,
  }) {
    return TrackerModel(
      id: id,
      date: date,
      habits: habits ?? Map.from(this.habits),
      goals: goals ?? this.goals,
      notes: notes ?? this.notes,
    );
  }

  int get completedHabits => habits.values.where((v) => v).length;
  int get totalHabits => habits.length;
  double get habitProgress => totalHabits > 0 ? completedHabits / totalHabits : 0;
}

class GoalItem {
  final String title;
  final bool completed;

  GoalItem({required this.title, this.completed = false});

  factory GoalItem.fromJson(Map<String, dynamic> json) {
    return GoalItem(
      title: json['title'] ?? '',
      completed: json['completed'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {'title': title, 'completed': completed};
}
