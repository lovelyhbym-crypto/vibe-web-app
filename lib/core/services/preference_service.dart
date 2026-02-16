import 'package:shared_preferences/shared_preferences.dart';

/// NERVE Peek-a-boo Discovery 시스템을 위한 Preference 관리 서비스
///
/// 사용자의 최초 진입 여부를 판독하고, 1회 실행 애니메이션을 제어합니다.
class PreferenceService {
  static const String _keyFirstEntry = 'is_first_entry_detail';

  /// 최초 진입 여부 확인 및 업데이트
  ///
  /// Returns: true면 최초 진입, false면 이미 진입한 적 있음
  ///
  /// 이 메서드는 확인과 동시에 플래그를 false로 변경하여
  /// 다음 진입부터는 애니메이션이 실행되지 않도록 합니다.
  static Future<bool> checkAndMarkFirstEntry() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirst = prefs.getBool(_keyFirstEntry) ?? true;

    if (isFirst) {
      await prefs.setBool(_keyFirstEntry, false); // 확인 즉시 false로 변경
    }
    return isFirst;
  }

  /// [디버그용] 최초 진입 플래그를 초기화하여 애니메이션을 다시 볼 수 있게 함
  static Future<void> resetFirstEntry() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyFirstEntry, true);
  }
}
