import 'dart:io';
import 'dart:ui';
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
                    imageFilter: ImageFilter.blur(
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

              // Layer 2: The Shatter Overlay
              Positioned.fill(
                child: AnimatedOpacity(
                  opacity: isBroken ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.fastOutSlowIn,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      border: Border.all(
                        color: Colors.redAccent.withOpacity(0.8),
                        width: 8,
                      ),
                    ),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.redAccent),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.redAccent,
                              size: 40,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "DREAM SHATTERED",
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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
