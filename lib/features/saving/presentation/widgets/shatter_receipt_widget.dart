import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

/// ShatterReceiptWidget: 하이테크 NERVE 시스템이 발행하는 '전투 결과 보고서' 영수증 위젯입니다.
class ShatterReceiptWidget extends StatelessWidget {
  final String targetName;
  final double savedAmount;
  final VoidCallback? onComplete;
  final VoidCallback? onCollect; // Callback for the final action
  final double damageLevel; // 0.0 to 1.0

  static const Color _inkBlack = Color(0xFF000000);

  const ShatterReceiptWidget({
    super.key,
    required this.targetName,
    required this.savedAmount,
    this.onComplete,
    this.onCollect,
    this.damageLevel = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
    final approvalDate = DateFormat('yyyy-MMdd').format(now);

    return Center(
      child:
          ClipPath(
                clipper: _ReceiptClipper(),
                child: CustomPaint(
                  painter: _ReceiptPainter(damageLevel: damageLevel),
                  child: Container(
                    width: 320,
                    constraints: BoxConstraints(
                      maxHeight:
                          MediaQuery.of(context).size.height *
                          0.75, // 75% height constraint
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 24,
                    ),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. Top Header
                          const Text(
                            "카드결제승인",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _inkBlack,
                              fontFamily: 'Pretendard',
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Store Info
                          Column(
                            children: const [
                              Text(
                                "금융치료 전문센터",
                                style: TextStyle(
                                  color: _inkBlack,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "서울특별시 이성구 정신차려동",
                                style: TextStyle(
                                  color: _inkBlack,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildDashedLine(),
                          const SizedBox(height: 16),

                          // 2. Product & Amount (Heroized Target)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("상품명", style: _labelStyle),
                              Expanded(
                                child: Text(
                                  targetName,
                                  textAlign: TextAlign.end,
                                  style: const TextStyle(
                                    color: _inkBlack,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("금액", style: _labelStyle),
                              Text(
                                "${NumberFormat('#,###').format(savedAmount)} 원",
                                style: const TextStyle(
                                  color: _inkBlack,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildDashedLine(),
                          const SizedBox(height: 16),

                          // 3. Approval Detail Info
                          const Text(
                            "[승인정보]",
                            style: TextStyle(
                              color: _inkBlack,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildDetailRow("승인일시", dateStr),
                          const SizedBox(height: 4),

                          // Updated Section: Installment & VAT
                          _buildDetailRow("할부", "본인 양심 일시불"),
                          const SizedBox(height: 4),
                          _buildDetailRow(
                            "부가세",
                            "정신력",
                          ), // Changed from Fee to VAT as requested
                          const SizedBox(height: 4),

                          _buildDetailRow(
                            "결제금액",
                            "${NumberFormat('#,###').format(savedAmount)} 원",
                          ),

                          const SizedBox(height: 16),
                          _buildDashedLine(),
                          const SizedBox(height: 16),

                          // 4. Bottom Info
                          _buildDetailRow("매입사명", "nerve카드"),
                          const SizedBox(height: 4),
                          _buildDetailRow("카드종류", "nerve카드"),
                          const SizedBox(height: 4),
                          _buildDetailRow("승인번호", "NO-FLEX-$approvalDate"),

                          const SizedBox(height: 24),

                          // Footer Message REMOVED

                          // Final Collect Button
                          if (onCollect != null)
                            GestureDetector(
                              onTap: onCollect,
                              child:
                                  Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.redAccent,
                                            width: 1.5,
                                          ),
                                          color: Colors.redAccent.withOpacity(
                                            0.05,
                                          ),
                                        ),
                                        child: const Text(
                                          "영수증 챙기기",
                                          style: TextStyle(
                                            color: Colors.redAccent,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 1.0,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      )
                                      .animate(
                                        onPlay: (c) => c.repeat(reverse: true),
                                      )
                                      .shimmer(
                                        duration: 2.seconds,
                                        color: Colors.red.withOpacity(0.2),
                                      ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
              .animate()
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuart),
    );
  }

  static const _labelStyle = TextStyle(color: Colors.black54, fontSize: 12);

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: _labelStyle),
        Text(
          value,
          style: const TextStyle(
            color: _inkBlack,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDashedLine() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dashWidth = 4.0;
        final dashCount = (constraints.maxWidth / (2 * dashWidth)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Colors.black26),
              ),
            );
          }),
        );
      },
    );
  }
}

class _ReceiptClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return _getReceiptPath(size, 0.0);
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

Path _getReceiptPath(Size size, double damageLevel) {
  final path = Path();
  const double zigzagHeight = 4.0;
  const double zigzagWidth = 8.0;
  final int zigzagCount = (size.width / zigzagWidth).floor();
  final random = math.Random(42);

  // Top Zigzag
  path.moveTo(0, zigzagHeight);
  for (int i = 0; i <= zigzagCount; i++) {
    double tearY = 0;
    if (damageLevel > 0.2) {
      tearY = random.nextDouble() * 12 * damageLevel;
    }
    path.lineTo(i * zigzagWidth + (zigzagWidth / 2), tearY);
    path.lineTo((i + 1) * zigzagWidth, zigzagHeight);
  }

  // Right side
  path.lineTo(size.width, size.height - zigzagHeight);

  // Bottom Zigzag
  for (int i = zigzagCount; i >= 0; i--) {
    double tearY = size.height;
    if (damageLevel > 0.4) {
      tearY = size.height - (random.nextDouble() * 15 * damageLevel);
    }
    path.lineTo(i * zigzagWidth + (zigzagWidth / 2), tearY);
    path.lineTo(i * zigzagWidth, size.height - zigzagHeight);
  }

  // Left side
  path.close();
  return path;
}

class _ReceiptPainter extends CustomPainter {
  final double damageLevel;

  _ReceiptPainter({this.damageLevel = 0.0});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Background
    final paint = Paint()
      ..color = Colors
          .white // White thermal paper
      ..style = PaintingStyle.fill;

    final path = _getReceiptPath(size, damageLevel);

    // Shadow
    canvas.drawShadow(
      path.shift(const Offset(0, 8)),
      Colors.black.withOpacity(0.15),
      15,
      true,
    );

    // Draw Main Paper
    canvas.drawPath(path, paint);

    // CLIP to path
    canvas.save();
    canvas.clipPath(path);

    // 2. Scanline Texture (Black scanlines)
    final scanlinePaint = Paint()
      ..color = Colors.black.withOpacity(0.03)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (double i = 0; i < size.height; i += 3) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), scanlinePaint);
    }

    // Noise/Grain effect
    final noisePaint = Paint()
      ..color = Colors.black.withOpacity(0.03)
      ..style = PaintingStyle.fill;
    final random = math.Random(123);
    for (int i = 0; i < 400; i++) {
      canvas.drawCircle(
        Offset(
          random.nextDouble() * size.width,
          random.nextDouble() * size.height,
        ),
        0.4 + random.nextDouble(),
        noisePaint,
      );
    }

    // 3. Cracks/Damage with Black Visuals & Particles
    if (damageLevel > 0) {
      _drawCracks(canvas, size);
    }

    // 4. Border/Edge Highlight
    final borderPaint = Paint()
      ..color = Colors.black.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(path, borderPaint);

    // 5. Subtle Gradient Overlay for realism
    final gradientRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.black.withOpacity(0.02),
        Colors.transparent,
        Colors.black.withOpacity(0.05),
      ],
      stops: const [0.0, 0.4, 1.0],
    );

    final gradientPaint = Paint()
      ..shader = gradient.createShader(gradientRect)
      ..blendMode = BlendMode.srcATop;

    canvas.drawPath(path, gradientPaint);

    canvas.restore();
  }

  void _drawCracks(Canvas canvas, Size size) {
    final tearPath = Path();
    final random = math.Random(42); // Seed guarantees path consistency
    final int crackCount = (damageLevel * 12).toInt();

    final crackPaint = Paint()
      ..color = Colors.black
          .withOpacity(0.9) // Step 1: Deep black
      ..style = PaintingStyle.stroke
      ..strokeWidth =
          1.5 +
          random
              .nextDouble() // Step 2: Randomized width (1.5 ~ 2.5)
      ..strokeCap = StrokeCap
          .butt // Step 2: Sharp ends
      ..strokeJoin = StrokeJoin.miter;

    final debrisPaint = Paint()
      ..color =
          Colors.grey[800]! // Step 3: Debris particles
      ..style = PaintingStyle.fill;

    // Use a separate random for particles to not disturb path generation if needed,
    // but here we use the same sequence to keep particles attached to cracks.
    // However, to keep drawing the path efficiently as one path, we separate the logic:
    // 1. Generate path
    // 2. Draw path
    // 3. Draw particles near the path vertices

    for (int i = 0; i < crackCount; i++) {
      final startSide = random.nextInt(4);
      double startX, startY;
      switch (startSide) {
        case 0:
          startX = random.nextDouble() * size.width;
          startY = 0;
          break;
        case 1:
          startX = size.width;
          startY = random.nextDouble() * size.height;
          break;
        case 2:
          startX = random.nextDouble() * size.width;
          startY = size.height;
          break;
        default:
          startX = 0;
          startY = random.nextDouble() * size.height;
          break;
      }

      tearPath.moveTo(startX, startY);
      double curX = startX;
      double curY = startY;
      final double length = 40.0 + random.nextDouble() * 80.0 * damageLevel;

      for (int j = 0; j < 5; j++) {
        final double angle =
            (startSide * 90 + 135 + random.nextDouble() * 90) * (math.pi / 180);
        curX += math.cos(angle) * (length / 5);
        curY += math.sin(angle) * (length / 5);
        tearPath.lineTo(curX, curY);

        // Step 3: Scatter particles at vertices with some probability
        if (random.nextDouble() > 0.6) {
          canvas.drawCircle(
            Offset(
              curX + random.nextDouble() * 6 - 3,
              curY + random.nextDouble() * 6 - 3,
            ),
            0.6 + random.nextDouble() * 0.5,
            debrisPaint,
          );
        }
      }
    }

    canvas.drawPath(tearPath, crackPaint);
  }

  @override
  bool shouldRepaint(covariant _ReceiptPainter oldDelegate) =>
      oldDelegate.damageLevel != damageLevel;
}
