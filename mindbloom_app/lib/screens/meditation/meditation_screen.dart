import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/theme.dart';
import '../../models/meditation_model.dart';
import '../../providers/meditation_favorites_provider.dart';
import '../../widgets/custom_card.dart';

class MeditationScreen extends ConsumerStatefulWidget {
  const MeditationScreen({super.key});

  @override
  ConsumerState<MeditationScreen> createState() => _MeditationScreenState();
}

class _MeditationScreenState extends ConsumerState<MeditationScreen> with TickerProviderStateMixin {
  int _selectedIndex = -1;
  bool _isPlaying = false;
  double _progress = 0;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioPlayer _ambientPlayer = AudioPlayer();
  double _ambientVolume = 0.5;

  // Custom Timer State Variables
  bool _isCustomMode = false;
  int _customDurationMinutes = 10;
  int _customSecondsLeft = 600;
  bool _isCustomTimerPlaying = false;
  Timer? _customTimer;
  List<MeditationSession> _history = [];
  int _totalMeditationTimeSeconds = 0;

  final List<Map<String, dynamic>> _sessions = [
    {'title': 'Calm Morning', 'duration': '10 min', 'icon': '🌅', 'color': AppColors.warmAmber, 'seconds': 600, 'path': 'assets/audio/calm.wav'},
    {'title': 'Stress Relief', 'duration': '15 min', 'icon': '🌊', 'color': AppColors.calmBlue, 'seconds': 900, 'path': 'assets/audio/stress.wav'},
    {'title': 'Body Scan', 'duration': '20 min', 'icon': '🧘', 'color': AppColors.primaryPurple, 'seconds': 1200, 'path': 'assets/audio/body.wav'},
    {'title': 'Sleep Prep', 'duration': '10 min', 'icon': '🌙', 'color': AppColors.softGreen, 'seconds': 600, 'path': 'assets/audio/sleep.wav'},
    {'title': 'Focus Flow', 'duration': '5 min', 'icon': '🎯', 'color': AppColors.coral, 'seconds': 300, 'path': 'assets/audio/focus.wav'},
    {'title': 'Gratitude', 'duration': '8 min', 'icon': '🙏', 'color': AppColors.warmAmber, 'seconds': 480, 'path': 'assets/audio/gratitude.wav'},
  ];

  final List<Map<String, dynamic>> _ambientSounds = [
    {'title': 'Rain', 'icon': '🌧️', 'path': 'assets/audio/rain.wav'},
    {'title': 'Ocean', 'icon': '🌊', 'path': 'assets/audio/ocean.wav'},
    {'title': 'Forest', 'icon': '🌿', 'path': 'assets/audio/forest.wav'},
    {'title': 'Birds', 'icon': '🐦', 'path': 'assets/audio/birds.wav'},
    {'title': 'Wind', 'icon': '💨', 'path': 'assets/audio/wind.wav'},
    {'title': 'Fire', 'icon': '🔥', 'path': 'assets/audio/fire.wav'},
  ];

  int _selectedAmbient = -1;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    // Listen to player state
    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
          if (state.processingState == ProcessingState.completed) {
            _audioPlayer.seek(Duration.zero);
            _audioPlayer.pause();
            _isPlaying = false;
            if (_selectedIndex >= 0) {
              final session = _sessions[_selectedIndex];
              _saveCompletedSession(session['seconds'] as int, session['title'] as String, false);
            }
          }
        });
      }
    });

    // Listen to position changes
    _audioPlayer.positionStream.listen((position) {
      if (mounted && _audioPlayer.duration != null) {
        setState(() {
          _progress = position.inMilliseconds / _audioPlayer.duration!.inMilliseconds;
          if (_progress.isNaN || _progress.isInfinite) _progress = 0;
        });
      }
    });

    _loadMeditationHistory();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _audioPlayer.dispose();
    _ambientPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final favState = ref.watch(meditationFavoritesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Meditation')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mode selector (Guided Sessions vs Custom Timer)
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _isCustomMode = false;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: !_isCustomMode
                            ? AppColors.primaryPurple.withValues(alpha: 0.15)
                            : Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: !_isCustomMode ? AppColors.primaryPurple : Colors.black.withValues(alpha: 0.08),
                          width: !_isCustomMode ? 1.5 : 0.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Guided Sessions',
                          style: TextStyle(
                            fontWeight: !_isCustomMode ? FontWeight.bold : FontWeight.normal,
                            color: !_isCustomMode ? AppColors.primaryPurple : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _isCustomMode = true;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _isCustomMode
                            ? AppColors.primaryPurple.withValues(alpha: 0.15)
                            : Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isCustomMode ? AppColors.primaryPurple : Colors.black.withValues(alpha: 0.08),
                          width: _isCustomMode ? 1.5 : 0.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Custom Timer',
                          style: TextStyle(
                            fontWeight: _isCustomMode ? FontWeight.bold : FontWeight.normal,
                            color: _isCustomMode ? AppColors.primaryPurple : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (!_isCustomMode) ...[
              // Player area
              if (_selectedIndex >= 0) ...[
                _buildPlayer(context),
                const SizedBox(height: 24),
              ],

              // Sessions
            Text('Sessions', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _sessions.length,
              itemBuilder: (context, index) {
                final session = _sessions[index];
                final title = session['title'] as String;
                final isFav = favState.favoriteTitles.contains(title);
                final isActive = _selectedIndex == index;
                return GestureDetector(
                  onTap: () async {
                    setState(() {
                      _selectedIndex = index;
                      _isPlaying = true;
                      _progress = 0;
                    });
                    try {
                      await _audioPlayer.setVolume(1.0);
                      // Loop the ambient sounds
                      await _audioPlayer.setLoopMode(LoopMode.all);
                      await _audioPlayer.setAsset(session['path'] as String);
                      _audioPlayer.play();
                    } catch (e) {
                      debugPrint('Error loading audio: $e');
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isActive
                          ? (session['color'] as Color).withValues(alpha: 0.1)
                          : Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isActive ? session['color'] as Color : Colors.black.withValues(alpha: 0.08),
                        width: isActive ? 1.5 : 0.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(session['icon'] as String, style: const TextStyle(fontSize: 28)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(session['title'] as String,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                              Text(session['duration'] as String,
                                style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                color: isFav ? Colors.redAccent : AppColors.textSecondary,
                                size: 22,
                              ),
                              tooltip: isFav ? 'Remove from favorites' : 'Add to favorites',
                              onPressed: () {
                                ref
                                    .read(meditationFavoritesProvider.notifier)
                                    .toggleFavorite(title);
                              },
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              isActive && _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                              color: session['color'] as Color,
                              size: 36,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Ambient sounds
            Text('Ambient Sounds', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            SizedBox(
              height: 90,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _ambientSounds.length,
                itemBuilder: (context, index) {
                  final sound = _ambientSounds[index];
                  final isActive = _selectedAmbient == index;
                  return GestureDetector(
                    onTap: () async {
                      final isCurrentlyActive = _selectedAmbient == index;
                      setState(() {
                        _selectedAmbient = isCurrentlyActive ? -1 : index;
                      });
                      try {
                        if (isCurrentlyActive) {
                          await _ambientPlayer.stop();
                        } else {
                          await _ambientPlayer.setAsset(sound['path'] as String);
                          await _ambientPlayer.setVolume(_ambientVolume);
                          await _ambientPlayer.setLoopMode(LoopMode.all);
                          _ambientPlayer.play();
                        }
                      } catch (e) {
                        debugPrint('Error playing ambient sound: $e');
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 12),
                      width: 80,
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.primaryPurple.withValues(alpha: 0.12)
                            : Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isActive ? AppColors.primaryPurple : Colors.black.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(sound['icon'] as String, style: const TextStyle(fontSize: 28)),
                          const SizedBox(height: 6),
                          Text(sound['title'] as String,
                            style: TextStyle(fontSize: 12, fontWeight: isActive ? FontWeight.w600 : FontWeight.w400)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_selectedAmbient >= 0) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: [
                    const Icon(Icons.volume_down_rounded, size: 20, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Slider(
                        value: _ambientVolume,
                        min: 0.0,
                        max: 1.0,
                        activeColor: AppColors.primaryPurple,
                        onChanged: (val) {
                          setState(() {
                            _ambientVolume = val;
                          });
                          _ambientPlayer.setVolume(val);
                        },
                      ),
                    ),
                    const Icon(Icons.volume_up_rounded, size: 20, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ],
          ] else ...[
            _buildCustomTimer(context),
          ],
          ],
        ),
      ),
    );
  }

  Future<void> _loadMeditationHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('meditation_history') ?? '[]';
    try {
      final List decoded = jsonDecode(jsonStr);
      final list = decoded.map((item) => MeditationSession.fromJson(item)).toList();
      int totalSeconds = 0;
      for (final s in list) {
        totalSeconds += s.durationSeconds;
      }
      setState(() {
        _history = list;
        _totalMeditationTimeSeconds = totalSeconds;
      });
    } catch (_) {}
  }

  Future<void> _saveCompletedSession(int durationSeconds, String title, bool isCustom) async {
    final prefs = await SharedPreferences.getInstance();
    final session = MeditationSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      durationSeconds: durationSeconds,
      date: DateTime.now(),
      isCustom: isCustom,
    );
    final updatedList = List<MeditationSession>.from(_history)..insert(0, session);
    final jsonStr = jsonEncode(updatedList.map((s) => s.toJson()).toList());
    await prefs.setString('meditation_history', jsonStr);
    setState(() {
      _history = updatedList;
      _totalMeditationTimeSeconds += durationSeconds;
    });
  }

  void _startCustomTimer() {
    if (_isCustomTimerPlaying) return;
    setState(() {
      _isCustomTimerPlaying = true;
    });

    _customTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_customSecondsLeft > 0) {
          _customSecondsLeft--;
        } else {
          timer.cancel();
          _isCustomTimerPlaying = false;
          _onCustomTimerComplete();
        }
      });
    });
  }

  void _pauseCustomTimer() {
    _customTimer?.cancel();
    setState(() {
      _isCustomTimerPlaying = false;
    });
  }

  void _stopCustomTimer() {
    _customTimer?.cancel();
    setState(() {
      _isCustomTimerPlaying = false;
      _customSecondsLeft = _customDurationMinutes * 60;
    });
  }

  void _onCustomTimerComplete() {
    _saveCompletedSession(_customDurationMinutes * 60, 'Custom Silent Meditation', true);
    _showCustomCompleteDialog();
  }

  void _showCustomCompleteDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Mindful Session Complete 🌸'),
        content: Text('You spent $_customDurationMinutes minutes in silent meditation. How do you feel?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _stopCustomTimer();
            },
            child: const Text('Done'),
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

  Widget _buildCustomTimer(BuildContext context) {
    final progress = _customDurationMinutes > 0
        ? (_customDurationMinutes * 60 - _customSecondsLeft) / (_customDurationMinutes * 60)
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Sessions', '${_history.length}', '🧘'),
              Container(
                width: 1,
                height: 30,
                color: Colors.grey.withValues(alpha: 0.2),
              ),
              _buildStatItem('Total Time', '${_totalMeditationTimeSeconds ~/ 60}m', '🔥'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        CustomCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                'Meditation Timer',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Set your own duration and find your peaceful center.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              // Big timer text
              Text(
                '${(_customSecondsLeft ~/ 60).toString().padLeft(2, '0')}:${(_customSecondsLeft % 60).toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 54, fontWeight: FontWeight.bold, letterSpacing: 2),
              ),
              const SizedBox(height: 12),
              if (_isCustomTimerPlaying || _customSecondsLeft < _customDurationMinutes * 60) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppColors.primaryPurple.withValues(alpha: 0.15),
                    valueColor: const AlwaysStoppedAnimation(AppColors.primaryPurple),
                    minHeight: 6,
                  ),
                ),
              ] else ...[
                Slider(
                  value: _customDurationMinutes.toDouble(),
                  min: 1.0,
                  max: 60.0,
                  divisions: 59,
                  activeColor: AppColors.primaryPurple,
                  label: '$_customDurationMinutes min',
                  onChanged: (val) {
                    setState(() {
                      _customDurationMinutes = val.toInt();
                      _customSecondsLeft = _customDurationMinutes * 60;
                    });
                  },
                ),
                Text(
                  'Duration: $_customDurationMinutes minutes',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isCustomTimerPlaying || _customSecondsLeft < _customDurationMinutes * 60) ...[
                    OutlinedButton(
                      onPressed: _stopCustomTimer,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primaryPurple),
                        minimumSize: const Size(100, 40),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Reset'),
                    ),
                    const SizedBox(width: 16),
                  ],
                  ElevatedButton(
                    onPressed: _isCustomTimerPlaying ? _pauseCustomTimer : _startCustomTimer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryPurple,
                      minimumSize: const Size(120, 40),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(_isCustomTimerPlaying ? 'Pause' : 'Start'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlayer(BuildContext context) {
    final session = _sessions[_selectedIndex];
    return CustomCard(
      gradient: LinearGradient(
        colors: [
          (session['color'] as Color),
          (session['color'] as Color).withValues(alpha: 0.7),
        ],
      ),
      child: Column(
        children: [
          // Pulsing icon
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _isPlaying ? _pulseAnimation.value : 1.0,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                  child: Center(
                    child: Text(session['icon'] as String, style: const TextStyle(fontSize: 36)),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            session['title'] as String,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            session['duration'] as String,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
          ),
          const SizedBox(height: 16),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _progress,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 16),
          // Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.replay_10, color: Colors.white, size: 28),
                onPressed: () {
                  final newPos = _audioPlayer.position - const Duration(seconds: 10);
                  _audioPlayer.seek(newPos < Duration.zero ? Duration.zero : newPos);
                },
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () {
                  if (_isPlaying) {
                    _audioPlayer.pause();
                  } else {
                    _audioPlayer.play();
                  }
                },
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                  child: Icon(
                    _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.forward_10, color: Colors.white, size: 28),
                onPressed: () {
                  if (_audioPlayer.duration != null) {
                    final newPos = _audioPlayer.position + const Duration(seconds: 10);
                    _audioPlayer.seek(newPos > _audioPlayer.duration! ? _audioPlayer.duration! : newPos);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
