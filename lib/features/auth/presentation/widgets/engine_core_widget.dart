import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class EngineCoreWidget extends StatelessWidget {
  const EngineCoreWidget({super.key});

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFFCCFF00);

    return Center(
      child: SizedBox(
        width: 300,
        height: 300,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Vortex Particles (Absorption Loop)
            ...List.generate(12, (index) {
              final random = math.Random();
              final angle = random.nextDouble() * 2 * math.pi;
              final distance = 180.0 + random.nextDouble() * 100.0;
              final startX = math.cos(angle) * distance;
              final startY = math.sin(angle) * distance;

              return Positioned(
                left: 150 + startX, // Center of 300
                top: 150 + startY,
                child:
                    Container(
                          width: 2,
                          height: 2,
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.9),
                            shape: BoxShape.circle,
                          ),
                        )
                        .animate(onPlay: (c) => c.repeat())
                        .move(
                          begin: Offset.zero,
                          end: Offset(-startX, -startY),
                          duration: (1.0 + random.nextDouble() * 2).seconds,
                          curve: Curves.easeInQuad,
                        )
                        .fadeIn(duration: 400.ms)
                        .fadeOut(duration: 200.ms, delay: 1.5.seconds),
              );
            }),

            // Vortex Rings (Imploding toward center)
            _VortexRing(
              diameter: 250,
              color: accentColor.withOpacity(0.1),
              duration: 40.seconds,
              clockwise: true,
            ),
            _VortexRing(
              diameter: 180,
              color: accentColor.withOpacity(0.2),
              duration: 25.seconds,
              clockwise: false,
            ),
            _VortexRing(
              diameter: 120,
              color: accentColor.withOpacity(0.4),
              duration: 15.seconds,
              clockwise: true,
            ),

            // The Kernel (Vortex Singularity)
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: accentColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withOpacity(0.6),
                    spreadRadius: 4,
                    blurRadius: 15,
                  ),
                  BoxShadow(
                    color: accentColor.withOpacity(0.4),
                    spreadRadius: 8,
                    blurRadius: 30,
                  ),
                ],
              ),
            ),
          ],
        ),
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
        .scale(
          begin: const Offset(1.6, 1.6),
          end: const Offset(0.4, 0.4),
          duration: 3.seconds,
          curve: Curves.easeInSine,
        )
        .fadeOut(duration: 3.seconds, curve: Curves.easeInSine);
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
