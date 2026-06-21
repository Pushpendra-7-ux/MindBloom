import 'dart:async';
import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/breathing_model.dart';
import '../../widgets/custom_button.dart';

class BreathingScreen extends StatefulWidget {
  const BreathingScreen({super.key});

  @override
  State<BreathingScreen> createState() => _BreathingScreenState();
}

class _BreathingScreenState extends State<BreathingScreen> with TickerProviderStateMixin {
  late AnimationController _breathController;
  late Animation<double> _sizeAnimation;
  late Animation<double> _opacityAnimation;

  bool _isRunning = false;
  int _currentPhase = 0; // 0: inhale, 1: hold, 2: exhale, 3: hold
  int _currentRound = 0;
  int _totalRounds = 4;
  Timer? _phaseTimer;

  // 4-7-8 breathing
  final List<Map<String, dynamic>> _phases = [
    {'name': 'Breathe In', 'duration': 4, 'color': AppColors.calmBlue},
    {'name': 'Hold', 'duration': 7, 'color': AppColors.primaryPurple},
    {'name': 'Breathe Out', 'duration': 8, 'color': AppColors.softGreen},
    {'name': 'Hold', 'duration': 2, 'color': AppColors.warmAmber},
  ];

  int _secondsLeft = 4;
  late BreathingProgram _selectedProgram;

  @override
  void initState() {
    super.initState();
    _selectedProgram = BreathingProgram.presets.first;
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _sizeAnimation = Tween<double>(begin: 120, end: 220).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );
    _opacityAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _breathController.dispose();
    _phaseTimer?.cancel();
    super.dispose();
  }

  void _start() {
    setState(() {
      _isRunning = true;
      _currentPhase = 0;
      _currentRound = 0;
    });
    _runPhase();
  }

  void _pause() {
    _phaseTimer?.cancel();
    _breathController.stop();
    setState(() => _isRunning = false);
  }

  void _reset() {
    _phaseTimer?.cancel();
    _breathController.reset();
    setState(() {
      _isRunning = false;
      _currentPhase = 0;
      _currentRound = 0;
      _secondsLeft = _phases[0]['duration'] as int;
    });
  }

  void _runPhase() {
    final phase = _phases[_currentPhase];
    final duration = phase['duration'] as int;
    _secondsLeft = duration;

    // Animate circle
    _breathController.duration = Duration(seconds: duration);
    if (_currentPhase == 0) {
      _breathController.forward();
    } else if (_currentPhase == 2) {
      _breathController.reverse();
    }

    // Timer countdown
    _phaseTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) {
        timer.cancel();
        _nextPhase();
      }
    });
  }

  void _nextPhase() {
    if (_currentPhase < 3) {
      setState(() => _currentPhase++);
      _runPhase();
    } else {
      setState(() {
        _currentRound++;
        _currentPhase = 0;
      });
      if (_currentRound >= _totalRounds) {
        _breathController.reset();
        setState(() => _isRunning = false);
        _showCompleteDialog();
      } else {
        _runPhase();
      }
    }
  }

  void _showCompleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Great Job! 🌸'),
        content: const Text('You completed your breathing exercise. How do you feel?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _reset();
            },
            child: const Text('Done'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _reset();
              _start();
            },
            child: const Text('Again'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final phase = _phases[_currentPhase];

    return Scaffold(
      appBar: AppBar(title: const Text('Breathing Exercise')),
      body: Column(
        children: [
          // Program Selector
          Container(
            height: 90,
            margin: const EdgeInsets.symmetric(vertical: 12),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: BreathingProgram.presets.length,
              itemBuilder: (context, idx) {
                final prog = BreathingProgram.presets[idx];
                final isSelected = prog.id == _selectedProgram.id;
                return GestureDetector(
                  onTap: () {
                    if (_isRunning) _reset();
                    setState(() {
                      _selectedProgram = prog;
                    });
                  },
                  child: Container(
                    width: 150,
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryPurple.withValues(alpha: 0.1)
                          : Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryPurple
                            : Theme.of(context).brightness == Brightness.dark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.black.withValues(alpha: 0.08),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(prog.emoji, style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                prog.name,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? AppColors.primaryPurple : null,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${prog.totalDuration}s cycle',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Round counter
                  Text(
                    'Round ${_currentRound + 1} / $_totalRounds',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Technique label
                  Text(
                    _selectedProgram.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 32),

                  // Breathing circle
                  AnimatedBuilder(
                    animation: _sizeAnimation,
                    builder: (context, child) {
                      return Container(
                        width: _isRunning ? _sizeAnimation.value : 160,
                        height: _isRunning ? _sizeAnimation.value : 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              (phase['color'] as Color).withValues(alpha: _isRunning ? _opacityAnimation.value : 0.3),
                              (phase['color'] as Color).withValues(alpha: 0.05),
                            ],
                          ),
                          border: Border.all(
                            color: (phase['color'] as Color).withValues(alpha: 0.6),
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (phase['color'] as Color).withValues(alpha: 0.2),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              phase['name'] as String,
                              style: TextStyle(
                                color: phase['color'] as Color,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            if (_isRunning)
                              Text(
                                '$_secondsLeft',
                                style: TextStyle(
                                  color: phase['color'] as Color,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 36,
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 48),

                  // Phase indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) {
                      final isActive = index == _currentPhase && _isRunning;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 32 : 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: isActive
                              ? _phases[index]['color'] as Color
                              : (_phases[index]['color'] as Color).withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(5),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 48),

                  // Controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isRunning || _currentRound > 0) ...[
                        CustomButton(
                          label: 'Reset',
                          isOutlined: true,
                          width: 120,
                          onPressed: _reset,
                        ),
                        const SizedBox(width: 16),
                      ],
                      CustomButton(
                        label: _isRunning ? 'Pause' : 'Start',
                        width: 160,
                        color: _isRunning ? AppColors.warmAmber : AppColors.softGreen,
                        icon: _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        onPressed: _isRunning ? _pause : _start,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  // Rounds selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Rounds: ', style: Theme.of(context).textTheme.bodyMedium),
                      ...List.generate(4, (i) {
                        final rounds = [2, 4, 6, 8];
                        return GestureDetector(
                          onTap: _isRunning ? null : () => setState(() => _totalRounds = rounds[i]),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: _totalRounds == rounds[i]
                                  ? AppColors.primaryPurple
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _totalRounds == rounds[i]
                                    ? AppColors.primaryPurple
                                    : Colors.black.withValues(alpha: 0.15),
                              ),
                            ),
                            child: Text(
                              '${rounds[i]}',
                              style: TextStyle(
                                color: _totalRounds == rounds[i] ? Colors.white : null,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
