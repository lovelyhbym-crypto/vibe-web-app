import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class EngineCoreWidget extends StatelessWidget {
  const EngineCoreWidget({super.key});

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFFCCFF00);

    return Container(
      height: 380, // 한 화면에 모든 UI가 보일 수 있도록 높이 최적화
      width: double.infinity,
      color: Colors.transparent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final centerX = constraints.maxWidth / 2;
          final centerY = constraints.maxHeight / 2;

          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Vortex Particles (Absorption Loop - Cosmic Scale)
              ...List.generate(15, (index) {
                final random = math.Random();
                final angle = random.nextDouble() * 2 * math.pi;
                // 우주적 스케일: 화면 완전히 바깥(500~800px)에서 유입
                final distance = 500.0 + random.nextDouble() * 300.0;
                final startX = math.cos(angle) * distance;
                final startY = math.sin(angle) * distance;
                final duration = (3.0 + random.nextDouble() * 2).seconds;

                return Positioned(
                  left: centerX + startX,
                  top: centerY + startY,
                  child:
                      Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: accentColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: accentColor.withOpacity(0.6),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          )
                          .animate(onPlay: (c) => c.repeat())
                          .move(
                            begin: Offset.zero,
                            end: Offset(-startX, -startY),
                            duration: duration,
                            curve: Curves.easeInQuad,
                          )
                          .fadeIn(duration: 600.ms)
                          .fadeOut(duration: 400.ms, delay: duration * 0.8),
                );
              }),

              // Vortex Rings (Cosmic Scale - 5x)
              _VortexRing(
                diameter: 250,
                color: accentColor.withOpacity(0.12),
                duration: 40.seconds,
                clockwise: true,
              ),
              _VortexRing(
                diameter: 180,
                color: accentColor.withOpacity(0.25),
                duration: 25.seconds,
                clockwise: false,
              ),
              _VortexRing(
                diameter: 120,
                color: accentColor.withOpacity(0.45),
                duration: 15.seconds,
                clockwise: true,
              ),

              // The Kernel (Vortex Singularity - Living Pulse)
              Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withOpacity(0.8),
                          spreadRadius: 6,
                          blurRadius: 20,
                        ),
                        BoxShadow(
                          color: accentColor.withOpacity(0.5),
                          spreadRadius: 12,
                          blurRadius: 40,
                        ),
                      ],
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(
                    begin: const Offset(1.0, 1.0),
                    end: const Offset(1.3, 1.3),
                    duration: 1.seconds,
                    curve: Curves.easeInOutSine,
                  ),
            ],
          );
        },
      ),
    );
  }
}

class _VortexRing extends StatelessWidget {
  final double diameter;
  final Color color;
  final Duration duration;
  final bool clockwise;

  const _VortexRing({
    required this.diameter,
    required this.color,
    required this.duration,
    required this.clockwise,
  });

  @override
  Widget build(BuildContext context) {
    return _RotatingDashedRing(
          diameter: diameter,
          color: color,
          duration: duration,
          clockwise: clockwise,
        )
        .animate(onPlay: (c) => c.repeat())
        .fadeIn(duration: 800.ms)
        .scale(
          begin: const Offset(3.5, 3.5), // 5.0 -> 3.5로 최적화
          end: const Offset(0.4, 0.4),
          duration: 6.seconds,
          curve: Curves.easeInSine,
        )
        .fadeOut(duration: 6.seconds, curve: Curves.easeInSine);
  }
}

class _RotatingDashedRing extends StatelessWidget {
  final double diameter;
  final Color color;
  final Duration duration;
  final bool clockwise;

  const _RotatingDashedRing({
    required this.diameter,
    required this.color,
    required this.duration,
    required this.clockwise,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
          width: diameter,
          height: diameter,
          child: CustomPaint(painter: _DashedCirclePainter(color: color)),
        )
        .animate(onPlay: (c) => c.repeat())
        .rotate(begin: 0, end: clockwise ? 1 : -1, duration: duration);
  }
}

class _DashedCirclePainter extends CustomPainter {
  final Color color;

  _DashedCirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final double radius = size.width / 2;
    const double dashWidth = 4;
    const double dashSpace = 6;
    final double totalLength = 2 * math.pi * radius;
    final int dashCount = (totalLength / (dashWidth + dashSpace)).floor();

    for (int i = 0; i < dashCount; i++) {
      final double startAngle = (i * (dashWidth + dashSpace)) / radius;
      final double endAngle = startAngle + (dashWidth / radius);
      canvas.drawArc(
        Rect.fromCircle(center: Offset(radius, radius), radius: radius),
        startAngle,
        endAngle - startAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
