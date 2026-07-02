class MeditationSession {
  final String id;
  final String title;
  final int durationSeconds;
  final DateTime date;
  final bool isCustom;

  MeditationSession({
    required this.id,
    required this.title,
    required this.durationSeconds,
    required this.date,
    this.isCustom = false,
  });

  factory MeditationSession.fromJson(Map<String, dynamic> json) {
    return MeditationSession(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      durationSeconds: json['durationSeconds'] ?? 0,
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      isCustom: json['isCustom'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'durationSeconds': durationSeconds,
        'date': date.toIso8601String(),
        'isCustom': isCustom,
      };
}
