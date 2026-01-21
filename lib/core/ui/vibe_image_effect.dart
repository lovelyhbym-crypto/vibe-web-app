import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class VibeImageEffect extends StatelessWidget {
  final double progress;
  final String? imageUrl;
  final XFile? localImage;
  final double blurLevel;
  final bool isBroken;
  final double width;
  final double height;

  const VibeImageEffect({
    super.key,
    this.imageUrl,
    this.localImage,
    required this.progress,
    required this.blurLevel,
    required this.isBroken,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double w = width == double.infinity
            ? constraints.maxWidth
            : width;
        final double h = height == double.infinity
            ? constraints.maxHeight
            : height;

        return SizedBox(
          width: w,
          height: h,
          child: Stack(
            children: [
              // Layer 1: Base Image with Blur & Effects
              TweenAnimationBuilder<double>(
                tween: Tween<double>(end: blurLevel),
                duration: const Duration(milliseconds: 1500),
                curve: Curves.easeOutCubic,
                builder: (context, blurValue, child) {
                  return ImageFiltered(
                    imageFilter: ui.ImageFilter.blur(
                      sigmaX: blurValue,
                      sigmaY: blurValue,
                    ),
                    child: Stack(
                      children: [
                        // Base Grayscale Layer (Full width)
                        _buildImage(grayscale: true, w: w, h: h),

                        // Progress-based Color Layer (Clipped width)
                        ClipRect(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            widthFactor: progress,
                            child: _buildImage(grayscale: false, w: w, h: h),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              // Layer 2: The Shatter Overlay (Stabilized Phase 1)
              if (isBroken)
                Positioned.fill(
                  child: AnimatedOpacity(
                    opacity: 1.0,
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.fastOutSlowIn,
                    child: Stack(
                      children: [
                        // 1. Backdrop Blur (Dissolving the reality) - Encapsulated with ClipRect
                        Positioned.fill(
                          child: ClipRect(
                            child: BackdropFilter(
                              filter: ui.ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.2),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // 2. Dark Red Mood (Tint)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.black.withOpacity(0.5),
                                  Colors.red.withOpacity(0.25),
                                  Colors.black.withOpacity(0.5),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // 3. Crack Synthesis (Using broken_glass.png)
                        Positioned.fill(
                          child: Image.asset(
                            'assets/images/broken_glass.png',
                            fit: BoxFit.cover,
                            color: Colors.white.withOpacity(0.6),
                            colorBlendMode: BlendMode.overlay,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(), // Safe fallback if asset missing
                          ),
                        ),

                        // 4. Warning Labels
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(220),
                              borderRadius: BorderRadius.circular(2),
                              border: Border.all(
                                color: Colors.redAccent.withOpacity(0.7),
                                width: 1.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.redAccent.withOpacity(0.2),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.redAccent,
                                  size: 44,
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  "DREAM SHATTERED",
                                  style: TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2.0,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "SYSTEM CORRUPTED",
                                  style: TextStyle(
                                    color: Colors.redAccent.withOpacity(0.6),
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 3.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImage({
    required bool grayscale,
    required double w,
    required double h,
  }) {
    Widget img;
    if (localImage != null) {
      if (kIsWeb) {
        img = Image.network(
          localImage!.path,
          width: w,
          height: h,
          fit: BoxFit.cover,
        );
      } else {
        img = Image.file(
          File(localImage!.path),
          width: w,
          height: h,
          fit: BoxFit.cover,
        );
      }
    } else if (imageUrl != null) {
      img = Image.network(
        imageUrl!,
        width: w,
        height: h,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey[900],
          child: const Icon(Icons.image_not_supported, color: Colors.white24),
        ),
      );
    } else {
      img = Container(color: Colors.grey[900]);
    }

    if (grayscale) {
      return ColorFiltered(
        colorFilter: const ColorFilter.matrix([
          0.21,
          0.72,
          0.07,
          0,
          -30,
          0.21,
          0.72,
          0.07,
          0,
          -30,
          0.21,
          0.72,
          0.07,
          0,
          -30,
          0,
          0,
          0,
          1,
          0,
        ]),
        child: img,
      );
    }
    return img;
  }
}
