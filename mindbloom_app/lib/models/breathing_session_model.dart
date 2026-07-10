/// A record of a single completed breathing exercise session.
///
/// Stores the program used, duration, rounds completed, and timestamp
/// so the user can review their breathing practice history.
class BreathingSession {
  final String id;
  final String programName;
  final String programEmoji;
  final int durationSeconds;
  final int roundsCompleted;
  final DateTime completedAt;

  BreathingSession({
    required this.id,
    required this.programName,
    required this.programEmoji,
    required this.durationSeconds,
    required this.roundsCompleted,
    required this.completedAt,
  });

  factory BreathingSession.fromJson(Map<String, dynamic> json) {
    return BreathingSession(
      id: json['id'] as String,
      programName: json['programName'] as String,
      programEmoji: json['programEmoji'] as String? ?? '🌬️',
      durationSeconds: json['durationSeconds'] as int,
      roundsCompleted: json['roundsCompleted'] as int,
      completedAt: DateTime.parse(json['completedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'programName': programName,
        'programEmoji': programEmoji,
        'durationSeconds': durationSeconds,
        'roundsCompleted': roundsCompleted,
        'completedAt': completedAt.toIso8601String(),
      };

  /// Human-readable duration string (e.g. "3m 20s").
  String get formattedDuration {
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    if (minutes == 0) return '${seconds}s';
    if (seconds == 0) return '${minutes}m';
    return '${minutes}m ${seconds}s';
  }
}
