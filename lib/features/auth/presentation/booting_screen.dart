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

class LoadingLine extends StatelessWidget {
  const LoadingLine({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
          width: 200,
          height: 1,
          decoration: BoxDecoration(
            color: const Color(0xFFCCFF00),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFCCFF00).withValues(alpha: 0.6),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
        )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .custom(
          duration: 1000.ms,
          builder: (context, value, child) {
            return Opacity(
              opacity: 0.5 + (value * 0.5), // Pulse 0.5 -> 1.0
              child: child,
            );
          },
        );
  }
}

class _BootingScreenState extends ConsumerState<BootingScreen> {
  @override
  void initState() {
    super.initState();
    _startBootingSequence();
  }

  Future<void> _startBootingSequence() async {
    // 1. Start Haptic
    await HapticService.light();

    // 2. Data Pre-fetch + Min Delay (1.5s)
    try {
      await Future.wait([
        ref.read(wishlistProvider.future),
        ref.read(savingProvider.future),
        Future.delayed(const Duration(milliseconds: 1500)),
      ]);
    } catch (e) {
      debugPrint('Booting data load error: $e');
    }

    // 3. Navigate (Silent Boot)
    if (mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFFCCFF00); // Neon Lime

    return Scaffold(
      backgroundColor: Colors.black, // [Pure Black UI]
      body: Stack(
        children: [
          // Layer 1: Stealth Grid (1% Opacity) [Grid Stealth]
          Positioned.fill(
            child: CustomPaint(
              painter: _GridPainter(opacity: 0.01), // 1% Opacity
            ),
          ),

          // Layer 2: Breathing Logo (Center)
          Align(
            alignment: Alignment.center,
            child:
                Text(
                      'NERVE',
                      style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 8.0,
                        color: accentColor,
                      ),
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(
                      begin: const Offset(1.0, 1.0),
                      end: const Offset(
                        1.02,
                        1.02,
                      ), // [Heartbeat] Subtle 1.0 -> 1.02
                      duration: 2000.ms,
                      curve: Curves.easeInOutSine,
                    )
                    .shimmer(
                      duration: 2000.ms,
                      color: Colors.white.withValues(
                        alpha: 0.5,
                      ), // [Shimmer] Subtle
                    ),
          ),

          // Layer 3: Dynamic Neon Flow Loading Line [Neon Flow]
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: 1500.ms,
              curve: Curves.easeInOutExpo,
              builder: (context, loadingProgress, child) {
                return Center(
                  child:
                      Container(
                            width:
                                MediaQuery.of(context).size.width *
                                loadingProgress,
                            height: 2, // Slightly thicker for neon effect
                            decoration: BoxDecoration(
                              color: accentColor,
                              boxShadow: [
                                BoxShadow(
                                  color: accentColor.withValues(alpha: 0.6),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          )
                          .animate(
                            onPlay: (c) => c.repeat(), // Continuous loop
                          )
                          .shimmer(
                            duration: 1500.ms,
                            color: accentColor.withValues(alpha: 0.5),
                            angle: 0.0, // Horizontal flow
                          ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Digital Grid Background Painter [Restored & Stealthed]
class _GridPainter extends CustomPainter {
  final double opacity;

  _GridPainter({this.opacity = 0.01}); // Default 1% Opacity

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
