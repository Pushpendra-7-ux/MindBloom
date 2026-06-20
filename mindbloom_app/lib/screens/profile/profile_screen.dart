import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/custom_card.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final themeMode = ref.watch(themeProvider);
    final user = authState.user;
    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar area
            Center(
              child: Column(
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        (user?.name ?? 'U')[0].toUpperCase(),
                        style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(user?.name ?? 'User', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 4),
                  Text(user?.email ?? '', style: Theme.of(context).textTheme.bodyMedium),
                  if (user?.category != null && user!.category != 'other') ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryPurple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        user.category[0].toUpperCase() + user.category.substring(1),
                        style: TextStyle(color: AppColors.primaryPurple, fontWeight: FontWeight.w500, fontSize: 13),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Stats row
            Row(
              children: [
                Expanded(child: _statCard(context, '🔥', '${user?.streak.current ?? 0}', 'Day Streak')),
                const SizedBox(width: 12),
                Expanded(child: _statCard(context, '🏆', '${user?.streak.longest ?? 0}', 'Best Streak')),
                const SizedBox(width: 12),
                Expanded(child: _statCard(context, '💫', '${user?.wellnessScore ?? 50}', 'Wellness')),
              ],
            ),
            const SizedBox(height: 24),

            // Dark mode toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.08),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.dark_mode_outlined, size: 22, color: AppColors.textSecondary),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text('Dark Mode', style: Theme.of(context).textTheme.titleMedium),
                  ),
                  Switch(
                    value: isDark,
                    onChanged: (_) => ref.read(themeProvider.notifier).toggleTheme(),
                    activeTrackColor: AppColors.primaryPurple,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Menu items
            _menuItem(context, Icons.favorite_rounded, 'Saved Quotes', () => _showSavedQuotes(context)),
            _menuItem(context, Icons.notifications_outlined, 'Notifications', () {}),
            _menuItem(context, Icons.security_outlined, 'Privacy & Security', () {}),
            _menuItem(context, Icons.help_outline_rounded, 'Help & Support', () {}),
            _menuItem(context, Icons.info_outline_rounded, 'About MindBloom', () {}),
            const SizedBox(height: 20),

            // Logout button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await ref.read(authStateProvider.notifier).logout();
                  if (context.mounted) context.go('/login');
                },
                icon: const Icon(Icons.logout_rounded, color: AppColors.coral),
                label: const Text('Sign Out', style: TextStyle(color: AppColors.coral)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.coral),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('MindBloom v1.0.0', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showSavedQuotes(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final favoritedList = prefs.getStringList('favorited_quotes') ?? [];

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SavedQuotesSheet(
        initialQuotes: favoritedList,
      ),
    );
  }

  Widget _statCard(BuildContext context, String emoji, String value, String label) {
    return CustomCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 6),
          Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _menuItem(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: AppColors.textSecondary),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: Theme.of(context).textTheme.titleMedium)),
            const Icon(Icons.chevron_right, size: 20, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

/// Stateful bottom sheet that can remove quotes from the list interactively.
class _SavedQuotesSheet extends StatefulWidget {
  final List<String> initialQuotes;

  const _SavedQuotesSheet({required this.initialQuotes});

  @override
  State<_SavedQuotesSheet> createState() => _SavedQuotesSheetState();
}

class _SavedQuotesSheetState extends State<_SavedQuotesSheet> {
  late List<String> _quotes;

  @override
  void initState() {
    super.initState();
    _quotes = List.from(widget.initialQuotes);
  }

  Future<void> _removeQuote(int index) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _quotes.removeAt(index);
    });
    await prefs.setStringList('favorited_quotes', _quotes);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.favorite_rounded, color: AppColors.coral, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      'Saved Quotes',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    Text(
                      '${_quotes.length}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const Divider(),
              // Quote list
              Expanded(
                child: _quotes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('💭', style: TextStyle(fontSize: 48)),
                            const SizedBox(height: 16),
                            Text(
                              'No saved quotes yet',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap the heart on your daily quote\nto save it here.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _quotes.length,
                        itemBuilder: (context, index) {
                          final parts = _quotes[index].split('~');
                          final text = parts.isNotEmpty ? parts[0] : '';
                          final author = parts.length > 1 ? parts[1] : 'Unknown';

                          return Dismissible(
                            key: ValueKey(_quotes[index]),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: AppColors.coral.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.delete_outline_rounded, color: AppColors.coral),
                            ),
                            onDismissed: (_) => _removeQuote(index),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primaryPurple.withValues(alpha: 0.08),
                                    AppColors.calmBlue.withValues(alpha: 0.05),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: AppColors.primaryPurple.withValues(alpha: 0.15),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '"$text"',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontStyle: FontStyle.italic,
                                      height: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Container(
                                        width: 3,
                                        height: 14,
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryPurple,
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '— $author',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: AppColors.primaryPurple,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
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
  }
}
