import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class VibeImageEffect extends StatelessWidget {
  final String? imageUrl;
  final XFile? localImage;
  final double blurLevel;
  final bool isBroken;
  final double width;
  final double height;
  final bool isGrayscale;

  const VibeImageEffect({
    super.key,
    this.imageUrl,
    this.localImage,
    required this.blurLevel,
    required this.isBroken,
    required this.width,
    required this.height,
    this.isGrayscale = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Layer 1 & 2: Original + Blur Animation
          TweenAnimationBuilder<double>(
            tween: Tween<double>(
              end: blurLevel,
            ), // begin을 제거하여 변화 시 부드럽게 애니메이션되도록 수정
            duration: const Duration(milliseconds: 1500),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: value, sigmaY: value),
                child: _buildImage(isGrayscale),
              );
            },
          ),

          // Layer 3: The Shatter (Glass Crack) - Asset-Free Safety Mode (연출 강화)
          AnimatedOpacity(
            opacity: isBroken ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 800),
            curve: Curves.fastOutSlowIn,
            child: Container(
              decoration: BoxDecoration(
                // 파괴됨을 명확히 알리기 위해 붉은색 색조(Wash) 효과 추가
                color: Colors.red.withOpacity(0.2),
                border: Border.all(
                  color: Colors.redAccent.withOpacity(0.8),
                  width: 8, // 보더 두께 강화
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
                      Text(
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
        ],
      ),
    );
  }

  Widget _buildImage(bool grayscale) {
    Widget img;
    if (localImage != null) {
      if (kIsWeb) {
        img = Image.network(
          localImage!.path,
          width: width,
          height: height,
          fit: BoxFit.cover,
        );
      } else {
        img = Image.file(
          File(localImage!.path),
          width: width,
          height: height,
          fit: BoxFit.cover,
        );
      }
    } else if (imageUrl != null) {
      img = Image.network(
        imageUrl!,
        width: width,
        height: height,
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
