class MoodAnalytics {
  final int totalLogs;
  final double averageScore;
  final int positiveCount;
  final int neutralCount;
  final int negativeCount;
  final int streakDays;
  final Map<String, int> topFeelings;
  final int filterDays;

  const MoodAnalytics({
    required this.totalLogs,
    required this.averageScore,
    required this.positiveCount,
    required this.neutralCount,
    required this.negativeCount,
    required this.streakDays,
    required this.topFeelings,
    required this.filterDays,
  });

  double get positivePercentage => totalLogs == 0 ? 0.0 : (positiveCount / totalLogs) * 100;
  double get neutralPercentage => totalLogs == 0 ? 0.0 : (neutralCount / totalLogs) * 100;
  double get negativePercentage => totalLogs == 0 ? 0.0 : (negativeCount / totalLogs) * 100;

  String get summaryLabel {
    if (totalLogs == 0) return 'No Logs Yet';
    if (averageScore >= 8.0) return 'Mostly Thriving 😊';
    if (averageScore >= 6.0) return 'Generally Balanced 😌';
    if (averageScore >= 4.0) return 'Mixed / Neutral 😐';
    return 'Challenging Period 🌧️';
  }
}
