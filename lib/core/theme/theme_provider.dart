import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_theme.dart';

// 테마 상태 관리자
final themeNotifierProvider =
    StateNotifierProvider<ThemeNotifier, VibeThemeMode>((ref) {
      return ThemeNotifier();
    });

class ThemeNotifier extends StateNotifier<VibeThemeMode> {
  // 기본값: 사이버펑크 (사용자의 요청으로 사이버펑크 모드로 고정)
  ThemeNotifier() : super(VibeThemeMode.cyberpunk);

  // 테마 변경 기능 비활성화 (사이버펑크 고정)
  void toggleTheme() {
    // state = state == VibeThemeMode.cyberpunk
    //     ? VibeThemeMode.pureFinance
    //     : VibeThemeMode.cyberpunk;
  }

  // 특정 테마로 강제 설정 비활성화 (사이버펑크 고정)
  void setMode(VibeThemeMode mode) {
    // state = mode;
  }
}
