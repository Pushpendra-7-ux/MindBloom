import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../config/constants.dart';

class MoodSelector extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const MoodSelector({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Current emoji display
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            AppConstants.moodEmojis[selectedIndex],
            key: ValueKey(selectedIndex),
            style: const TextStyle(fontSize: 64),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _getMoodLabel(selectedIndex),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: _getMoodColor(selectedIndex),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 24),
        // Emoji row
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: AppConstants.moodEmojis.length,
            itemBuilder: (context, index) {
              final isSelected = index == selectedIndex;
              return GestureDetector(
                onTap: () => onSelected(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _getMoodColor(index).withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected
                        ? Border.all(color: _getMoodColor(index), width: 2)
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      AppConstants.moodEmojis[index],
                      style: TextStyle(fontSize: isSelected ? 28 : 22),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _getMoodLabel(int index) {
    final labels = [
      'Terrible', 'Very Bad', 'Bad', 'Low', 'Meh',
      'Okay', 'Good', 'Great', 'Amazing', 'Fantastic'
    ];
    return labels[index];
  }

  Color _getMoodColor(int index) {
    if (index <= 2) return AppColors.coral;
    if (index <= 4) return AppColors.warmAmber;
    if (index <= 6) return AppColors.calmBlue;
    return AppColors.softGreen;
  }
}
