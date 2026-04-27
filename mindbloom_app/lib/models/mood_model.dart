class MoodLog {
  final String? id;
  final int moodScore;
  final String emoji;
  final List<String> feelings;
  final List<String> activities;
  final String journal;
  final double sleepHours;
  final int waterIntake;
  final int exerciseMinutes;
  final DateTime? createdAt;

  MoodLog({
    this.id,
    required this.moodScore,
    required this.emoji,
    this.feelings = const [],
    this.activities = const [],
    this.journal = '',
    this.sleepHours = 0,
    this.waterIntake = 0,
    this.exerciseMinutes = 0,
    this.createdAt,
  });

  factory MoodLog.fromJson(Map<String, dynamic> json) {
    return MoodLog(
      id: json['_id'] ?? json['id'],
      moodScore: json['moodScore'] ?? 5,
      emoji: json['emoji'] ?? '😐',
      feelings: List<String>.from(json['feelings'] ?? []),
      activities: List<String>.from(json['activities'] ?? []),
      journal: json['journal'] ?? '',
      sleepHours: (json['sleepHours'] ?? 0).toDouble(),
      waterIntake: json['waterIntake'] ?? 0,
      exerciseMinutes: json['exerciseMinutes'] ?? 0,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'moodScore': moodScore,
    'emoji': emoji,
    'feelings': feelings,
    'activities': activities,
    'journal': journal,
    'sleepHours': sleepHours,
    'waterIntake': waterIntake,
    'exerciseMinutes': exerciseMinutes,
  };
}

class WeeklyMoodData {
  final String day;
  final String date;
  final double? avgMood;
  final int count;

  WeeklyMoodData({required this.day, required this.date, this.avgMood, this.count = 0});

  factory WeeklyMoodData.fromJson(Map<String, dynamic> json) {
    return WeeklyMoodData(
      day: json['day'] ?? '',
      date: json['date'] ?? '',
      avgMood: json['avgMood']?.toDouble(),
      count: json['count'] ?? 0,
    );
  }
}
