import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../providers/recommendation_provider.dart';
import '../../models/recommendation_model.dart';
import '../../widgets/custom_card.dart';

class RecommendationsScreen extends ConsumerWidget {
  const RecommendationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recState = ref.watch(recommendationProvider);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Recommendations'),
          bottom: TabBar(
            isScrollable: false,
            labelColor: AppColors.primaryPurple,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primaryPurple,
            indicatorWeight: 3,
            tabs: const [
              Tab(text: '📚 Books'),
              Tab(text: '🏃 Physical'),
              Tab(text: '🧘 Mind'),
              Tab(text: '🌿 Lifestyle'),
            ],
          ),
        ),
        body: recState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : recState.error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(recState.error!, style: Theme.of(context).textTheme.bodyLarge),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => ref.read(recommendationProvider.notifier).fetchRecommendations(moodScore: 5),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : recState.recommendations == null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('🌟', style: TextStyle(fontSize: 48)),
                            const SizedBox(height: 16),
                            Text('Complete a check-in to get\npersonalized recommendations',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          // Summary banner
                          if (recState.recommendations!.summary.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: CustomCard(
                                gradient: AppColors.primaryGradient,
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    const Text('✨', style: TextStyle(fontSize: 24)),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        recState.recommendations!.summary,
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          Expanded(
                            child: TabBarView(
                              children: [
                                _buildRecList(context, recState.recommendations!.books, AppColors.warmAmber),
                                _buildRecList(context, recState.recommendations!.physical, AppColors.softGreen),
                                _buildRecList(context, recState.recommendations!.mindSpirit, AppColors.primaryPurple),
                                _buildRecList(context, recState.recommendations!.lifestyle, AppColors.calmBlue),
                              ],
                            ),
                          ),
                        ],
                      ),
      ),
    );
  }

  Widget _buildRecList(BuildContext context, List<Recommendation> recs, Color accent) {
    if (recs.isEmpty) {
      return const Center(child: Text('No recommendations available'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: recs.length,
      itemBuilder: (context, index) {
        final rec = recs[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: CustomCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_getIcon(rec.icon), color: accent, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(rec.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                      if (rec.author != null) ...[
                        const SizedBox(height: 2),
                        Text('by ${rec.author}', style: TextStyle(fontSize: 12, color: accent)),
                      ],
                      if (rec.duration != null) ...[
                        const SizedBox(height: 2),
                        Text(rec.duration!, style: TextStyle(fontSize: 12, color: accent)),
                      ],
                      if (rec.frequency != null) ...[
                        const SizedBox(height: 2),
                        Text(rec.frequency!, style: TextStyle(fontSize: 12, color: accent)),
                      ],
                      const SizedBox(height: 6),
                      Text(rec.description, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getIcon(String icon) {
    switch (icon) {
      case 'book': return Icons.menu_book_rounded;
      case 'fitness': return Icons.fitness_center_rounded;
      case 'spa': return Icons.spa_rounded;
      case 'lifestyle': return Icons.eco_rounded;
      default: return Icons.star_rounded;
    }
  }
}
