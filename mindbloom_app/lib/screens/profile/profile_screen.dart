import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
            const SizedBox(height: 32),

            // Stats row
            Row(
              children: [
                Expanded(child: _statCard(context, '🔥', '${user?.streak.current ?? 0}', 'Streak')),
                const SizedBox(width: 10),
                Expanded(child: _statCard(context, '🏆', '${user?.streak.longest ?? 0}', 'Best')),
                const SizedBox(width: 10),
                Expanded(child: _statCard(context, '💪', '${user?.wellnessScore ?? 50}', 'Score')),
              ],
            ),
            const SizedBox(height: 24),

            // Settings
            Text('Settings', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),

            // Dark mode toggle
            CustomCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    color: AppColors.primaryPurple, size: 22),
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
