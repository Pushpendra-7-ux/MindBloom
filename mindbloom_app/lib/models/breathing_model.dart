import 'package:flutter/material.dart';
import '../config/theme.dart';

class BreathingPhase {
  final String name;
  final int duration;
  final Color color;
  final String instruction;

  const BreathingPhase({
    required this.name,
    required this.duration,
    required this.color,
    required this.instruction,
  });
}

class BreathingProgram {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final List<BreathingPhase> phases;

  const BreathingProgram({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.phases,
  });

  int get totalDuration => phases.fold(0, (sum, phase) => sum + phase.duration);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'emoji': emoji,
        'phases': phases.map((p) => {
              'name': p.name,
              'duration': p.duration,
              'colorValue': p.color.value,
              'instruction': p.instruction,
            }).toList(),
      };

  factory BreathingProgram.fromJson(Map<String, dynamic> json) {
    return BreathingProgram(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      emoji: json['emoji'] as String,
      phases: (json['phases'] as List).map((p) => BreathingPhase(
            name: p['name'] as String,
            duration: p['duration'] as int,
            color: Color(p['colorValue'] as int),
            instruction: p['instruction'] as String,
          )).toList(),
    );
  }

  static BreathingProgram createCustom({
    required int inhale,
    required int hold,
    required int exhale,
    required int holdEmpty,
  }) {
    return BreathingProgram(
      id: 'custom',
      name: 'Custom Breath',
      description: 'Your personalized breathing rhythm.',
      emoji: '✨',
      phases: [
        BreathingPhase(
          name: 'Breathe In',
          duration: inhale,
          color: AppColors.calmBlue,
          instruction: 'Inhale slowly and fill your lungs.',
        ),
        if (hold > 0)
          BreathingPhase(
            name: 'Hold',
            duration: hold,
            color: AppColors.primaryPurple,
            instruction: 'Hold the breath in and relax.',
          ),
        BreathingPhase(
          name: 'Breathe Out',
          duration: exhale,
          color: AppColors.softGreen,
          instruction: 'Exhale completely and release.',
        ),
        if (holdEmpty > 0)
          BreathingPhase(
            name: 'Hold Empty',
            duration: holdEmpty,
            color: AppColors.warmAmber,
            instruction: 'Hold empty before the next breath.',
          ),
      ],
    );
  }

  static final List<BreathingProgram> presets = [
    BreathingProgram(
      id: '478',
      name: '4-7-8 Relax',
      description: 'Natural tranquilizer for the nervous system.',
      emoji: '🍃',
      phases: [
        const BreathingPhase(
          name: 'Breathe In',
          duration: 4,
          color: AppColors.calmBlue,
          instruction: 'Inhale deeply through your nose, expanding your chest.',
        ),
        const BreathingPhase(
          name: 'Hold',
          duration: 7,
          color: AppColors.primaryPurple,
          instruction: 'Hold your breath and find stillness within.',
        ),
        const BreathingPhase(
          name: 'Breathe Out',
          duration: 8,
          color: AppColors.softGreen,
          instruction: 'Exhale completely with a whoosh sound through your mouth.',
        ),
        const BreathingPhase(
          name: 'Hold',
          duration: 2,
          color: AppColors.warmAmber,
          instruction: 'Pause briefly before the next round.',
        ),
      ],
    ),
    BreathingProgram(
      id: 'box',
      name: 'Box Breathing',
      description: 'Used by Navy SEALs to clear mind & relieve stress.',
      emoji: '📦',
      phases: [
        const BreathingPhase(
          name: 'Breathe In',
          duration: 4,
          color: AppColors.calmBlue,
          instruction: 'Inhale slowly for 4 seconds.',
        ),
        const BreathingPhase(
          name: 'Hold',
          duration: 4,
          color: AppColors.primaryPurple,
          instruction: 'Hold the air in your lungs for 4 seconds.',
        ),
        const BreathingPhase(
          name: 'Breathe Out',
          duration: 4,
          color: AppColors.softGreen,
          instruction: 'Exhale slowly for 4 seconds.',
        ),
        const BreathingPhase(
          name: 'Hold Empty',
          duration: 4,
          color: AppColors.warmAmber,
          instruction: 'Rest with empty lungs for 4 seconds.',
        ),
      ],
    ),
    BreathingProgram(
      id: 'equal',
      name: 'Equal Breathing',
      description: 'Balances energy & increases focus.',
      emoji: '⚖️',
      phases: [
        const BreathingPhase(
          name: 'Breathe In',
          duration: 5,
          color: AppColors.calmBlue,
          instruction: 'Inhale slowly and steadily.',
        ),
        const BreathingPhase(
          name: 'Breathe Out',
          duration: 5,
          color: AppColors.softGreen,
          instruction: 'Exhale with the same depth and duration.',
        ),
      ],
    ),
    BreathingProgram(
      id: 'awake',
      name: 'Awakening Breath',
      description: 'Boosts alertness and revitalizes body.',
      emoji: '⚡',
      phases: [
        const BreathingPhase(
          name: 'Breathe In',
          duration: 6,
          color: AppColors.coral,
          instruction: 'Take a long, energizing inhalation.',
        ),
        const BreathingPhase(
          name: 'Hold',
          duration: 2,
          color: AppColors.primaryPurple,
          instruction: 'Hold briefly to absorb energy.',
        ),
        const BreathingPhase(
          name: 'Breathe Out',
          duration: 4,
          color: AppColors.softGreen,
          instruction: 'Exhale with power and force.',
        ),
      ],
    ),
  ];
}
