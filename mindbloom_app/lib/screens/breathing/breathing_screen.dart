import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/theme.dart';
import '../../models/breathing_model.dart';
import '../../services/haptic_util.dart';
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
  int _currentPhase = 0;
  int _currentRound = 0;
  int _totalRounds = 4;
  Timer? _phaseTimer;

  late int _secondsLeft;
  late BreathingProgram _selectedProgram;

  int _totalCompletedSessions = 0;
  int _todayCompletedSessions = 0;

  @override
  void initState() {
    super.initState();
    _selectedProgram = BreathingProgram.presets.first;
    _secondsLeft = _selectedProgram.phases.first.duration;
    _breathController = AnimationController(
      vsync: this,
      duration: Duration(seconds: _secondsLeft),
    );
    _sizeAnimation = Tween<double>(begin: 120, end: 220).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );
    _opacityAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );
    _loadStats();
  }

  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final lastDateStr = prefs.getString('breathing_last_date') ?? '';

    setState(() {
      _totalCompletedSessions = prefs.getInt('breathing_sessions_total') ?? 0;
      if (lastDateStr == todayStr) {
        _todayCompletedSessions = prefs.getInt('breathing_sessions_today') ?? 0;
      } else {
        _todayCompletedSessions = 0;
      }
    });
  }

  Future<void> _logCompletedSession() async {
    final prefs = await SharedPreferences.getInstance();
    
    final totalCount = prefs.getInt('breathing_sessions_total') ?? 0;
    await prefs.setInt('breathing_sessions_total', totalCount + 1);

    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final lastDateStr = prefs.getString('breathing_last_date') ?? '';
    
    int dailyCount = prefs.getInt('breathing_sessions_today') ?? 0;
    if (lastDateStr == todayStr) {
      dailyCount += 1;
    } else {
      dailyCount = 1;
      await prefs.setString('breathing_last_date', todayStr);
    }
    await prefs.setInt('breathing_sessions_today', dailyCount);

    _loadStats();
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
      _secondsLeft = _selectedProgram.phases.first.duration;
    });
  }

  void _runPhase() {
    final phase = _selectedProgram.phases[_currentPhase];
    final duration = phase.duration;
    _secondsLeft = duration;

    // Animate circle
    _breathController.duration = Duration(seconds: duration);
    if (phase.name.toLowerCase().contains('in')) {
      _breathController.forward();
    } else if (phase.name.toLowerCase().contains('out')) {
      _breathController.reverse();
    } else {
      // Hold phase: keep it in current state (either max size or min size)
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
        HapticUtil.mediumImpact();
        _nextPhase();
      } else {
        HapticUtil.selectionClick();
      }
    });
  }

  void _nextPhase() {
    if (_currentPhase < _selectedProgram.phases.length - 1) {
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
    _logCompletedSession();
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
    final phase = _selectedProgram.phases[_currentPhase];

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
                              phase.color.withValues(alpha: _isRunning ? _opacityAnimation.value : 0.3),
                              phase.color.withValues(alpha: 0.05),
                            ],
                          ),
                          border: Border.all(
                            color: phase.color.withValues(alpha: 0.6),
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: phase.color.withValues(alpha: 0.2),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              phase.name,
                              style: TextStyle(
                                color: phase.color,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            if (_isRunning)
                              Text(
                                '$_secondsLeft',
                                style: TextStyle(
                                  color: phase.color,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 36,
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      key: ValueKey('${_selectedProgram.id}_$_currentPhase'),
                      height: 60,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      alignment: Alignment.center,
                      child: Text(
                        phase.instruction,
                        key: ValueKey('${_selectedProgram.id}_${_currentPhase}_text'),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: phase.color.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Phase indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_selectedProgram.phases.length, (index) {
                      final isActive = index == _currentPhase && _isRunning;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 32 : 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: isActive
                              ? _selectedProgram.phases[index].color
                              : _selectedProgram.phases[index].color.withValues(alpha: 0.25),
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
                  const SizedBox(height: 32),

                  // Stats dashboard panel
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.05),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem('Today\'s Sessions', '$_todayCompletedSessions', '🧘'),
                        Container(
                          width: 1,
                          height: 30,
                          color: Colors.grey.withValues(alpha: 0.2),
                        ),
                        _buildStatItem('Total Sessions', '$_totalCompletedSessions', '🔥'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, String icon) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ],
    );
  }
}
