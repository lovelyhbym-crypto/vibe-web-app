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
  final int brokenImageIndex;
  final double width;
  final double height;

  const VibeImageEffect({
    super.key,
    this.imageUrl,
    this.localImage,
    required this.progress,
    required this.blurLevel,
    required this.isBroken,
    this.brokenImageIndex = 0,
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
              // Layer 0: Original Gauge Image (Base Layer)
              // This logic runs regardless of isBroken status
              Stack(
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

              // Layer 1: Destruction Overlay (Top Layer)
              if (isBroken) ...[
                // Vignette Shadow Layer (Middle)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 0.8,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.8),
                        ],
                        stops: const [0.2, 1.0],
                      ),
                    ),
                  ),
                ),

                // Broken Glass Layer (Top)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Image.asset(
                      brokenImageIndex > 0
                          ? 'assets/images/broken_glass_$brokenImageIndex.png'
                          : 'assets/images/broken_glass_1.png', // Use _1 as default
                      fit: BoxFit.cover,
                      opacity: const AlwaysStoppedAnimation(0.8),
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback to _1 if specific random image is missing
                        return Image.asset(
                          'assets/images/broken_glass_1.png',
                          fit: BoxFit.cover,
                          opacity: const AlwaysStoppedAnimation(0.8),
                        );
                      },
                    ),
                  ),
                ),
              ],
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

    if (blurLevel > 0) {
      img = ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: blurLevel, sigmaY: blurLevel),
        child: img,
      );
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
