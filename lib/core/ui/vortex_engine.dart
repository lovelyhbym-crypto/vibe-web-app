import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class VortexEngine extends StatelessWidget {
  final bool isAccelerated;

  const VortexEngine({super.key, this.isAccelerated = false});

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFFCCFF00);
    final speedMultiplier = isAccelerated ? 3.0 : 1.0;

    return Container(
      height: 300,
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
              // Vortex Particles (Absorption Loop)
              ...List.generate(15, (index) {
                final random = math.Random();
                final angle = random.nextDouble() * 2 * math.pi;
                final distance = 180.0 + random.nextDouble() * 30.0;
                final startX = math.cos(angle) * distance;
                final startY = math.sin(angle) * distance;
                final baseDuration = (2.0 + random.nextDouble() * 1.5);
                final duration = (baseDuration / speedMultiplier).seconds;

                return Positioned(
                  left: centerX + startX,
                  top: centerY + startY,
                  child:
                      Container(
                            width: 2.5,
                            height: 2.5,
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: accentColor.withValues(alpha: 0.5),
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

              // Vortex Rings
              _VortexRing(
                diameter: 250,
                color: accentColor.withValues(alpha: 0.35),
                duration: (40.0 / speedMultiplier).seconds,
                clockwise: true,
              ),
              _VortexRing(
                diameter: 180,
                color: accentColor.withValues(alpha: 0.35),
                duration: (25.0 / speedMultiplier).seconds,
                clockwise: false,
              ),
              _VortexRing(
                diameter: 120,
                color: accentColor.withValues(alpha: 0.35),
                duration: (15.0 / speedMultiplier).seconds,
                clockwise: true,
              ),

              // The Kernel
              Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.8),
                          spreadRadius: 6,
                          blurRadius: 30,
                        ),
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.5),
                          spreadRadius: 15,
                          blurRadius: 50,
                        ),
                      ],
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(
                    begin: const Offset(1.0, 1.0),
                    end: const Offset(1.2, 1.2),
                    duration: (800 / speedMultiplier).ms,
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
          begin: const Offset(1.5, 1.5),
          end: const Offset(0.3, 0.3),
          duration: 4.seconds,
          curve: Curves.easeInSine,
        )
        .fadeOut(duration: 4.seconds, curve: Curves.easeInSine);
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
      ..strokeWidth = 1.2
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
