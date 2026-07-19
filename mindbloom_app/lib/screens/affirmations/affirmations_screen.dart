import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../config/daily_affirmations.dart';
import '../../config/theme.dart';
import '../../providers/affirmation_provider.dart';
import '../../services/haptic_util.dart';
import '../../widgets/custom_card.dart';

class AffirmationsScreen extends ConsumerStatefulWidget {
  const AffirmationsScreen({super.key});

  @override
  ConsumerState<AffirmationsScreen> createState() => _AffirmationsScreenState();
}

class _AffirmationsScreenState extends ConsumerState<AffirmationsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _animateTransition(VoidCallback action) {
    _animController.reverse().then((_) {
      action();
      _animController.forward();
    });
    HapticUtil.selectionClick();
  }

  void _shareAffirmation(String text, String category) {
    final msg = '"$text"'
        '\n— $category affirmation'
        '\n\n🌸 Shared from MindBloom';
    Share.share(msg);
  }

  Color _categoryColor(String category) {
    switch (category) {
      case 'Self-Love':
        return AppColors.coral;
      case 'Resilience':
        return AppColors.softGreen;
      case 'Gratitude':
        return AppColors.warmAmber;
      case 'Calm':
        return AppColors.calmBlue;
      case 'Growth':
        return AppColors.primaryPurple;
      case 'Confidence':
        return AppColors.lavender;
      default:
        return AppColors.primaryPurple;
    }
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Self-Love':
        return Icons.favorite_rounded;
      case 'Resilience':
        return Icons.shield_rounded;
      case 'Gratitude':
        return Icons.volunteer_activism_rounded;
      case 'Calm':
        return Icons.spa_rounded;
      case 'Growth':
        return Icons.trending_up_rounded;
      case 'Confidence':
        return Icons.star_rounded;
      default:
        return Icons.auto_awesome_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final affState = ref.watch(affirmationProvider);
    final notifier = ref.read(affirmationProvider.notifier);
    final current = affState.current;
    final category = current['category'] ?? '';
    final text = current['text'] ?? '';
    final isFav = affState.isFavorited;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Affirmations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Create Custom Affirmation',
            onPressed: () => _showCreateAffirmationSheet(context, notifier),
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_rounded),
            tooltip: 'Saved Affirmations',
            onPressed: () => _showSavedSheet(context, notifier),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              // Category filter chips
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildFilterChip(context, 'All', null, affState.activeCategory),
                    ...DailyAffirmations.categories.map((cat) =>
                        _buildFilterChip(context, cat, cat, affState.activeCategory)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Main affirmation card
              FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: CustomCard(
                    gradient: LinearGradient(
                      colors: [
                        _categoryColor(category),
                        _categoryColor(category).withValues(alpha: 0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      children: [
                        Icon(
                          _categoryIcon(category),
                          size: 44,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          text,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                height: 1.5,
                              ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            category,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Navigation & actions row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    Icons.arrow_back_ios_rounded,
                    'Previous',
                    () => _animateTransition(() => notifier.previous()),
                  ),
                  _buildActionButton(
                    isFav ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                    isFav ? 'Saved' : 'Save',
                    () {
                      notifier.toggleFavorite();
                      HapticUtil.mediumImpact();
                    },
                    highlight: isFav,
                  ),
                  _buildActionButton(
                    Icons.share_rounded,
                    'Share',
                    () => _shareAffirmation(text, category),
                  ),
                  _buildActionButton(
                    Icons.arrow_forward_ios_rounded,
                    'Next',
                    () => _animateTransition(() => notifier.next()),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Counter
              Text(
                '${affState.currentIndex + 1} of ${affState.affirmations.length}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                    ),
              ),
              const SizedBox(height: 24),

              // Tip card
              CustomCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Text('💡', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Read your affirmation aloud and take a deep breath. Repetition builds belief.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(
      BuildContext context, String label, String? category, String? active) {
    final isActive = category == active || (category == null && active == null);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isActive,
        onSelected: (_) {
          ref.read(affirmationProvider.notifier).filterByCategory(category);
          _animController.forward(from: 0);
          HapticUtil.lightImpact();
        },
        selectedColor: AppColors.primaryPurple.withValues(alpha: 0.15),
        checkmarkColor: AppColors.primaryPurple,
        labelStyle: TextStyle(
          color: isActive ? AppColors.primaryPurple : null,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildActionButton(
      IconData icon, String label, VoidCallback onTap,
      {bool highlight = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: highlight
                  ? AppColors.primaryPurple.withValues(alpha: 0.12)
                  : Theme.of(context).cardTheme.color ?? Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: highlight
                    ? AppColors.primaryPurple.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.08),
              ),
            ),
            child: Icon(
              icon,
              color: highlight ? AppColors.primaryPurple : null,
              size: 22,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }

  void _showCreateAffirmationSheet(BuildContext context, AffirmationNotifier notifier) {
    final textController = TextEditingController();
    String selectedCategory = DailyAffirmations.categories.first;
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Text('✨', style: TextStyle(fontSize: 22)),
                        const SizedBox(width: 10),
                        Text(
                          'Create Your Affirmation',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text('Choose a Category', style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: DailyAffirmations.categories.map((cat) {
                        final isSelected = selectedCategory == cat;
                        return ChoiceChip(
                          label: Text(cat),
                          selected: isSelected,
                          onSelected: (_) => setSheetState(() => selectedCategory = cat),
                          selectedColor: _categoryColor(cat).withValues(alpha: 0.18),
                          checkmarkColor: _categoryColor(cat),
                          labelStyle: TextStyle(
                            color: isSelected ? _categoryColor(cat) : null,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    Text('Your Affirmation', style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 8),
                    Form(
                      key: formKey,
                      child: TextFormField(
                        controller: textController,
                        maxLines: 4,
                        maxLength: 150,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: 'e.g. I am capable of creating the life I desire.',
                          filled: true,
                          fillColor: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white.withValues(alpha: 0.06)
                              : Colors.grey.withValues(alpha: 0.07),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.all(14),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please write an affirmation.';
                          }
                          if (value.trim().length < 10) {
                            return 'Affirmation must be at least 10 characters.';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.auto_awesome_rounded),
                        label: const Text('Save Affirmation'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () async {
                          if (formKey.currentState!.validate()) {
                            await notifier.addCustomAffirmation(
                              textController.text,
                              selectedCategory,
                            );
                            if (context.mounted) {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Text('✨'),
                                      const SizedBox(width: 8),
                                      const Expanded(child: Text('Custom affirmation saved!')),
                                    ],
                                  ),
                                  backgroundColor: AppColors.primaryPurple,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showSavedSheet(BuildContext context, AffirmationNotifier notifier) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final favorites = notifier.getFavorites();
            return Container(
              height: MediaQuery.of(context).size.height * 0.65,
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
                        const Text('🔖', style: TextStyle(fontSize: 22)),
                        const SizedBox(width: 10),
                        Text(
                          'Saved Affirmations',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: favorites.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.bookmark_border_rounded,
                                    size: 48, color: Colors.grey[400]),
                                const SizedBox(height: 12),
                                Text('No saved affirmations yet',
                                    style: Theme.of(context).textTheme.bodyMedium),
                                const SizedBox(height: 4),
                                Text('Tap the bookmark icon to save your favourites',
                                    style: Theme.of(context).textTheme.bodySmall),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: favorites.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final aff = favorites[index];
                              final isCustom = aff['isCustom'] == 'true';
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                leading: Icon(
                                  _categoryIcon(aff['category'] ?? ''),
                                  color: _categoryColor(aff['category'] ?? ''),
                                ),
                                title: Text(
                                  aff['text'] ?? '',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                subtitle: Row(
                                  children: [
                                    Text(aff['category'] ?? ''),
                                    if (isCustom) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryPurple.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '✦ Custom',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: AppColors.primaryPurple,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                trailing: isCustom
                                    ? IconButton(
                                        icon: const Icon(Icons.delete_outline_rounded, size: 20),
                                        color: Colors.redAccent,
                                        tooltip: 'Delete custom affirmation',
                                        onPressed: () async {
                                          await notifier.deleteCustomAffirmation(aff['text'] ?? '');
                                          setSheetState(() {});
                                        },
                                      )
                                    : IconButton(
                                        icon: const Icon(Icons.share_rounded, size: 20),
                                        onPressed: () => _shareAffirmation(
                                            aff['text'] ?? '', aff['category'] ?? ''),
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
}
