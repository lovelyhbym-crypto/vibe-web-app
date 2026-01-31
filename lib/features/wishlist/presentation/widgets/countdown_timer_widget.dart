import 'package:flutter/material.dart';
import 'dart:ui' as dart_ui;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vive_app/features/wishlist/providers/wishlist_provider.dart';
import 'package:vive_app/core/theme/app_theme.dart';

class CountdownTimerWidget extends ConsumerWidget {
  final DateTime targetDate;
  final bool isAchieved;

  const CountdownTimerWidget({
    super.key,
    required this.targetDate,
    this.isAchieved = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1초마다 갱신 (화면이 활성 상태일 때만)
    final _ = ref.watch(countdownProvider);

    if (isAchieved) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green),
        ),
        child: const Text(
          "MISSION CLEAR",
          style: TextStyle(
            color: Colors.greenAccent,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      );
    }

    final now = DateTime.now();
    final difference = targetDate.difference(now);

    // 만료 처리
    if (difference.isNegative) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red),
        ),
        child: const Text(
          "TIME OVER",
          style: TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      );
    }

    final days = difference.inDays;
    final hours = difference.inHours % 24;
    final minutes = difference.inMinutes % 60;
    final seconds = difference.inSeconds % 60;

    // 긴급 상태 판단 (24시간 미만)
    final isUrgent = difference.inHours < 24 && days == 0;

    final colors = Theme.of(context).extension<VibeThemeExtension>()!.colors;

    // 긴급 상태일 때 깜빡임 효과 (초 단위 짝/홀 이용)
    final isBlinking = isUrgent && (seconds % 2 != 0);
    final urgentColor = isBlinking
        ? colors.danger.withValues(alpha: 0.5)
        : colors.danger;

    // 폰트 스타일 정의
    final baseStyle = GoogleFonts.robotoMono(
      color: isUrgent
          ? urgentColor
          : colors.textMain.withValues(alpha: 0.7), // Semi-transparent white
      fontSize: 16,
      fontWeight: FontWeight.bold,
      letterSpacing: -0.5,
      shadows: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.3), // Softer shadow
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    );

    final highlightStyle = GoogleFonts.robotoMono(
      color: colors.danger, // Neon Red for seconds
      fontSize: 18,
      fontWeight: FontWeight.bold,
      letterSpacing: -0.5,
      shadows: [
        BoxShadow(
          color: colors.danger.withValues(alpha: 0.4), // Softer glow
          blurRadius: 8,
          spreadRadius: 2,
        ),
      ],
    );

    final unitStyle = const TextStyle(
      color: Colors.white38,
      fontSize: 12,
      fontWeight: FontWeight.normal,
    );

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: BackdropFilter(
        filter: dart_ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double
              .infinity, // Full width as requested "positioned left:0 right:0"
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.4),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.timer_outlined,
                color: isUrgent ? urgentColor : Colors.white70,
                size: 20,
              ),
              const SizedBox(width: 8),
              if (days > 0) ...[
                Text('D-$days', style: baseStyle),
                Text('일 ', style: unitStyle),
              ],
              Text('$hours', style: baseStyle),
              Text('시간 ', style: unitStyle),
              Text('$minutes', style: baseStyle),
              Text('분 ', style: unitStyle),
              // 초 단위 강조
              SizedBox(
                width: 32,
                child: Text(
                  '$seconds',
                  style: isUrgent
                      ? baseStyle.copyWith(color: urgentColor, fontSize: 18)
                      : highlightStyle,
                  textAlign: TextAlign.center,
                ),
              ),
              Text('초', style: unitStyle),
            ],
          ),
        ),
      ),
    );
  }
}
