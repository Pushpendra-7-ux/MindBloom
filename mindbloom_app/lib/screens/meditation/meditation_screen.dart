import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../config/theme.dart';
import '../../widgets/custom_card.dart';

class MeditationScreen extends StatefulWidget {
  const MeditationScreen({super.key});

  @override
  State<MeditationScreen> createState() => _MeditationScreenState();
}

class _MeditationScreenState extends State<MeditationScreen> with TickerProviderStateMixin {
  int _selectedIndex = -1;
  bool _isPlaying = false;
  double _progress = 0;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  final AudioPlayer _audioPlayer = AudioPlayer();

  final List<Map<String, dynamic>> _sessions = [
    {'title': 'Calm Morning', 'duration': '10 min', 'icon': '🌅', 'color': AppColors.warmAmber, 'seconds': 600, 'path': 'assets/audio/calm.wav'},
    {'title': 'Stress Relief', 'duration': '15 min', 'icon': '🌊', 'color': AppColors.calmBlue, 'seconds': 900, 'path': 'assets/audio/stress.wav'},
    {'title': 'Body Scan', 'duration': '20 min', 'icon': '🧘', 'color': AppColors.primaryPurple, 'seconds': 1200, 'path': 'assets/audio/body.wav'},
    {'title': 'Sleep Prep', 'duration': '10 min', 'icon': '🌙', 'color': AppColors.softGreen, 'seconds': 600, 'path': 'assets/audio/sleep.wav'},
    {'title': 'Focus Flow', 'duration': '5 min', 'icon': '🎯', 'color': AppColors.coral, 'seconds': 300, 'path': 'assets/audio/focus.wav'},
    {'title': 'Gratitude', 'duration': '8 min', 'icon': '🙏', 'color': AppColors.warmAmber, 'seconds': 480, 'path': 'assets/audio/gratitude.wav'},
  ];

  final List<Map<String, dynamic>> _ambientSounds = [
    {'title': 'Rain', 'icon': '🌧️'},
    {'title': 'Ocean', 'icon': '🌊'},
    {'title': 'Forest', 'icon': '🌿'},
    {'title': 'Birds', 'icon': '🐦'},
    {'title': 'Wind', 'icon': '💨'},
    {'title': 'Fire', 'icon': '🔥'},
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
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meditation')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                        Icon(
                          isActive && _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                          color: session['color'] as Color,
                          size: 36,
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
                    onTap: () => setState(() => _selectedAmbient = isActive ? -1 : index),
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
          ],
        ),
      ),
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
