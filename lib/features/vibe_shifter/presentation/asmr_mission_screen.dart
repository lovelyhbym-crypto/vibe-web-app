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
      body: SafeArea(
        child: Stack(
          children: [
            // Close Button
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.close, color: Colors.white54, size: 32),
              ),
            ),

            // Content Center
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),

                // 1. Breathing Circle (Central Object)
                AnimatedBuilder(
                  animation: _breathingController,
                  builder: (context, child) {
                    final scale =
                        1.0 + (_breathingController.value * 0.2); // 1.0 ~ 1.2
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.amber.withOpacity(0.1),
                          border: Border.all(
                            color: Colors.amberAccent.withOpacity(0.6),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withOpacity(0.4),
                              blurRadius:
                                  20 +
                                  (_breathingController.value * 20), // 20 ~ 40
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          "Listen...",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w300,
                            fontStyle: FontStyle.italic,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const Spacer(),

                // 2. Fake Visualizer (Bottom)
                SizedBox(
                  height: 150,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(7, (index) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 100),
                        width: 20,
                        height: _barHeights[index],
                        decoration: BoxDecoration(
                          color: Colors.greenAccent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.greenAccent.withOpacity(0.5),
                              blurRadius: 10,
                              offset: const Offset(0, -2),
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
    );
  }
}
