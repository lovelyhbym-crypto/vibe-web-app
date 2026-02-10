import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

/// 전역 햅틱 피드백 시스템
/// 기계적이고 물리적인 피드백을 통해 사용자에게 상호작용의 확신을 제공합니다.
class HapticService {
  HapticService._();

  static Future<void> _safeVibrate({
    int duration = 50,
    int amplitude = 128,
  }) async {
    try {
      if (await Vibration.hasVibrator() == true) {
        Vibration.vibrate(duration: duration, amplitude: amplitude);
      }
    } catch (_) {
      // Ignore MissingPluginException on macOS/Web
    }
  }

  /// 사소한 상호작용 (다이얼, 가벼운 버튼, 키패드 입력 등)
  /// 아주 짧고 예리한 진동
  static Future<void> light() async {
    HapticFeedback.selectionClick();
    await _safeVibrate(duration: 30, amplitude: 128);
  }

  /// 일반적인 상공/성공 (데이터 저장, 화면 전환 등)
  /// 묵직한 성공의 느낌
  static Future<void> medium() async {
    HapticFeedback.mediumImpact();
    await _safeVibrate(duration: 60, amplitude: 255);
  }

  /// 실패, 경고, 또는 중요한 시스템 알림
  /// 강하고 긴 진동
  static Future<void> heavy() async {
    HapticFeedback.heavyImpact();
    await _safeVibrate(duration: 100, amplitude: 255);
  }

  /// 불규칙하거나 특별한 패턴 (예: 오류 발생 시 뚝-뚝 끊김)
  static Future<void> error() async {
    HapticFeedback.vibrate();
    try {
      if (await Vibration.hasVibrator() == true) {
        Vibration.vibrate(
          pattern: [0, 50, 100, 50],
          intensities: [0, 255, 0, 255],
        );
      }
    } catch (_) {}
  }

  // --- Legacy Compatibility ---

  /// Alias for medium() - General success feedback
  static Future<void> success() => medium();

  /// Alias for heavy() - Default vibration
  static Future<void> vibrate() => heavy();
}
