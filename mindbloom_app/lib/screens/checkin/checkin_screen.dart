import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../models/mood_model.dart';
import '../../providers/mood_provider.dart';
import '../../providers/recommendation_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/mood_selector.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_card.dart';

class CheckinScreen extends ConsumerStatefulWidget {
  const CheckinScreen({super.key});

  @override
  ConsumerState<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends ConsumerState<CheckinScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  int _moodIndex = 4; // Default: Meh
  final Set<String> _selectedFeelings = {};
  final Set<String> _selectedActivities = {};
  final TextEditingController _journalController = TextEditingController();
  double _sleepHours = 7;
  int _waterIntake = 4;
  int _exerciseMinutes = 0;

  @override
  void dispose() {
    _pageController.dispose();
    _journalController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 3) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() => _currentStep++);
    } else {
      _submitCheckin();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() => _currentStep--);
    }
  }

  Future<void> _submitCheckin() async {
    final moodLog = MoodLog(
      moodScore: _moodIndex + 1,
      emoji: AppConstants.moodEmojis[_moodIndex],
      feelings: _selectedFeelings.toList(),
      activities: _selectedActivities.toList(),
      journal: _journalController.text,
      sleepHours: _sleepHours,
      waterIntake: _waterIntake,
      exerciseMinutes: _exerciseMinutes,
    );

    final success = await ref.read(moodProvider.notifier).submitCheckin(moodLog);

    if (success && mounted) {
      final user = ref.read(authStateProvider).user;
      ref.read(recommendationProvider.notifier).fetchRecommendations(
        moodScore: _moodIndex + 1,
        feelings: _selectedFeelings.toList(),
        activities: _selectedActivities.toList(),
        category: user?.category,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Mood logged successfully! 🌸'),
          backgroundColor: AppColors.softGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      context.push('/recommendations');
    }
  }

  @override
  Widget build(BuildContext context) {
    final moodState = ref.watch(moodProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Check-in'),
        leading: _currentStep > 0
            ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: _prevStep)
            : null,
      ),
      body: Column(
        children: [
          // Progress bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: List.generate(4, (index) {
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    height: 4,
                    decoration: BoxDecoration(
                      color: index <= _currentStep
                          ? AppColors.primaryPurple
                          : AppColors.primaryPurple.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),

          // Pages
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildMoodStep(context),
                _buildFeelingsStep(context),
                _buildActivitiesStep(context),
                _buildDetailsStep(context),
              ],
            ),
          ),

          // Next button
          Padding(
            padding: const EdgeInsets.all(20),
            child: CustomButton(
              label: _currentStep < 3 ? 'Continue' : 'Submit Check-in',
              onPressed: _nextStep,
              isLoading: moodState.isLoading,
              color: _currentStep < 3 ? AppColors.primaryPurple : AppColors.softGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodStep(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Text('How are you feeling?', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text('Select the emoji that best describes your mood', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 32),
          MoodSelector(
            selectedIndex: _moodIndex,
            onSelected: (index) => setState(() => _moodIndex = index),
          ),
          const SizedBox(height: 24),
          // Slider
          Text('Mood Score: ${_moodIndex + 1}/10', style: Theme.of(context).textTheme.titleMedium),
          Slider(
            value: _moodIndex.toDouble(),
            min: 0,
            max: 9,
            divisions: 9,
            activeColor: AppColors.primaryPurple,
            onChanged: (v) => setState(() => _moodIndex = v.round()),
          ),
        ],
      ),
    );
  }

  Widget _buildFeelingsStep(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What are you feeling?', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text('Select all that apply', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AppConstants.feelings.map((feeling) {
              final isSelected = _selectedFeelings.contains(feeling);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedFeelings.remove(feeling);
                    } else {
                      _selectedFeelings.add(feeling);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primaryPurple : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? AppColors.primaryPurple : Colors.black.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Text(
                    '${_getFeelingEmoji(feeling)} ${feeling[0].toUpperCase()}${feeling.substring(1)}',
                    style: TextStyle(
                      color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
                      fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActivitiesStep(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What have you been doing?', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text('Select your recent activities', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AppConstants.activities.map((activity) {
              final isSelected = _selectedActivities.contains(activity);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedActivities.remove(activity);
                    } else {
                      _selectedActivities.add(activity);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.softGreen : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? AppColors.softGreen : Colors.black.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Text(
                    '${_getActivityEmoji(activity)} ${activity[0].toUpperCase()}${activity.substring(1)}',
                    style: TextStyle(
                      color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
                      fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsStep(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('A few more details', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 24),

          // Sleep
          CustomCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('😴', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Text('Sleep: ${_sleepHours.toStringAsFixed(1)} hours', style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
                Slider(
                  value: _sleepHours,
                  min: 0,
                  max: 12,
                  divisions: 24,
                  activeColor: AppColors.calmBlue,
                  onChanged: (v) => setState(() => _sleepHours = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Water
          CustomCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('💧', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Text('Water: $_waterIntake glasses', style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
                Slider(
                  value: _waterIntake.toDouble(),
                  min: 0,
                  max: 15,
                  divisions: 15,
                  activeColor: AppColors.calmBlue,
                  onChanged: (v) => setState(() => _waterIntake = v.round()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Exercise
          CustomCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('🏃', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Text('Exercise: $_exerciseMinutes min', style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
                Slider(
                  value: _exerciseMinutes.toDouble(),
                  min: 0,
                  max: 120,
                  divisions: 24,
                  activeColor: AppColors.softGreen,
                  onChanged: (v) => setState(() => _exerciseMinutes = v.round()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Journal
          Text('Journal (optional)', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextFormField(
            controller: _journalController,
            maxLines: 4,
            maxLength: 1000,
            decoration: const InputDecoration(
              hintText: 'Write about your day...',
            ),
          ),
        ],
      ),
    );
  }

  String _getFeelingEmoji(String feeling) {
    const map = {
      'happy': '😊', 'sad': '😢', 'anxious': '😰', 'calm': '😌', 'stressed': '😤',
      'energetic': '⚡', 'tired': '😴', 'grateful': '🙏', 'angry': '😠', 'hopeful': '🌈',
      'lonely': '😔', 'loved': '❤️', 'confused': '😵', 'motivated': '💪', 'overwhelmed': '🌊',
    };
    return map[feeling] ?? '😶';
  }

  String _getActivityEmoji(String activity) {
    const map = {
      'exercise': '🏋️', 'meditation': '🧘', 'reading': '📚', 'socializing': '👥',
      'work': '💼', 'sleep': '😴', 'nature': '🌿', 'music': '🎵', 'cooking': '🍳',
      'journaling': '📝', 'therapy': '🗣️', 'gaming': '🎮', 'studying': '📖', 'walking': '🚶',
    };
    return map[activity] ?? '📌';
  }
}
