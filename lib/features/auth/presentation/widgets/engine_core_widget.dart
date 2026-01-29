import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class EngineCoreWidget extends StatelessWidget {
  const EngineCoreWidget({super.key});

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFFCCFF00);

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Layer 3: Outer Pulse (Resonance)
          Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [accentColor.withOpacity(0.15), Colors.transparent],
                  ),
                ),
              )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1.2, 1.2),
                duration: 2.seconds,
                curve: Curves.easeInOut,
              )
              .fadeOut(
                begin: 0.4,
                duration: 2.seconds,
                curve: Curves.easeInOut,
              ),

          // Layer 2: Rotating Ring (Orbit)
          SizedBox(
                width: 150,
                height: 150,
                child: CustomPaint(
                  painter: _DashedCirclePainter(
                    color: accentColor.withOpacity(0.3),
                  ),
                ),
              )
              .animate(onPlay: (controller) => controller.repeat())
              .rotate(duration: 10.seconds),

          // Layer 1: Center Glow (The Kernel)
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: accentColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: accentColor.withOpacity(0.8),
                  spreadRadius: 20,
                  blurRadius: 40,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  final Color color;

  _DashedCirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final double radius = size.width / 2;
    const double dashWidth = 5;
    const double dashSpace = 5;
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
