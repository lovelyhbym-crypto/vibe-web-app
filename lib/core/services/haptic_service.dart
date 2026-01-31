import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

/// 전역 햅틱 피드백 시스템
/// 기계적이고 물리적인 피드백을 통해 사용자에게 상호작용의 확신을 제공합니다.
class HapticService {
  HapticService._();

  /// 사소한 상호작용 (다이얼, 가벼운 버튼, 키패드 입력 등)
  /// 아주 짧고 예리한 진동
  static Future<void> light() async {
    HapticFeedback.selectionClick();
    if (await Vibration.hasVibrator() == true) {
      Vibration.vibrate(duration: 30, amplitude: 128);
    }
  }

  /// 일반적인 상공/성공 (데이터 저장, 화면 전환 등)
  /// 묵직한 성공의 느낌
  static Future<void> medium() async {
    HapticFeedback.mediumImpact();
    if (await Vibration.hasCustomVibrationsSupport() == true) {
      Vibration.vibrate(duration: 100, amplitude: 180);
    } else {
      Vibration.vibrate(duration: 100);
    }
  }

  /// 강력한 경고 및 파괴 연출 (민감한 설정 접근, 이미지 파괴 등)
  /// 강한 충격
  static Future<void> heavy() async {
    HapticFeedback.heavyImpact();
    Vibration.vibrate(duration: 200, amplitude: 255);
  }

  /// 인증 성공 및 긍정적 피드백
  static Future<void> success() async {
    HapticFeedback.mediumImpact();
    Vibration.vibrate(duration: 150, amplitude: 200);
  }

  /// 인증 실패 및 부정적 피드백 (경고 의미 전달)
  /// 강한 진동 2회 시뮬레이셔닝
  static Future<void> error() async {
    HapticFeedback.heavyImpact();
    Vibration.vibrate(pattern: [0, 100, 100, 200]);
  }

  /// 시스템 파괴 및 최후의 경고 (데이터 초기화, 실패 확정)
  /// 가장 길고 묵직한 진동
  static Future<void> vibrate() async {
    HapticFeedback.vibrate();
    Vibration.vibrate(duration: 800);
  }
}
