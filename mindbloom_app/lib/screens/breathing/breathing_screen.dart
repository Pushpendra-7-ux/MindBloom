import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/theme.dart';
import '../../models/breathing_model.dart';
import '../../providers/breathing_history_provider.dart';
import '../../services/haptic_util.dart';
import '../../widgets/custom_button.dart';

class BreathingScreen extends ConsumerStatefulWidget {
  const BreathingScreen({super.key});

  @override
  ConsumerState<BreathingScreen> createState() => _BreathingScreenState();
}

class _BreathingScreenState extends ConsumerState<BreathingScreen> with TickerProviderStateMixin {
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

  BreathingProgram? _customProgram;

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

    final customJson = prefs.getString('breathing_custom_program');
    BreathingProgram? customProg;
    if (customJson != null) {
      try {
        customProg = BreathingProgram.fromJson(jsonDecode(customJson));
      } catch (_) {}
    }

    final selectedProgId = prefs.getString('breathing_selected_program_id') ?? '478';
    BreathingProgram selected = BreathingProgram.presets.firstWhere(
      (p) => p.id == selectedProgId,
      orElse: () => BreathingProgram.presets.first,
    );
    if (selectedProgId == 'custom' && customProg != null) {
      selected = customProg;
    }

    setState(() {
      _customProgram = customProg;
      _selectedProgram = selected;
      _secondsLeft = selected.phases.first.duration;
      _breathController.duration = Duration(seconds: _secondsLeft);
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

    // Save to our new BreathingHistoryProvider
    await ref.read(breathingHistoryProvider.notifier).addSession(
      programName: _selectedProgram.name,
      programEmoji: _selectedProgram.emoji,
      durationSeconds: _selectedProgram.totalDuration * _totalRounds,
      roundsCompleted: _totalRounds,
    );

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
    final historyState = ref.watch(breathingHistoryProvider);
    final todayCount = historyState.todaySessions.length;
    final totalCount = historyState.sessions.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Breathing Exercise')),
      body: Column(
        children: [
          // Program Selector
          Container(
            height: 100,
            margin: const EdgeInsets.symmetric(vertical: 12),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: BreathingProgram.presets.length + 1 + (_customProgram != null ? 1 : 0),
              itemBuilder: (context, idx) {
                final isCustomAddCard = idx == BreathingProgram.presets.length + (_customProgram != null ? 1 : 0);
                final isCustomProgramCard = _customProgram != null && idx == BreathingProgram.presets.length;

                if (isCustomAddCard) {
                  return GestureDetector(
                    onTap: () {
                      if (_isRunning) _reset();
                      _showCustomBreathingDialog();
                    },
                    child: Container(
                      width: 150,
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.black.withValues(alpha: 0.08),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_rounded, color: AppColors.primaryPurple, size: 24),
                          const SizedBox(height: 4),
                          Text(
                            'Custom Program',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryPurple,
                                ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final prog = isCustomProgramCard ? _customProgram! : BreathingProgram.presets[idx];
                final isSelected = prog.id == _selectedProgram.id;
                return GestureDetector(
                  onTap: () async {
                    if (_isRunning) _reset();
                    setState(() {
                      _selectedProgram = prog;
                      _secondsLeft = prog.phases.first.duration;
                      _breathController.duration = Duration(seconds: _secondsLeft);
                    });
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('breathing_selected_program_id', prog.id);
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
                  GestureDetector(
                    onTap: _showHistoryBottomSheet,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.05),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem('Today\'s Sessions', '$todayCount', '🧘'),
                              Container(
                                width: 1,
                                height: 30,
                                color: Colors.grey.withValues(alpha: 0.2),
                              ),
                              _buildStatItem('Total Sessions', '$totalCount', '🔥'),
                            ],
                          ),
                          const Divider(height: 24, thickness: 0.5),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.history_rounded, size: 16, color: AppColors.primaryPurple),
                              const SizedBox(width: 6),
                              Text(
                                'View Detailed History',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.primaryPurple,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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

  void _showCustomBreathingDialog() {
    int inhale = 4;
    int hold = 4;
    int exhale = 4;
    int holdEmpty = 2;

    // Pre-fill from existing custom program
    if (_customProgram != null) {
      for (final p in _customProgram!.phases) {
        final name = p.name.toLowerCase();
        if (name.contains('breathe in')) inhale = p.duration;
        else if (name == 'hold') hold = p.duration;
        else if (name.contains('breathe out')) exhale = p.duration;
        else if (name.contains('hold empty')) holdEmpty = p.duration;
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final totalCycle = inhale + hold + exhale + holdEmpty;
            return Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Title
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryPurple.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text('✨', style: TextStyle(fontSize: 20)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Custom Breathing', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                            Text('Total cycle: ${totalCycle}s', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Sliders
                  _buildDurationSlider('Inhale', inhale, AppColors.calmBlue, (v) {
                    setSheetState(() => inhale = v);
                  }),
                  _buildDurationSlider('Hold', hold, AppColors.primaryPurple, (v) {
                    setSheetState(() => hold = v);
                  }),
                  _buildDurationSlider('Exhale', exhale, AppColors.softGreen, (v) {
                    setSheetState(() => exhale = v);
                  }),
                  _buildDurationSlider('Hold Empty', holdEmpty, AppColors.warmAmber, (v) {
                    setSheetState(() => holdEmpty = v);
                  }),
                  const SizedBox(height: 20),
                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final custom = BreathingProgram.createCustom(
                          inhale: inhale,
                          hold: hold,
                          exhale: exhale,
                          holdEmpty: holdEmpty,
                        );
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString('breathing_custom_program', jsonEncode(custom.toJson()));
                        await prefs.setString('breathing_selected_program_id', custom.id);
                        if (mounted) {
                          setState(() {
                            _customProgram = custom;
                            _selectedProgram = custom;
                            _reset();
                          });
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Custom breathing program saved! ✨'),
                              backgroundColor: AppColors.primaryPurple,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryPurple,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Save & Use', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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

  Widget _buildDurationSlider(String label, int value, Color color, ValueChanged<int> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                activeTrackColor: color,
                thumbColor: color,
                inactiveTrackColor: color.withValues(alpha: 0.15),
                overlayColor: color.withValues(alpha: 0.1),
              ),
              child: Slider(
                value: value.toDouble(),
                min: 0,
                max: 10,
                divisions: 10,
                onChanged: (v) => onChanged(v.round()),
              ),
            ),
          ),
          Container(
            width: 36,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${value}s',
              style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  void _showHistoryBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, child) {
            final historyState = ref.watch(breathingHistoryProvider);
            final sessions = historyState.sessions;

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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Text('🌬️', style: TextStyle(fontSize: 22)),
                            const SizedBox(width: 10),
                            Text(
                              'Breathing History',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        if (sessions.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.delete_sweep_rounded, color: AppColors.error),
                            tooltip: 'Clear All',
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Clear History'),
                                  content: const Text('Are you sure you want to clear all breathing history?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      child: const Text('Clear', style: TextStyle(color: AppColors.error)),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await ref.read(breathingHistoryProvider.notifier).clearHistory();
                                final prefs = await SharedPreferences.getInstance();
                                await prefs.remove('breathing_sessions_total');
                                await prefs.remove('breathing_sessions_today');
                                _loadStats();
                              }
                            },
                          ),
                      ],
                    ),
                  ),
                  if (sessions.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildHistorySummaryItem(context, 'Total Time', historyState.formattedTotalTime, '⏱️'),
                          _buildHistorySummaryItem(context, 'Active Days', '${historyState.activeDays} days', '📅'),
                        ],
                      ),
                    ),
                  const Divider(height: 24),
                  Expanded(
                    child: sessions.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.history_rounded, size: 48, color: Colors.grey[400]),
                                const SizedBox(height: 12),
                                Text(
                                  'No sessions recorded yet',
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Complete a session to start tracking!',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            itemCount: sessions.length,
                            itemBuilder: (context, index) {
                              final session = sessions[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
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
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryPurple.withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        session.programEmoji,
                                        style: const TextStyle(fontSize: 20),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            session.programName,
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${session.formattedDuration} • ${session.roundsCompleted} rounds',
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                  color: AppColors.textSecondary,
                                                ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            DateFormat('MMM d, h:mm a').format(session.completedAt),
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                  color: Colors.grey[500],
                                                  fontSize: 10,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.textSecondary),
                                      onPressed: () async {
                                        await ref.read(breathingHistoryProvider.notifier).removeSession(session.id);
                                        final prefs = await SharedPreferences.getInstance();
                                        final totalCount = prefs.getInt('breathing_sessions_total') ?? 0;
                                        if (totalCount > 0) {
                                          await prefs.setInt('breathing_sessions_total', totalCount - 1);
                                        }
                                        final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
                                        if (DateFormat('yyyy-MM-dd').format(session.completedAt) == todayStr) {
                                          final todayCount = prefs.getInt('breathing_sessions_today') ?? 0;
                                          if (todayCount > 0) {
                                            await prefs.setInt('breathing_sessions_today', todayCount - 1);
                                          }
                                        }
                                        _loadStats();
                                      },
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
  }

  Widget _buildHistorySummaryItem(BuildContext context, String label, String value, String icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.03),
        ),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
