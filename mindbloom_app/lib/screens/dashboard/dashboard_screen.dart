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
import '../../providers/gratitude_provider.dart';
import '../../services/haptic_util.dart';
import '../../widgets/custom_card.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _isQuoteFavorited = false;
  final _gratitudeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(moodProvider.notifier).fetchLatestMood();
      ref.read(moodProvider.notifier).fetchWeeklyData();
      _checkIfQuoteFavorited();
    });
  }

  @override
  void dispose() {
    _gratitudeController.dispose();
    super.dispose();
  }

  // Submit gratitude entry
  void _submitGratitude() {
    final text = _gratitudeController.text.trim();
    if (text.isEmpty) return;
    // Add entry via provider
    ref.read(gratitudeProvider.notifier).add(text);
    _gratitudeController.clear();
    // Haptic feedback
    HapticUtil.mediumImpact();
    // Celebration UI
    _celebrateGratitude();
  }

  // Show a celebration SnackBar
  void _celebrateGratitude() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Text('🎉 Added!'),
            SizedBox(width: 8),
            Expanded(child: Text('Your gratitude entry was saved.')),
          ],
        ),
        backgroundColor: AppColors.warmAmber,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
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

  Future<List<Map<String, String>>> _getSavedQuotes() async {
    final prefs = await SharedPreferences.getInstance();
    final favoritedList = prefs.getStringList('favorited_quotes') ?? [];
    return favoritedList.map((q) {
      final parts = q.split('~');
      final text = parts.isNotEmpty ? parts[0] : '';
      final author = parts.length > 1 ? parts[1] : 'Unknown';
      return {'text': text, 'author': author, 'raw': q};
    }).toList();
  }

  Future<void> _unfavoriteQuote(String quoteKey) async {
    final prefs = await SharedPreferences.getInstance();
    final favoritedList = prefs.getStringList('favorited_quotes') ?? [];
    if (favoritedList.contains(quoteKey)) {
      favoritedList.remove(quoteKey);
      await prefs.setStringList('favorited_quotes', favoritedList);
      _checkIfQuoteFavorited();
    }
  }

  void _showSavedQuotes() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return FutureBuilder<List<Map<String, String>>>(
              future: _getSavedQuotes(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    height: MediaQuery.of(context).size.height * 0.7,
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: const Center(child: CircularProgressIndicator()),
                  );
                }

                final savedQuotes = snapshot.data ?? [];

                return Container(
                  height: MediaQuery.of(context).size.height * 0.7,
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            const Text('💖', style: TextStyle(fontSize: 22)),
                            const SizedBox(width: 10),
                            Text(
                              'Saved Quotes',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const Spacer(),
                            if (savedQuotes.isNotEmpty)
                              TextButton(
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Clear All'),
                                      content: const Text('Are you sure you want to remove all saved quotes?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          child: const Text('Clear'),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirm == true) {
                                    final prefs = await SharedPreferences.getInstance();
                                    await prefs.remove('favorited_quotes');
                                    _checkIfQuoteFavorited();
                                    setSheetState(() {});
                                  }
                                },
                                child: const Text(
                                  'Clear All',
                                  style: TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                              )
                            else
                              Text(
                                '${savedQuotes.length} saved',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: savedQuotes.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.bookmark_outline_rounded, size: 48, color: Colors.grey[400]),
                                    const SizedBox(height: 12),
                                    Text('No saved quotes yet!', style: Theme.of(context).textTheme.bodyLarge),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Tap the heart icon on your daily quote to save it here.',
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.all(20),
                                itemCount: savedQuotes.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final quote = savedQuotes[index];
                                  return Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).cardTheme.color,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: Colors.black.withValues(alpha: 0.08),
                                        width: 0.5,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '"${quote['text']}"',
                                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                      fontStyle: FontStyle.italic,
                                                    ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                '— ${quote['author']}',
                                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                      color: AppColors.textSecondary,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        IconButton(
                                          icon: const Icon(Icons.favorite_rounded, color: AppColors.error),
                                          onPressed: () async {
                                            await _unfavoriteQuote(quote['raw']!);
                                            setSheetState(() {});
                                          },
                                          tooltip: 'Remove from saved',
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
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

                // Gratitude Journal Card
                _buildGratitudeCard(context),
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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(
                      Icons.bookmarks_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    onPressed: _showSavedQuotes,
                    tooltip: 'Saved Quotes',
                  ),
                  const SizedBox(width: 12),
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

  void _celebrateGoal() {
    HapticUtil.mediumImpact();
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Text('🎉 ', style: TextStyle(fontSize: 20)),
            Expanded(
              child: Text(
                'Amazing job! You hit your daily water intake goal of 8 cups! 💧',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.softGreen,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showGratitudeGarden() {
    final allEntries = ref.read(gratitudeProvider).entries;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          builder: (_, controller) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Text('🌻', style: TextStyle(fontSize: 22)),
                        const SizedBox(width: 8),
                        Text(
                          'Gratitude Garden',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const Spacer(),
                        Text(
                          '${allEntries.length} total',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: allEntries.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.local_florist_rounded, size: 48, color: Colors.grey[300]),
                                const SizedBox(height: 12),
                                Text('No entries yet', style: Theme.of(context).textTheme.bodyMedium),
                                const SizedBox(height: 4),
                                Text('Start planting seeds of gratitude!', style: Theme.of(context).textTheme.bodySmall),
                              ],
                            ),
                          )
                        : ListView.separated(
                            controller: controller,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            itemCount: allEntries.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (_, index) {
                              final entry = allEntries[index];
                              final dateStr =
                                  '${entry.createdAt.day}/${entry.createdAt.month}/${entry.createdAt.year}';
                              final timeStr =
                                  '${entry.createdAt.hour.toString().padLeft(2, '0')}:${entry.createdAt.minute.toString().padLeft(2, '0')}';
                              return Dismissible(
                                key: Key(entry.id),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  decoration: BoxDecoration(
                                    color: AppColors.error.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.delete_rounded, color: AppColors.error),
                                ),
                                onDismissed: (_) {
                                  ref.read(gratitudeProvider.notifier).remove(entry.id);
                                  Navigator.of(ctx).pop();
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: AppColors.warmAmber.withValues(alpha: 0.06),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.warmAmber.withValues(alpha: 0.15),
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('🌱', style: TextStyle(fontSize: 18)),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              entry.text,
                                              style: Theme.of(context).textTheme.bodyLarge,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '$dateStr  •  $timeStr',
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                    color: AppColors.textSecondary,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGratitudeCard(BuildContext context) {
    final gratitudeState = ref.watch(gratitudeProvider);
    final todayEntries = gratitudeState.todayEntries;

    return CustomCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              gradient: AppColors.warmGradient,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Text('🌻', style: TextStyle(fontSize: 26)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gratitude Journal',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        todayEntries.isEmpty
                            ? 'What are you grateful for today?'
                            : '${todayEntries.length} entr${todayEntries.length == 1 ? 'y' : 'ies'} today',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _showGratitudeGarden,
                  icon: const Icon(Icons.grid_view_rounded, color: Colors.white, size: 22),
                  tooltip: 'View all entries',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Body: today's entries or empty state
          Padding(
            padding: const EdgeInsets.all(16),
            child: todayEntries.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        children: [
                          Icon(Icons.edit_note_rounded, size: 36, color: Colors.grey[400]),
                          const SizedBox(height: 8),
                          Text(
                            'Tap below to add what made you smile today ✨',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: todayEntries.map((entry) {
                      return Chip(
                        label: Text(
                          entry.text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        avatar: const Icon(Icons.favorite_rounded, size: 16, color: AppColors.warmAmber),
                        deleteIcon: const Icon(Icons.close_rounded, size: 16),
                        onDeleted: () {
                          ref.read(gratitudeProvider.notifier).remove(entry.id);
                        },
                        backgroundColor: AppColors.warmAmber.withValues(alpha: 0.1),
                        side: BorderSide(color: AppColors.warmAmber.withValues(alpha: 0.25)),
                      );
                    }).toList(),
                  ),
          ),

          // Input row
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _gratitudeController,
                    textCapitalization: TextCapitalization.sentences,
                    maxLength: 120,
                    decoration: InputDecoration(
                      hintText: 'I\'m grateful for…',
                      hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                      counterText: '',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.warmAmber.withValues(alpha: 0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.warmAmber.withValues(alpha: 0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.warmAmber, width: 1.5),
                      ),
                    ),
                    onSubmitted: (_) => _submitGratitude(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _submitGratitude,
                  icon: const Icon(Icons.add_circle_rounded),
                  color: AppColors.warmAmber,
                  iconSize: 32,
                  tooltip: 'Add gratitude',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaterTracker(BuildContext context) {
    final waterState = ref.watch(waterProvider);
    final cups = waterState.cups;
    final goal = waterState.goal;
    final progress = (cups / goal).clamp(0.0, 1.0);

    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Animated glass cylinder visual
          Container(
            width: 50,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10), top: Radius.circular(4)),
              border: Border.all(color: AppColors.calmBlue.withValues(alpha: 0.4), width: 2.5),
              color: AppColors.calmBlue.withValues(alpha: 0.05),
            ),
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                  width: double.infinity,
                  height: 80 * progress,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.vertical(
                      bottom: const Radius.circular(8),
                      top: Radius.circular(cups >= goal ? 2 : 0),
                    ),
                    gradient: LinearGradient(
                      colors: [
                        AppColors.calmBlue,
                        AppColors.calmBlue.withValues(alpha: 0.7),
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    '$cups',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: progress > 0.45 ? Colors.white : AppColors.primaryPurple,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Info & Progress bar
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Hydration Tracker 💧',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      '$cups / $goal cups',
                      style: const TextStyle(
                        color: AppColors.primaryPurple,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  cups >= goal
                      ? 'Goal achieved! You are fully hydrated. 🎉'
                      : 'Keep drinking water to stay refreshed.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey.withValues(alpha: 0.1),
                  valueColor: const AlwaysStoppedAnimation(AppColors.calmBlue),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton.outlined(
                      onPressed: cups <= 0
                          ? null
                          : () {
                              HapticUtil.selectionClick();
                              ref.read(waterProvider.notifier).decrement();
                            },
                      icon: const Icon(Icons.remove_rounded),
                      style: IconButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        side: BorderSide(
                          color: AppColors.calmBlue.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton.filled(
                      onPressed: () {
                        HapticUtil.selectionClick();
                        ref.read(waterProvider.notifier).increment();
                        if (cups + 1 == goal) {
                          _celebrateGoal();
                        }
                      },
                      icon: const Icon(Icons.add_rounded),
                      style: IconButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        backgroundColor: AppColors.calmBlue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
