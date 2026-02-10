import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/haptic_service.dart';
import '../../wishlist/providers/wishlist_provider.dart';
import '../../saving/providers/saving_provider.dart';

/// [NERVE SYSTEM BOOTING SEQUENCE]
/// "CORE-LOG HYBRID" - Ver 1.0
///
/// 사용자가 '일반인'에서 '시스템 운영자'로 페르소나를 전환하는
/// 심리적 재부팅 과정을 시각화하는 부팅 화면
class BootingScreen extends ConsumerStatefulWidget {
  const BootingScreen({super.key});

  @override
  ConsumerState<BootingScreen> createState() => _BootingScreenState();
}

class _BootingScreenState extends ConsumerState<BootingScreen> {
  bool _isAccelerated = false;
  bool _shouldFlash = false;
  final List<String> _logs = [];
  Timer? _logTimer;
  int _logIndex = 0;

  // 시스템 로그 시퀀스
  final List<String> _systemLogs = [
    '> INITIALIZING NERVE_CORE_ENGINE...',
    '> ALLOCATING MEMORY SECTORS... [OK]',
    '> LINKING TO SECURE_DATABASE...',
    '> CONNECTING TO SUPABASE...',
    '> SYNCING WISHLIST_DATA...',
    '> RETRIEVING USER_STATE...',
    '> ANALYZING SAVING_LOG...',
    '> CALCULATING IMPACT_RATIO...',
    '> SYSTEM READY.',
    '> PROTOCOL: SAVE_YOUR_DREAMS.',
    '> ACCESS_GRANTED.',
  ];

  @override
  void initState() {
    super.initState();
    _startBootingSequence();
  }

  @override
  void dispose() {
    _logTimer?.cancel();
    super.dispose();
  }

  Future<void> _startBootingSequence() async {
    // 1. 시작 시 묵직한 진동
    await HapticService.heavy();

    // 2. 로그 출력 시작 (0.1초 간격)
    _logTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_logIndex < _systemLogs.length && mounted) {
        setState(() {
          _logs.add(_systemLogs[_logIndex]);
          _logIndex++;

          // 로그 출력 시 미세한 틱 진동
          HapticService.light();
        });
      }
    });

    // 3. 실제 데이터 로딩 시작 (병렬 처리)
    final startTime = DateTime.now();

    try {
      await Future.wait([
        ref.read(wishlistProvider.future),
        ref.read(savingProvider.future),
      ]);
    } catch (e) {
      debugPrint('Booting data load error (non-critical): $e');
    }

    final elapsed = DateTime.now().difference(startTime);

    // 4. 최소 1.5초 보장 (UX 안정성)
    final remainingTime = const Duration(milliseconds: 1500) - elapsed;
    if (remainingTime.isNegative == false) {
      await Future.delayed(remainingTime);
    }

    // 5. 로딩 50% 이상 완료 시 엔진 가속
    if (mounted) {
      setState(() => _isAccelerated = true);
    }

    // 6. 추가 대기 (가속 애니메이션 표현)
    await Future.delayed(const Duration(milliseconds: 800));

    // 7. 최종 Flash 연출
    if (mounted) {
      setState(() => _shouldFlash = true);
      await HapticService.heavy(); // 최종 점화 진동
    }

    await Future.delayed(const Duration(milliseconds: 300));

    // 8. 대시보드로 전환
    if (mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    const deepNavyBlack = Color(0xFF0A0A0E);
    const accentColor = Color(0xFFCCFF00); // Neon Lime

    return Scaffold(
      backgroundColor: deepNavyBlack,
      body: Stack(
        children: [
          // Layer 1: Digital Grid Background (Almost Invisible)
          Positioned.fill(
            child: CustomPaint(
              painter: _GridPainter(opacity: 0.015), // 1.5% Opacity
            ),
          ),

          // Layer 1.5: Heavy Vignette (Masking edges)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Colors.transparent,
                    deepNavyBlack, // Fade into background color
                  ],
                  stops: [0.2, 0.85], // Center 20% clear, edges completely dark
                  radius: 1.0, // Tighter radius to ensure dark edges
                ),
              ),
            ),
          ), // Layer 2: Breathing Logo (Center)
          Align(
            alignment: Alignment.center,
            child:
                Text(
                      'NERVE',
                      style: TextStyle(
                        fontFamily: 'Courier', // 기계적인 느낌 유지
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 8.0, // 넓은 자간으로 압도감
                        color: accentColor,
                      ),
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .custom(
                      duration: 2000.ms,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: 0.2 + (value * 0.8), // 0.2 -> 1.0 -> 0.2
                          child: child,
                        );
                      },
                    )
                    // 미세한 Glow 효과 (Breathing과 동기화)
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .custom(
                      duration: 2000.ms,
                      builder: (context, value, child) {
                        return Container(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: accentColor.withValues(
                                  alpha: 0.1 + (value * 0.2),
                                ),
                                blurRadius: 20 + (value * 20),
                                spreadRadius: value * 10,
                              ),
                            ],
                          ),
                          child: child,
                        );
                      },
                    ),
          ),

          // Layer 3: Minimal Progress Bar (Bottom Edge 1px)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 1, // 1px
              child: Stack(
                children: [
                  // Background Dim Line
                  Container(color: Colors.white.withValues(alpha: 0.05)),
                  // Progress Line
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutExpo,
                        width: _isAccelerated
                            ? constraints.maxWidth
                            : constraints.maxWidth *
                                  (_logIndex / _systemLogs.length),
                        color: accentColor,
                        child: Container(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: accentColor.withValues(alpha: 0.8),
                                blurRadius: 4,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Layer 4: Version Info (Top Right - Minimal)
          Positioned(
            top: 60,
            right: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'NERVE_OS',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.2),
                    fontFamily: 'Courier',
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),

          // Flash Effect (최종 점화)
          if (_shouldFlash)
            Positioned.fill(
              child: Container(color: accentColor.withValues(alpha: 0.2))
                  .animate()
                  .fadeIn(duration: 100.ms)
                  .then()
                  .fadeOut(duration: 200.ms),
            ),
        ],
      ),
    );
  }
}

/// Digital Grid Background Painter
/// shredder_mission_screen.dart에서 사용된 0.03 투명도 그리드
class _GridPainter extends CustomPainter {
  final double opacity;

  _GridPainter({this.opacity = 0.03});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: opacity)
      ..strokeWidth = 1;

    const gridSize = 40.0;

    // Vertical lines
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Horizontal lines
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
