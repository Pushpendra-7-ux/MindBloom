import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../providers/mood_provider.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/mood_analytics_card.dart';

class MoodHistoryScreen extends ConsumerStatefulWidget {
  const MoodHistoryScreen({super.key});

  @override
  ConsumerState<MoodHistoryScreen> createState() => _MoodHistoryScreenState();
}

class _MoodHistoryScreenState extends ConsumerState<MoodHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'all'; // 'all', 'positive', 'neutral', 'negative'
  int _analyticsDays = 30;
  final Set<int> _expandedJournals = {};

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(moodProvider.notifier).fetchMoodHistory(days: 30));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final moodState = ref.watch(moodProvider);
    final analytics = ref.read(moodProvider.notifier).calculateAnalytics(days: _analyticsDays);

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
              : Column(
                  children: [
                    // Mood Analytics Summary Card
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: MoodAnalyticsCard(
                        analytics: analytics,
                        onPeriodChanged: (days) {
                          setState(() => _analyticsDays = days);
                        },
                        onFeelingSelected: (feeling) {
                          setState(() {
                            _searchController.text = feeling;
                            _searchQuery = feeling.toLowerCase();
                          });
                        },
                      ),
                    ),
                    // Search bar
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search journals & feelings...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white.withValues(alpha: 0.06)
                              : Colors.grey.withValues(alpha: 0.08),
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() => _searchQuery = value.trim().toLowerCase());
                        },
                      ),
                    ),
                    // Filter chips
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          _buildFilterChip('All', 'all', Icons.grid_view_rounded),
                          const SizedBox(width: 8),
                          _buildFilterChip('Positive', 'positive', Icons.sentiment_very_satisfied),
                          const SizedBox(width: 8),
                          _buildFilterChip('Neutral', 'neutral', Icons.sentiment_neutral),
                          const SizedBox(width: 8),
                          _buildFilterChip('Negative', 'negative', Icons.sentiment_very_dissatisfied),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // List
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          final filteredLogs = moodState.history.where((log) {
                            // Category filter
                            if (_selectedFilter == 'positive' && log.moodScore < 8) return false;
                            if (_selectedFilter == 'neutral' && (log.moodScore < 4 || log.moodScore > 7)) return false;
                            if (_selectedFilter == 'negative' && log.moodScore > 3) return false;

                            // Search filter
                            if (_searchQuery.isNotEmpty) {
                              final journalMatch = log.journal.toLowerCase().contains(_searchQuery);
                              final feelingsMatch = log.feelings.any((f) => f.toLowerCase().contains(_searchQuery));
                              if (!journalMatch && !feelingsMatch) return false;
                            }
                            return true;
                          }).toList();

                          if (filteredLogs.isEmpty) {
                            return Center(
                              child: SingleChildScrollView(
                                child: Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text('🔍', style: TextStyle(fontSize: 48)),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No matching results',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Try adjusting your search query or changing filters.',
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              color: Colors.grey,
                                            ),
                                      ),
                                      const SizedBox(height: 24),
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() {
                                            _searchQuery = '';
                                            _selectedFilter = 'all';
                                          });
                                        },
                                        icon: const Icon(Icons.refresh),
                                        label: const Text('Reset Search & Filters'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primaryPurple,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }

                          return ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredLogs.length,
                            itemBuilder: (context, index) {
                              final log = filteredLogs[index];
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
                                    _buildExpandableJournal(log.journal, index),
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
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildFilterChip(String label, String value, IconData icon) {
    final isSelected = _selectedFilter == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedFilter = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryPurple.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? AppColors.primaryPurple
                  : Colors.grey.withValues(alpha: 0.2),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: isSelected ? AppColors.primaryPurple : AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? AppColors.primaryPurple : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
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

  Widget _buildExpandableJournal(String journal, int index) {
    final isLong = journal.length > 120;
    final isExpanded = _expandedJournals.contains(index);

    if (!isLong) {
      return Text(journal, style: Theme.of(context).textTheme.bodySmall);
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isExpanded) {
            _expandedJournals.remove(index);
          } else {
            _expandedJournals.add(index);
          }
        });
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedCrossFade(
            firstChild: Text(
              '${journal.substring(0, 120)}...',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            secondChild: Text(
              journal,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
          const SizedBox(height: 4),
          Text(
            isExpanded ? 'Show less' : 'Read more',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.primaryPurple,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
