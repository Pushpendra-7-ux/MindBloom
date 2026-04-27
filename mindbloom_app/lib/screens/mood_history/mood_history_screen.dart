import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../providers/mood_provider.dart';
import '../../widgets/custom_card.dart';

class MoodHistoryScreen extends ConsumerStatefulWidget {
  const MoodHistoryScreen({super.key});

  @override
  ConsumerState<MoodHistoryScreen> createState() => _MoodHistoryScreenState();
}

class _MoodHistoryScreenState extends ConsumerState<MoodHistoryScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(moodProvider.notifier).fetchMoodHistory(days: 30));
  }

  @override
  Widget build(BuildContext context) {
    final moodState = ref.watch(moodProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mood History')),
      body: moodState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : moodState.history.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('📊', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 16),
                      Text('No mood logs yet', style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 8),
                      Text('Start checking in to see your history', style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: moodState.history.length,
                  itemBuilder: (context, index) {
                    final log = moodState.history[index];
                    final date = log.createdAt;
                    final dateStr = date != null
                        ? DateFormat('MMM d, y • h:mm a').format(date)
                        : 'Unknown date';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: CustomCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(log.emoji, style: const TextStyle(fontSize: 32)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Score: ${log.moodScore}/10',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                                      ),
                                      Text(dateStr, style: Theme.of(context).textTheme.bodySmall),
                                    ],
                                  ),
                                ),
                                _buildMoodBadge(log.moodScore),
                              ],
                            ),
                            if (log.feelings.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: log.feelings.map((f) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryPurple.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(f, style: TextStyle(fontSize: 12, color: AppColors.primaryPurple)),
                                )).toList(),
                              ),
                            ],
                            if (log.journal.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(log.journal, style: Theme.of(context).textTheme.bodySmall, maxLines: 3, overflow: TextOverflow.ellipsis),
                            ],
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                _infoChip('😴 ${log.sleepHours}h'),
                                const SizedBox(width: 8),
                                _infoChip('💧 ${log.waterIntake}'),
                                const SizedBox(width: 8),
                                _infoChip('🏃 ${log.exerciseMinutes}m'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildMoodBadge(int score) {
    Color color;
    if (score <= 3) {
      color = AppColors.coral;
    } else if (score <= 5) {
      color = AppColors.warmAmber;
    } else if (score <= 7) {
      color = AppColors.calmBlue;
    } else {
      color = AppColors.softGreen;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$score/10',
        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13),
      ),
    );
  }

  Widget _infoChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: const TextStyle(fontSize: 11)),
    );
  }
}
