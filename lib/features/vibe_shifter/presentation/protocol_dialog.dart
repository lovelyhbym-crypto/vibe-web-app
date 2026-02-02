import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/ui/bouncy_button.dart';

class ProtocolDialog extends StatelessWidget {
  final Color themeColor;
  final String title;
  final String? subTitle; // [Added] Code Subtitle
  final String description;
  final Widget centerWidget;
  final Widget? bottomWidget;
  final VoidCallback onAccept;
  final bool isPulse;

  const ProtocolDialog({
    super.key,
    required this.themeColor,
    required this.title,
    this.subTitle, // [Added]
    required this.description,
    required this.centerWidget,
    this.bottomWidget,
    required this.onAccept,
    this.isPulse = false,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      // [UX Fix] Revert to standard padding to let system barrier handle dismissal
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 40.0,
        vertical: 24.0,
      ),
      child:
          ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 32,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.8),
                      borderRadius: const BorderRadius.all(
                        Radius.circular(2),
                      ), // Sharp tech corners
                      border: Border.all(
                        color: themeColor.withOpacity(0.5),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: themeColor.withOpacity(
                            0.2, // [Low Glow] subtle opacity
                          ),
                          blurRadius: 6, // [Low Glow] 30% of previous 20 -> ~6
                          spreadRadius: 0, // [Low Glow] Tight spread
                        ),
                      ],
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // "L" Corners
                        _buildCorner(true, true), // Top-Left
                        _buildCorner(true, false), // Top-Right
                        _buildCorner(false, true), // Bottom-Left
                        _buildCorner(false, false), // Bottom-Right
                        // Content
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Center Animation
                            SizedBox(
                              height: 120,
                              child: Center(child: centerWidget),
                            ),
                            const SizedBox(height: 24),

                            // Title
                            Text(
                                  title,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: themeColor,
                                    letterSpacing: 1.5,
                                    fontFamily: 'Courier',
                                    shadows: [
                                      BoxShadow(
                                        color: themeColor.withOpacity(0.8),
                                        blurRadius: 15,
                                      ),
                                    ],
                                  ),
                                )
                                .animate()
                                .fadeIn(duration: 300.ms)
                                .moveY(begin: 10, end: 0),

                            // SubTitle (Code Name)
                            if (subTitle != null) ...[
                              const SizedBox(
                                height: 16,
                              ), // [Padding] Added spacing
                              Text(
                                subTitle!,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: themeColor.withOpacity(0.7),
                                  fontFamily: 'Courier',
                                  letterSpacing: 2.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ).animate().fadeIn(delay: 200.ms),
                            ],

                            const SizedBox(
                              height: 32,
                            ), // [Visual Refinement] More Padding
                            // Typewriter Description
                            SizedBox(
                              height: 60, // Fixed height for 2 lines
                              child: Center(
                                child: Text(
                                  description,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                    height: 1.5,
                                    fontFamily: 'Courier',
                                  ),
                                ),
                              ),
                            ).animate().fadeIn(duration: 500.ms),

                            const SizedBox(height: 32),

                            // Bottom Widget (Timer etc)
                            if (bottomWidget != null) ...[
                              bottomWidget!,
                              const SizedBox(height: 24),
                            ],

                            // Accept Button
                            BouncyButton(
                                  onTap: onAccept,
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      color: themeColor.withOpacity(0.2),
                                      border: Border.all(
                                        color: themeColor.withOpacity(0.6),
                                      ),
                                      borderRadius: const BorderRadius.all(
                                        Radius.circular(4),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: themeColor.withOpacity(0.2),
                                          blurRadius: 10,
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      "프로토콜 가동 [START]", // [Refinement] Changed Text
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: themeColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18, // [Refinement] Size Up
                                        letterSpacing: 2.0,
                                        fontFamily: 'Courier',
                                      ),
                                    ),
                                  ),
                                )
                                .animate()
                                .fadeIn(delay: 800.ms)
                                .scale()
                                .then()
                                .animate(onPlay: (c) => c.repeat(reverse: true))
                                .shimmer(
                                  duration: 1500.ms,
                                  color: themeColor.withOpacity(0.5),
                                ), // Shimmer Animation
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .animate(onPlay: (c) => isPulse ? c.repeat(reverse: true) : null)
              .custom(
                duration: 1.seconds,
                builder: (context, value, child) {
                  if (!isPulse) return child;
                  return Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: themeColor.withOpacity(0.2 + (value * 0.3)),
                          blurRadius: 20 + (value * 20),
                          spreadRadius: value * 5,
                        ),
                      ],
                    ),
                    child: child,
                  );
                },
              ),
    );
  }

  Widget _buildCorner(bool isTop, bool isLeft) {
    const double size = 4.0; // [Minimalist] Halved from 8.0
    const double thickness = 1.0; // [Minimalist] Thin stroke

    return Positioned(
      top: isTop ? -2 : null,
      bottom: !isTop ? -2 : null,
      left: isLeft ? -2 : null,
      right: !isLeft ? -2 : null,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          border: Border(
            top: isTop
                ? BorderSide(color: themeColor, width: thickness)
                : BorderSide.none,
            bottom: !isTop
                ? BorderSide(color: themeColor, width: thickness)
                : BorderSide.none,
            left: isLeft
                ? BorderSide(color: themeColor, width: thickness)
                : BorderSide.none,
            right: !isLeft
                ? BorderSide(color: themeColor, width: thickness)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }
}
