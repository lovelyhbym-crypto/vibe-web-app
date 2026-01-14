import 'dart:async';
import 'dart:math';
import 'dart:ui'; // For PathMetric
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/ui/background_gradient.dart';
import '../providers/glory_report_provider.dart';

class GloryReportScreen extends ConsumerStatefulWidget {
  const GloryReportScreen({super.key});

  @override
  ConsumerState<GloryReportScreen> createState() => _GloryReportScreenState();
}

class _GloryReportScreenState extends ConsumerState<GloryReportScreen> {
  bool _isGlitching = true;

  @override
  void initState() {
    super.initState();
    // Simulate glitch effect duration
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) {
        setState(() {
          _isGlitching = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final reportState = ref.watch(gloryReportProvider);
    const limeColor = Color(0xFFCCFF00);

    return BackgroundGradient(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          centerTitle: true,
          title:
              Text(
                    "PRIVATE ARCHIVE", // [THEME] Final Title
                    style: TextStyle(
                      color: _isGlitching ? Colors.redAccent : limeColor,
                      fontFamily: 'Courier', // Monospace for log feel
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                  )
                  .animate(
                    target: _isGlitching ? 1 : 0,
                    onPlay: (c) => c.repeat(reverse: true),
                  )
                  .shake(hz: 8, offset: const Offset(2, 2))
                  .tint(color: Colors.red, duration: 200.ms),
        ),
        body: Stack(
          children: [
            // Grid Background
            Positioned.fill(
              child: CustomPaint(painter: _GridBackgroundPainter()),
            ),

            // [FX] Particle Overlay (Supernova Mode) - Active when all ready
            if (reportState.isReady && !_isGlitching)
              const Positioned.fill(child: _ParticleOverlay()),

            _isGlitching
                ? _buildGlitchOverlay()
                : Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // 1. Resilience
                        Expanded(
                          child: _BlueprintSection(
                            title:
                                "SYSTEM INTEGRITY", // [THEME] Updated Section 1
                            subtitle: "Gravity Resistance Coefficient",
                            isUnlocked: reportState.has30Savings,
                            icon: Icons.shield,
                            unlockedContent:
                                "30개의 노이즈를 제거하고\n완벽한 시스템을 유지 중입니다.", // [THEME] Updated Desc
                            lockedContent:
                                "DATA MISSING: Need more resistance data (30+ Savings)",
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 2. Breakthrough
                        Expanded(
                          child: _BlueprintSection(
                            title: "ASSET SECURED", // [THEME] Updated Section 2
                            subtitle: "Escape Velocity Achievement",
                            isUnlocked: reportState.hasAchieved,
                            icon: Icons.rocket_launch,
                            unlockedContent:
                                "첫 번째 핵심 자산이\n안전하게 확보되었습니다.", // [THEME] Updated Desc
                            lockedContent:
                                "DATA MISSING: No successful launch recorded (Achieve 1 Goal)",
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 3. Consistency
                        Expanded(
                          child: _BlueprintSection(
                            title: "SYNC RATE", // [THEME] Updated Section 3
                            subtitle: "Temporal Stability",
                            isUnlocked: reportState.has3ConsecutiveDays,
                            icon: Icons.access_time_filled,
                            unlockedContent:
                                "일상과 목표의 동기화가\n흔들림 없이 유지되고 있습니다.", // [THEME] Updated Desc
                            lockedContent:
                                "DATA MISSING: Signal unstable (Save 3 days in a row)",
                          ),
                        ),

                        const SizedBox(height: 32),
                        if (reportState.isReady)
                          Column(
                            children: [
                              TextButton(
                                    onPressed: () {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Accessing Deep Archive...",
                                          ),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      "ACCESS FULL REPORT >",
                                      style: TextStyle(
                                        color: limeColor,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                  )
                                  .animate(onPlay: (c) => c.repeat())
                                  .shimmer(
                                    duration: 2000.ms,
                                    color: Colors.white,
                                  ),
                              const SizedBox(height: 20),
                              const Text(
                                "당신은 오늘, 어제보다 더 가벼워졌습니다.", // [THEME] Footer
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w300,
                                  letterSpacing: 1.0,
                                ),
                              ).animate().fadeIn(
                                delay: 2000.ms,
                                duration: 1000.ms,
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlitchOverlay() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.warning_amber, size: 80, color: Colors.redAccent)
              .animate(onPlay: (c) => c.repeat())
              .shake(hz: 20, offset: const Offset(5, 5))
              .fade(duration: 100.ms),
          const SizedBox(height: 20),
          const Text(
            "ESTABLISHING SECURE LINK...",
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Courier',
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ).animate().tint(color: Colors.greenAccent, duration: 500.ms),
          const SizedBox(height: 10),
          for (int i = 0; i < 5; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child:
                  Container(
                        height: 2,
                        width: Random().nextInt(300).toDouble() + 50,
                        color: Colors.white.withValues(
                          alpha: 0.5,
                        ), // [FIX] withValues
                      )
                      .animate(delay: (i * 100).ms, onPlay: (c) => c.repeat())
                      .slideX(begin: -1, end: 1, duration: 400.ms),
            ),
        ],
      ),
    );
  }
}

class _BlueprintSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isUnlocked;
  final IconData icon;
  final String unlockedContent;
  final String lockedContent;

  const _BlueprintSection({
    required this.title,
    required this.subtitle,
    required this.isUnlocked,
    required this.icon,
    required this.unlockedContent,
    required this.lockedContent,
  });

  @override
  Widget build(BuildContext context) {
    const limeColor = Color(0xFFCCFF00);
    final titleColor = isUnlocked ? limeColor : Colors.grey;
    final textColor = isUnlocked ? Colors.white : Colors.white24;

    // [FX] Breathing Animation for Border using Animate setup correctly
    // [FIX] Moved onPlay to Animate constructor
    return Animate(onPlay: (c) => c.repeat(reverse: true))
        .custom(
          duration: 2000.ms,
          begin: 1.0,
          end: 0.5,
          builder: (context, value, child) {
            final breathingColor = isUnlocked
                ? limeColor.withValues(alpha: value)
                : Colors.grey; // [FIX] withValues

            return CustomPaint(
              painter: _SectionBorderPainter(
                isUnlocked: isUnlocked,
                color: breathingColor,
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(
                    alpha: 0.3,
                  ), // [FIX] withValues
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                          isUnlocked ? icon : Icons.lock_outline,
                          color: titleColor,
                          size: 40,
                        )
                        .animate(target: isUnlocked ? 1 : 0)
                        .scale(
                          begin: const Offset(0.8, 0.8),
                          end: const Offset(1, 1),
                          duration: 500.ms,
                          curve: Curves.elasticOut,
                        ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              color: titleColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              letterSpacing: 1.5,
                              decoration: isUnlocked
                                  ? null
                                  : TextDecoration.lineThrough,
                              decorationColor: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                          const Divider(color: Colors.white12, height: 20),
                          Text(
                            isUnlocked ? unlockedContent : lockedContent,
                            style: TextStyle(
                              color: textColor,
                              fontFamily: 'Courier',
                              fontSize: 13,
                              fontStyle: isUnlocked
                                  ? FontStyle.normal
                                  : FontStyle.italic,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        )
        .animate()
        .fadeIn(duration: 800.ms)
        .slideX(begin: 0.1, end: 0);
  }
}

class _SectionBorderPainter extends CustomPainter {
  final bool isUnlocked;
  final Color color;

  const _SectionBorderPainter({required this.isUnlocked, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = isUnlocked ? 2 : 1
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(12),
    );

    if (isUnlocked) {
      canvas.drawRRect(rrect, paint);
    } else {
      // Dashed Border
      const double dashWidth = 6;
      const double dashSpace = 4;
      final Path path = Path()..addRRect(rrect);

      final Path dashPath = Path();
      double distance = 0.0;
      for (final PathMetric measurePath in path.computeMetrics()) {
        while (distance < measurePath.length) {
          dashPath.addPath(
            measurePath.extractPath(distance, distance + dashWidth),
            Offset.zero,
          );
          distance += dashWidth + dashSpace;
        }
      }
      canvas.drawPath(dashPath, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SectionBorderPainter oldDelegate) {
    return oldDelegate.isUnlocked != isUnlocked || oldDelegate.color != color;
  }
}

class _GridBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.white
          .withValues(alpha: 0.05) // [FIX] withValues
      ..strokeWidth = 1;

    const double gridSize = 40;

    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    final Paint crossPaint = Paint()
      ..color = Colors.white
          .withValues(alpha: 0.1) // [FIX] withValues
      ..strokeWidth = 2;

    for (double x = 0; x < size.width; x += gridSize * 2) {
      for (double y = 0; y < size.height; y += gridSize * 2) {
        const double len = 4;
        canvas.drawLine(Offset(x - len, y), Offset(x + len, y), crossPaint);
        canvas.drawLine(Offset(x, y - len), Offset(x, y + len), crossPaint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// [FX] Particle Overlay
class _ParticleOverlay extends StatefulWidget {
  const _ParticleOverlay();

  @override
  State<_ParticleOverlay> createState() => _ParticleOverlayState();
}

class _ParticleOverlayState extends State<_ParticleOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // Generate particles
    for (int i = 0; i < 50; i++) {
      _particles.add(_generateParticle());
    }
  }

  _Particle _generateParticle() {
    return _Particle(
      x: _random.nextDouble(),
      y: _random.nextDouble(),
      size: _random.nextDouble() * 3 + 1,
      speed: _random.nextDouble() * 0.2 + 0.05,
      opacity: _random.nextDouble() * 0.5 + 0.1,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _ParticlePainter(_particles, _controller.value),
        );
      },
    );
  }
}

class _Particle {
  double x;
  double y;
  final double size;
  final double speed;
  final double opacity;

  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double animationValue;

  _ParticlePainter(this.particles, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..style = PaintingStyle.fill;
    const limeColor = Color(0xFFCCFF00);

    for (var particle in particles) {
      // Move particle upwards
      particle.y -= particle.speed * 0.01;
      if (particle.y < 0) {
        particle.y = 1.0;
        particle.x = Random().nextDouble(); // Reset x
      }

      paint.color = limeColor.withValues(
        alpha: particle.opacity,
      ); // [FIX] withValues
      canvas.drawCircle(
        Offset(particle.x * size.width, particle.y * size.height),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
