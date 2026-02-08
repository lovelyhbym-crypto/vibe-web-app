import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/ui/glass_card.dart';
import '../../../../core/ui/bouncy_button.dart';
import '../../../../core/services/haptic_service.dart';
import '../../../../core/services/sound_service.dart';

class RealityAwarenessScreen extends StatefulWidget {
  const RealityAwarenessScreen({super.key});

  @override
  State<RealityAwarenessScreen> createState() => _RealityAwarenessScreenState();
}

class _RealityAwarenessScreenState extends State<RealityAwarenessScreen>
    with TickerProviderStateMixin {
  // 15 Master-Selected Missions
  final List<String> _missions = [
    '[ 찬물 한 컵 원샷하기 ]',
    '[ 팔굽혀펴기 15회 하기 ]',
    '[ 플랭크 자세로 30~60초 ]\n유지하기',
    '[ 온 힘을 다해 1분간 ]\n벽밀기',
    '[ 얼음 조각 손바닥에 올리고 ]\n30초 버티기',
    '[ 한 발로 서서 1분간 ]\n균형잡기',
    '[ 주변(책상 등) 깨끗히 ]\n청소하기',
    '[ 가장 아끼는 물건 ]\n정성껏 닦아주기',
    '[ 손 씻고 로션 바르며 ]\n감각 집중하기',
    '[ 지금 당장 고마운 사람에게 ]\n안부 전화나 문자 하기',
    '5-4-3-2-1 오감찾기\n보이는 것 5개, 들리는 소리 4개\n닿는 감촉 3개, 주변의 냄새 2개,\n입안의 맛 1개에\n감각을 집중하세요',
    '[ 1년 뒤 이 물건을 가진 ]\n나를 상상하기',
    '[ 사고 싶은 물건 이름 ]\n30번 반복하기',
    '[ 이 물건을 가지고 싶은 이유 ]\n3개 적기',
    '[ 좋아하는 음악 1곡 ]\n끝까지 감상하기',
  ];

  late String _currentMission;
  Timer? _timer;
  int _timeLeft = 180; // 3 minutes

  // Sequence Flags
  bool _isScanning = false;
  bool _isBlackout = false;
  bool _showSuccessReveal = false;
  double _scanLineY = -1.0;

  @override
  void initState() {
    super.initState();
    final rawMission = _missions[Random().nextInt(_missions.length)];
    // [Fixed] Don't add brackets - missions already include formatting
    _currentMission = rawMission;

    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_timeLeft > 0) {
        setState(() {
          _timeLeft--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _completeMission() async {
    _timer?.cancel();
    if (_isScanning || _isBlackout) return;

    // Feedback
    HapticService.success();
    // Integrated high-tech sweep sound via SoundService
    SoundService().playLaserScan();

    // Step 1: Laser Sweep (0.5s)
    setState(() {
      _isScanning = true;
      _scanLineY = -1.0;
    });

    const int sweepSteps = 25;
    const sweepDuration = Duration(milliseconds: 500 ~/ sweepSteps);
    for (int i = 0; i <= sweepSteps; i++) {
      await Future.delayed(sweepDuration);
      if (mounted) {
        setState(() {
          _scanLineY = -1.0 + (i / sweepSteps) * 2.5; // Sweep past bottom
        });
      }
    }

    // Step 2: The Blackout (0.5s)
    if (mounted) {
      setState(() {
        _isScanning = false;
        _isBlackout = true;
      });
    }
    await Future.delayed(const Duration(milliseconds: 500));

    // Step 3: Success Reveal (1.0s Fade-in)
    if (mounted) {
      setState(() {
        _showSuccessReveal = true;
      });
    }
    await Future.delayed(const Duration(seconds: 1));

    // Step 4: Wait & Auto-Navigation (1.0s) - Increased for better readability
    await Future.delayed(const Duration(seconds: 1));

    if (mounted && context.canPop()) {
      context.pop();
    }
  }

  String get _formattedTime {
    final minutes = (_timeLeft ~/ 60).toString().padLeft(2, '0');
    final seconds = (_timeLeft % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    const mintColor = Color(0xFF00FFD1);
    const neonBlueColor = Color(0xFF00E5FF);

    return Scaffold(
      backgroundColor: Colors.black, // Deep Dark Background
      body: Stack(
        children: [
          // 1. Grid Background
          Positioned.fill(
            child: CustomPaint(
              painter: _GridBackgroundPainter(
                scanLineY: _scanLineY,
                isScanning: _isScanning,
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Close Button (Custom placement)
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54),
                      onPressed: () {
                        if (context.canPop()) context.pop();
                      },
                    ),
                  ),

                  const Spacer(),

                  // 2. Icon & Tag
                  Column(
                    children: [
                      Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.black, // [UI] Pure Black Core
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: mintColor.withValues(alpha: 
                                  0.5,
                                ), // [UI] Thin Neon Lime
                                width: 0.5,
                              ),
                              // Multi-layered Shadow for Glow effect
                              boxShadow: [
                                BoxShadow(
                                  color: neonBlueColor.withValues(alpha: 0.25),
                                  blurRadius: 20,
                                  spreadRadius: 10,
                                ),
                                BoxShadow(
                                  color: neonBlueColor.withValues(alpha: 0.15),
                                  blurRadius: 40,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.bolt_rounded,
                              size: 60,
                              color: mintColor, // [UI] Neon Lime
                            ),
                          )
                          .animate(
                            onPlay: (c) => c.repeat(reverse: true),
                          ) // [UI] Pulse Loop
                          .scale(
                            begin: const Offset(1.0, 1.0),
                            end: const Offset(1.05, 1.05),
                            duration: 2.seconds,
                            curve: Curves.easeInOut,
                          )
                          .shimmer(duration: 3.seconds, color: Colors.white10)
                          .custom(
                            duration: 2.seconds,
                            curve: Curves.easeInOut,
                            builder: (context, value, child) {
                              // breathing glow pulse
                              final glowIntensity = 0.2 + (value * 0.2);
                              return Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: neonBlueColor.withValues(alpha: 
                                        glowIntensity,
                                      ),
                                      blurRadius: 20 + (value * 10),
                                      spreadRadius: 10 + (value * 5),
                                    ),
                                    BoxShadow(
                                      color: neonBlueColor.withValues(alpha: 
                                        glowIntensity * 0.5,
                                      ),
                                      blurRadius: 40 + (value * 20),
                                      spreadRadius: 5 + (value * 5),
                                    ),
                                  ],
                                ),
                                child: child,
                              );
                            },
                          ),
                      const SizedBox(height: 24), // [UI] Increased spacing
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: mintColor.withValues(alpha: 0.1),
                          border: Border.all(color: mintColor),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: const TextSpan(
                            style: TextStyle(
                              color: mintColor,
                              fontFamily: 'Courier',
                              height: 1.0,
                            ),
                            children: [
                              TextSpan(
                                text: "[ ",
                                style: TextStyle(
                                  fontSize: 17, // 1.2x bigger + visual weight
                                  fontWeight: FontWeight.w300, // Thinner
                                ),
                              ),
                              TextSpan(
                                text: "뇌 재부팅 중",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              TextSpan(
                                text: " ]",
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(delay: 200.ms),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Mission Text - Centered with brackets and width constraint
                  Center(
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.8,
                      ),
                      child:
                          Text(
                                _currentMission,
                                style: TextStyle(
                                  // [Dynamic] Smaller font for mission #11
                                  fontSize:
                                      _currentMission.contains('5-4-3-2-1 오감찾기')
                                      ? 14.0 // Reduced from 16.0
                                      : 20.0, // Reduced from 22.0
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  height: 1.4,
                                  fontFamily: 'Courier',
                                  letterSpacing:
                                      _currentMission.contains('5-4-3-2-1 오감찾기')
                                      ? 0.5
                                      : 1.2,
                                ),
                                textAlign: TextAlign.center,
                              )
                              .animate()
                              .fadeIn(duration: 500.ms)
                              .slideY(begin: 0.2, end: 0),
                    ),
                  ),

                  const SizedBox(height: 16),
                  const Text(
                    '지금 바로 위 행동을 수행하며\n충동을 흘려보내세요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  ),

                  const SizedBox(height: 48),

                  // 3. Digital Timer
                  Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          border: Border.all(
                            color: Colors.redAccent.withValues(alpha: 0.5),
                            width: 1, // [Refine] Thinner border
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child:
                            Text(
                                  _formattedTime,
                                  style: const TextStyle(
                                    fontSize: 56,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.redAccent,
                                    fontFamily:
                                        'Courier', // Digital Clock style fallback
                                    letterSpacing: 4,
                                    fontFeatures: [
                                      FontFeature.tabularFigures(),
                                    ],
                                    shadows: [
                                      BoxShadow(
                                        color: Colors.redAccent,
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                )
                                .animate(
                                  key: ValueKey(
                                    _timeLeft,
                                  ), // [Effect] Animate on change
                                )
                                .shake(
                                  duration: 100.ms,
                                  hz: 4,
                                  offset: const Offset(2, 0), // Subtle shake
                                ),
                      )
                      .animate(onPlay: (c) => c.repeat())
                      .shimmer(
                        duration: 2000.ms,
                        color: Colors.white.withAlpha(50),
                      ),

                  const Spacer(),

                  // 4. Complete Button
                  BouncyButton(
                    onTap: _completeMission,
                    child: GlassCard(
                      width: double.infinity,
                      height: 60,
                      backgroundColor: mintColor.withValues(alpha: 0.1),
                      border: Border.all(color: mintColor.withValues(alpha: 0.5)),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min, // [UI] Minimal size
                          children: [
                            const Icon(
                              Icons.check_circle_outline,
                              color: mintColor,
                              size: 18, // [UI] Matches bracket weight
                            ),
                            const SizedBox(width: 12), // [UI] Increased spacing
                            RichText(
                              text: const TextSpan(
                                style: TextStyle(
                                  color: mintColor,
                                  fontFamily: 'Courier',
                                  height: 1.0,
                                ),
                                children: [
                                  TextSpan(
                                    text: "[ ",
                                    style: TextStyle(
                                      fontSize:
                                          21, // [UI] More majestic brackets
                                      fontWeight: FontWeight.w300,
                                    ),
                                  ),
                                  TextSpan(
                                    text: "미션 완료",
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 2.5,
                                    ),
                                  ),
                                  TextSpan(
                                    text: " ]",
                                    style: TextStyle(
                                      fontSize: 21,
                                      fontWeight: FontWeight.w300,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // Step 1: Laser Sweep Overlay
          if (_isScanning)
            Positioned(
              left: 0,
              right: 0,
              top:
                  (MediaQuery.of(context).size.height *
                      (_scanLineY + 1.0) /
                      2.0) -
                  1,
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  color: mintColor,
                  boxShadow: [
                    BoxShadow(
                      color: mintColor.withValues(alpha: 1.0),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),

          // Step 2 & 3: Blackout & Reveal Layer
          if (_isBlackout)
            Positioned.fill(
              child: Container(
                color: Colors.black, // Pure #000000
                child: _showSuccessReveal
                    ? Stack(
                        alignment: Alignment.center,
                        children: [
                          // Digital Confetti: Small mint particles popping for 0.5s
                          ...List.generate(24, (index) {
                            final random = Random();
                            final angle = random.nextDouble() * 2 * pi;
                            final distance =
                                100.0 + random.nextDouble() * 150.0;
                            return Container(
                                  width: 2,
                                  height: 2,
                                  decoration: BoxDecoration(
                                    color: mintColor.withValues(alpha: 0.8),
                                    shape: BoxShape.rectangle,
                                  ),
                                )
                                .animate()
                                .move(
                                  begin: Offset.zero,
                                  end: Offset(
                                    cos(angle) * distance,
                                    sin(angle) * distance,
                                  ),
                                  duration: 500.ms,
                                  curve: Curves.easeOutCubic,
                                )
                                .fadeOut(duration: 500.ms);
                          }),

                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                    "[ MISSION_ACCOMPLISHED ]",
                                    maxLines: 1,
                                    softWrap: false,
                                    style: TextStyle(
                                      color: mintColor,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      fontFamily: 'Courier',
                                      letterSpacing: 1.0,
                                      shadows: [
                                        BoxShadow(
                                          color: mintColor,
                                          blurRadius: 15,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                  )
                                  .animate()
                                  .fadeIn(duration: 800.ms)
                                  .scale(
                                    begin: const Offset(0.9, 0.9),
                                    end: const Offset(1.0, 1.0),
                                  ),
                              const SizedBox(height: 16),
                              Text(
                                "성공적으로 유혹을 뿌리쳤습니다.\n오늘 하루 중 가장 잘한 일입니다.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: mintColor.withValues(alpha: 0.9),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Courier',
                                  height: 1.5,
                                ),
                              ).animate().fadeIn(
                                duration: 1.seconds,
                                delay: 200.ms,
                              ),
                            ],
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ),
        ],
      ),
    );
  }
}

// Grid Background Painter
class _GridBackgroundPainter extends CustomPainter {
  final double scanLineY;
  final bool isScanning;

  _GridBackgroundPainter({this.scanLineY = -1.0, this.isScanning = false});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.height <= 0 || size.width <= 0) {
      return; // [Fix] Prevent NaN or invalid layout crashes
    }

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const step = 40.0;

    for (double x = 0; x < size.width; x += step) {
      for (double y = 0; y < size.height; y += step) {
        double opacity = 0.05;

        if (isScanning) {
          // Highlight grid if close to scanline
          final normalizedY = (y / size.height) * 2.0 - 1.0;
          final diff = (normalizedY - scanLineY).abs();
          if (diff < 0.3) {
            // [Fix] Clamp opacity to prevent withValues(alpha: ) errors
            opacity = (0.4 * (1.0 - diff / 0.3)).clamp(0.0, 1.0);
          }
        }

        paint.color = Colors.white.withValues(alpha: opacity);
        canvas.drawRect(Rect.fromLTWH(x, y, step, step), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GridBackgroundPainter oldDelegate) =>
      oldDelegate.scanLineY != scanLineY ||
      oldDelegate.isScanning != isScanning;
}
