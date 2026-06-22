import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/theme.dart';
import '../../config/daily_quotes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/mood_provider.dart';
import '../../providers/water_provider.dart';
import '../../widgets/custom_card.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _isQuoteFavorited = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(moodProvider.notifier).fetchLatestMood();
      ref.read(moodProvider.notifier).fetchWeeklyData();
      _checkIfQuoteFavorited();
    });
  }

  Future<void> _checkIfQuoteFavorited() async {
    final prefs = await SharedPreferences.getInstance();
    final favoritedList = prefs.getStringList('favorited_quotes') ?? [];
    final dailyQuote = DailyQuotes.getTodayQuote();
    final quoteKey = '${dailyQuote['text']}~${dailyQuote['author']}';
    if (mounted) {
      setState(() {
        _isQuoteFavorited = favoritedList.contains(quoteKey);
      });
    }
  }

  Future<void> _toggleFavoriteQuote() async {
    final prefs = await SharedPreferences.getInstance();
    final favoritedList = prefs.getStringList('favorited_quotes') ?? [];
    final dailyQuote = DailyQuotes.getTodayQuote();
    final quoteKey = '${dailyQuote['text']}~${dailyQuote['author']}';
    
    if (favoritedList.contains(quoteKey)) {
      favoritedList.remove(quoteKey);
      setState(() => _isQuoteFavorited = false);
    } else {
      favoritedList.add(quoteKey);
      setState(() => _isQuoteFavorited = true);
    }
    
    await prefs.setStringList('favorited_quotes', favoritedList);
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final moodState = ref.watch(moodProvider);
    final user = authState.user;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(moodProvider.notifier).fetchLatestMood();
            await ref.read(moodProvider.notifier).fetchWeeklyData();
            await ref.read(authStateProvider.notifier).refreshUser();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Greeting card
                _buildGreetingCard(context, user?.name ?? 'Friend'),
                const SizedBox(height: 20),

                // Streak & Mood badge row
                Row(
                  children: [
                    Expanded(
                      child: CustomCard(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Text('🔥', style: TextStyle(fontSize: 28)),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${user?.streak.current ?? 0} days',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                Text('Current streak', style: Theme.of(context).textTheme.bodySmall),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomCard(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Text(
                              moodState.latestMood?.emoji ?? '😐',
                              style: const TextStyle(fontSize: 28),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${moodState.latestMood?.moodScore ?? '-'}/10',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                Text('Latest mood', style: Theme.of(context).textTheme.bodySmall),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Wellness cards grid
                Text('Wellness Activities', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 500;
                    return GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: isWide ? 4 : 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: isWide ? 1.2 : 1.5,
                      children: [
                        _buildWellnessCard(
                          context, 'Meditation', Icons.self_improvement_rounded,
                          AppColors.primaryGradient, () => context.push('/meditation'),
                        ),
                        _buildWellnessCard(
                          context, 'Breathing', Icons.air_rounded,
                          AppColors.greenGradient, () => context.push('/breathing'),
                        ),
                        _buildWellnessCard(
                          context, 'Mood Log', Icons.history_rounded,
                          AppColors.warmGradient, () => context.push('/mood-history'),
                        ),
                        _buildWellnessCard(
                          context, 'Appointments', Icons.calendar_today_rounded,
                          AppColors.blueGradient, () => context.push('/appointments'),
                        ),
                      ],
                    );
                  }
                ),
                const SizedBox(height: 20),

                // Hydration Tracker Skeleton Card
                _buildWaterTracker(context),
                const SizedBox(height: 24),

                // Weekly mood chart
                Text('7-Day Mood Trend', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 12),
                CustomCard(
                  child: SizedBox(
                    height: 200,
                    child: moodState.weeklyData.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.insights_rounded, size: 40, color: Colors.grey[400]),
                                const SizedBox(height: 8),
                                Text('No mood data yet', style: Theme.of(context).textTheme.bodyMedium),
                                const SizedBox(height: 4),
                                Text('Start a check-in to see your trends!', style: Theme.of(context).textTheme.bodySmall),
                              ],
                            ),
                          )
                        : _buildMoodChart(moodState),
                  ),
                ),
                const SizedBox(height: 24),

                // Wellness score
                Text('Wellness Score', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 12),
                CustomCard(
                  child: Row(
                    children: [
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 80,
                              height: 80,
                              child: CircularProgressIndicator(
                                value: (user?.wellnessScore ?? 50) / 100,
                                strokeWidth: 8,
                                backgroundColor: AppColors.primaryPurple.withValues(alpha: 0.15),
                                valueColor: const AlwaysStoppedAnimation(AppColors.primaryPurple),
                                strokeCap: StrokeCap.round,
                              ),
                            ),
                            Text(
                              '${user?.wellnessScore ?? 50}',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryPurple,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getWellnessLabel(user?.wellnessScore ?? 50),
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Based on your recent mood check-ins and activity',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Daily reminder banner
                CustomCard(
                  gradient: AppColors.primaryGradient,
                  child: Row(
                    children: [
                      const Icon(Icons.tips_and_updates_rounded, color: Colors.white, size: 28),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Daily Check-in Reminder',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'How are you feeling today? Take a moment to check in.',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  onTap: () => context.go('/checkin'),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGreetingCard(BuildContext context, String name) {
    final dailyQuote = DailyQuotes.getTodayQuote();

    return CustomCard(
      gradient: LinearGradient(
        colors: [
          AppColors.primaryPurple,
          AppColors.primaryPurple.withValues(alpha: 0.8),
          AppColors.calmBlue,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_getGreeting()} ☀️',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      name,
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  _isQuoteFavorited ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: Colors.white,
                  size: 26,
                ),
                onPressed: _toggleFavoriteQuote,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '"${dailyQuote['text']}"',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.7),
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '— ${dailyQuote['author']}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWellnessCard(
    BuildContext context, String title, IconData icon,
    LinearGradient gradient, VoidCallback onTap,
  ) {
    return CustomCard(
      gradient: gradient,
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodChart(MoodState moodState) {
    final spots = <FlSpot>[];
    for (int i = 0; i < moodState.weeklyData.length; i++) {
      final data = moodState.weeklyData[i];
      if (data.avgMood != null) {
        spots.add(FlSpot(i.toDouble(), data.avgMood!));
      }
    }

    if (spots.isEmpty) {
      return const Center(child: Text('Not enough data'));
    }

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < moodState.weeklyData.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      moodState.weeklyData[index].day,
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minY: 0,
        maxY: 10,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            gradient: AppColors.primaryGradient,
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                radius: 4,
                color: AppColors.primaryPurple,
                strokeWidth: 2,
                strokeColor: Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryPurple.withValues(alpha: 0.2),
                  AppColors.primaryPurple.withValues(alpha: 0.02),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getWellnessLabel(int score) {
    if (score >= 80) return 'Excellent! 🌟';
    if (score >= 60) return 'Good 😊';
    if (score >= 40) return 'Fair 🙂';
    if (score >= 20) return 'Needs Attention 😐';
    return 'Reach Out for Help 💛';
  }

  Widget _buildWaterTracker(BuildContext context) {
    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Hydration Tracker 💧',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Text(
                'Goal: 8 cups',
                style: TextStyle(
                  color: AppColors.primaryPurple,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Track your daily water intake to stay hydrated and active.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: 0.0,
            backgroundColor: Colors.grey.withValues(alpha: 0.1),
            valueColor: const AlwaysStoppedAnimation(AppColors.calmBlue),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}
