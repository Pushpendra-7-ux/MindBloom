import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/mood_analytics_model.dart';
import 'custom_card.dart';

class MoodAnalyticsCard extends StatelessWidget {
  final MoodAnalytics analytics;
  final Function(int days) onPeriodChanged;
  final Function(String feeling)? onFeelingSelected;

  const MoodAnalyticsCard({
    super.key,
    required this.analytics,
    required this.onPeriodChanged,
    this.onFeelingSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('📊', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 8),
                  Text(
                    'Mood Insights',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              // Period selector pills
              Row(
                children: [
                  _periodPill(context, '7D', 7),
                  const SizedBox(width: 4),
                  _periodPill(context, '14D', 14),
                  const SizedBox(width: 4),
                  _periodPill(context, '30D', 30),
                  const SizedBox(width: 4),
                  _periodPill(context, 'All', 0),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (analytics.totalLogs == 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Log your mood to unlock personalized trend analytics.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white70 : AppColors.textSecondary,
                ),
              ),
            )
          else ...[
            // Key metrics row
            Row(
              children: [
                Expanded(
                  child: _metricBox(
                    context,
                    label: 'Avg Score',
                    value: '${analytics.averageScore}/10',
                    subtitle: analytics.summaryLabel,
                    color: _scoreColor(analytics.averageScore),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _metricBox(
                    context,
                    label: 'Active Streak',
                    value: '🔥 ${analytics.streakDays} ${analytics.streakDays == 1 ? 'day' : 'days'}',
                    subtitle: 'Check-in consistency',
                    color: AppColors.warmAmber,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _metricBox(
                    context,
                    label: 'Total Logs',
                    value: '📝 ${analytics.totalLogs}',
                    subtitle: analytics.filterDays == 0 ? 'All time' : 'Last ${analytics.filterDays}d',
                    color: AppColors.primaryPurple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Mood Distribution bar
            Text(
              'Mood Distribution',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 10,
                child: Row(
                  children: [
                    if (analytics.positiveCount > 0)
                      Expanded(
                        flex: analytics.positiveCount,
                        child: Container(color: AppColors.softGreen),
                      ),
                    if (analytics.neutralCount > 0)
                      Expanded(
                        flex: analytics.neutralCount,
                        child: Container(color: AppColors.warmAmber),
                      ),
                    if (analytics.negativeCount > 0)
                      Expanded(
                        flex: analytics.negativeCount,
                        child: Container(color: AppColors.coral),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Distribution Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _legendItem('Positive', '${analytics.positivePercentage.toStringAsFixed(0)}% (${analytics.positiveCount})', AppColors.softGreen),
                _legendItem('Neutral', '${analytics.neutralPercentage.toStringAsFixed(0)}% (${analytics.neutralCount})', AppColors.warmAmber),
                _legendItem('Negative', '${analytics.negativePercentage.toStringAsFixed(0)}% (${analytics.negativeCount})', AppColors.coral),
              ],
            ),
            if (analytics.topFeelings.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Text(
                'Frequent Feelings & Triggers',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: analytics.topFeelings.entries.map((entry) {
                  return GestureDetector(
                    onTap: () => onFeelingSelected?.call(entry.key),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryPurple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${entry.key} (${entry.value})',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.primaryPurple,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _periodPill(BuildContext context, String label, int days) {
    final isSelected = analytics.filterDays == days;
    return InkWell(
      onTap: () => onPeriodChanged(days),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryPurple : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryPurple : Colors.grey.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _metricBox(
    BuildContext context, {
    required String label,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 10, color: isDark ? Colors.white70 : AppColors.textSecondary),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(fontSize: 9, color: isDark ? Colors.white60 : Colors.grey.shade600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _legendItem(String label, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Color _scoreColor(double score) {
    if (score >= 8.0) return AppColors.softGreen;
    if (score >= 6.0) return AppColors.calmBlue;
    if (score >= 4.0) return AppColors.warmAmber;
    return AppColors.coral;
  }
}
