import 'dart:async';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AsmrMissionScreen extends StatefulWidget {
  const AsmrMissionScreen({super.key});

  @override
  State<AsmrMissionScreen> createState() => _AsmrMissionScreenState();
}

class _AsmrMissionScreenState extends State<AsmrMissionScreen>
    with TickerProviderStateMixin {
  late AudioPlayer _audioPlayer;
  late AnimationController _breathingController;
  final Random _random = Random();

  // Visualizer bars
  final List<double> _barHeights = List.filled(7, 50.0);
  Timer? _visualizerTimer;

  @override
  void initState() {
    super.initState();
    // Delay audio loading to prevent UI freeze/crash on entry
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _setupAudio();
      });
    });
    _setupAnimations();
  }

  void _setupAudio() async {
    _audioPlayer = AudioPlayer();
    try {
      // Set release mode to loop for infinite playback
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      // Pre-set source to prepare buffer
      await _audioPlayer.setSource(AssetSource('audio/coins.mp3'));
      // Resume (play) after source is ready
      if (mounted) {
        await _audioPlayer.resume();
      }
    } catch (e) {
      debugPrint('Error playing audio: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('오디오를 재생할 수 없습니다.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _setupAnimations() {
    // Breathing Controller (4 seconds cycle: 2s in, 2s out)
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    // Visualizer Timer: Update heights every 100ms
    _visualizerTimer = Timer.periodic(const Duration(milliseconds: 100), (
      timer,
    ) {
      if (mounted) {
        setState(() {
          for (int i = 0; i < _barHeights.length; i++) {
            // Random height between 20 and 120
            _barHeights[i] = 20.0 + _random.nextInt(100).toDouble();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    // Strict disposal order to prevent memory leaks
    _visualizerTimer?.cancel();
    _breathingController.dispose();

    // Stop first, then dispose player
    try {
      _audioPlayer.stop().then((_) => _audioPlayer.dispose());
    } catch (e) {
      // Ignore audio disposal errors
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Deep Dark Background
      body: Stack(
        children: [
          // 1. Digital Noise Background
          Positioned.fill(
            child: CustomPaint(
              painter: _DigitalNoisePainter(animation: _breathingController),
            ),
          ),

          SafeArea(
            child: Stack(
              children: [
                // Close Button
                Positioned(
                  top: 16,
                  right: 16,
                  child: IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white54,
                      size: 32,
                    ),
                  ),
                ),

                // Content Center
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),

                    // 2. Neon Frequency Widget (Replaces Breathing Circle)
                    AnimatedBuilder(
                      animation: _breathingController,
                      builder: (context, child) {
                        final value = _breathingController.value;
                        return Container(
                          width: 240,
                          height: 240,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            // Neon Glow Gradient
                            gradient: RadialGradient(
                              colors: [
                                Colors.transparent,
                                const Color(
                                  0xFFD050FF,
                                ).withValues(alpha: 0.1 + (value * 0.2)),
                                const Color(0xFFD050FF).withValues(alpha: 0.0),
                              ],
                              stops: const [0.5, 0.9, 1.0],
                            ),
                            border: Border.all(
                              color: const Color(0xFFD050FF).withValues(alpha: 0.6),
                              width: 1 + (value * 2),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFD050FF).withValues(alpha: 0.3),
                                blurRadius: 20 + (value * 20),
                                spreadRadius: value * 5,
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Inner Rings
                              Container(
                                width: 180 + (value * 20),
                                height: 180 + (value * 20),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.cyanAccent.withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                              ),
                              Container(
                                width: 100 - (value * 10),
                                height: 100 - (value * 10),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.5),
                                    width: 1,
                                  ),
                                ),
                              ),
                              // Icon Only
                              const Icon(
                                Icons.waves,
                                color: Color(0xFFD050FF),
                                size: 32,
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // Text Label (Moved Outside)
                    Text(
                      "TUNING...",
                      style: TextStyle(
                        color: const Color(0xFFD050FF).withValues(alpha: 0.8),
                        fontSize: 20, // Increased size
                        fontFamily: 'Courier',
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),

                    const Spacer(),

                    // 3. Tech Visualizer (Bottom)
                    SizedBox(
                      height: 100,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: List.generate(15, (index) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 100),
                            width: 6,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            height:
                                (_barHeights[index % 7] * 0.6) +
                                (index % 3 * 10), // Randomized look
                            decoration: BoxDecoration(
                              color: const Color(0xFFD050FF), // Neon Purple
                              borderRadius: BorderRadius.circular(2),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0xFFD050FF),
                                  blurRadius: 6,
                                  offset: Offset(0, -1),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 48),
                  ],
                ).animate().fadeIn(duration: 800.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Digital Noise Painter
class _DigitalNoisePainter extends CustomPainter {
  final Animation<double> animation;
  final Random _random = Random();

  _DigitalNoisePainter({required this.animation}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Draw random static dots
    for (int i = 0; i < 500; i++) {
      paint.color = Colors.white.withValues(alpha: 
        _random.nextDouble() * 0.15,
      ); // increased opacity for visibility
      canvas.drawRect(
        Rect.fromLTWH(
          _random.nextDouble() * size.width,
          _random.nextDouble() * size.height,
          2, // dot size
          2,
        ),
        paint,
      );
    }

    // Draw scan line
    final scanY = (animation.value * size.height) % size.height;
    paint.color = const Color(0xFFD050FF).withValues(alpha: 0.1);
    canvas.drawRect(Rect.fromLTWH(0, scanY, size.width, 4), paint);
  }

  @override
  bool shouldRepaint(covariant _DigitalNoisePainter oldDelegate) => true;
}
