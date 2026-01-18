import 'package:flutter/material.dart';

// 1. 테마의 종류를 정의하는 열거형
enum VibeThemeMode {
  cyberpunk, // 기존 네온 스타일
  pureFinance, // 토스 스타일 (신규)
}

// 2. 모든 테마가 반드시 가져야 할 색상 규칙 (Interface)
abstract class VibeColors {
  // 기본 배경색
  Color get background;
  // 카드나 모달의 배경색
  Color get surface;
  // 가장 강조되는 메인 텍스트
  Color get textMain;
  // 부가 설명 텍스트
  Color get textSub;
  // 포인트 컬러 (버튼, 강조 등)
  Color get accent;
  // 긍정/성공 색상
  Color get success;
  // 부정/위험 색상
  Color get danger;
  // 테두리나 구분선 (없을 수도 있음)
  Color get border;
  // 그리드 패턴 색상 (사이버펑크 전용, 퓨어에서는 투명)
  Color get gridLine;
}

// 3. [Cyberpunk] 기존 네온 스타일 구현체
class CyberpunkColors implements VibeColors {
  @override
  Color get background => const Color(0xFF121212); // Deep Dark
  @override
  Color get surface => const Color(0xFF1E1E1E);
  @override
  Color get textMain => const Color(0xFFE0E0E0);
  @override
  Color get textSub => const Color(0xFFAAAAAA);
  @override
  Color get accent => const Color(0xFFD4FF00); // Neon Yellow/Lime
  @override
  Color get success => const Color(0xFF00FF00); // Pure Neon Green
  @override
  Color get danger => const Color(0xFFFF003C); // Neon Red
  @override
  Color get border => const Color(0xFF333333);
  @override
  Color get gridLine => const Color(0xFF2A2A2A);
}

// 4. [Pure Finance] 토스 스타일 구현체 (New!)
class PureFinanceColors implements VibeColors {
  @override
  Color get background => const Color(0xFFF2F4F6); // 토스 전용 배경색
  @override
  Color get surface => const Color(0xFFFFFFFF); // 카드 및 위젯 배경
  @override
  Color get textMain => const Color(0xFF191F28); // 메인 텍스트 - 진회색
  @override
  Color get textSub => const Color(0xFF8B95A1); // 보조 텍스트 - 중간 회색
  @override
  Color get accent => const Color(0xFF3182F6); // Bright Toss Blue
  @override
  Color get success => const Color(0xFF008D00); // Standard Green
  @override
  Color get danger => const Color(0xFFF04452); // Soft Red (유지)
  @override
  Color get border => const Color(0xFFE5E8EB); // 구분선 및 비활성 테두리
  @override
  Color get gridLine => Colors.transparent; // 그리드 없음
}

// 5. 테마 팩토리: 색상뿐만 아니라 폰트 등 전체 테마 데이터 생성
class AppTheme {
  static ThemeData getTheme(VibeThemeMode mode) {
    final colors = mode == VibeThemeMode.cyberpunk
        ? CyberpunkColors()
        : PureFinanceColors();

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: colors.background,
      primaryColor: colors.accent,

      // 텍스트 테마 설정 (기본 색상 매핑)
      textTheme: TextTheme(
        bodyMedium: TextStyle(color: colors.textMain),
        bodySmall: TextStyle(color: colors.textSub),
        headlineMedium: TextStyle(
          color: colors.textMain,
          fontWeight: FontWeight.bold,
        ),
      ),

      // 카드 테마
      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: mode == VibeThemeMode.pureFinance ? 2 : 0, // 퓨어 모드만 그림자
        shadowColor: Colors.black.withOpacity(0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20), // 둥근 모서리 공통 적용
          side: mode == VibeThemeMode.cyberpunk
              ? BorderSide(color: colors.border)
              : BorderSide.none, // 사이버펑크만 테두리 있음
        ),
      ),

      // 앱바 테마
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: colors.textMain,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: colors.textMain),
      ),

      // 확장 테마 (커스텀 색상 접근을 위해 사용)
      extensions: [VibeThemeExtension(colors: colors)],
    );
  }
}

// 6. Flutter의 Theme 시스템에 우리만의 색상표를 주입하기 위한 확장 클래스
class VibeThemeExtension extends ThemeExtension<VibeThemeExtension> {
  final VibeColors colors;
  VibeThemeExtension({required this.colors});

  @override
  ThemeExtension<VibeThemeExtension> copyWith({VibeColors? colors}) {
    return VibeThemeExtension(colors: colors ?? this.colors);
  }

  @override
  ThemeExtension<VibeThemeExtension> lerp(
    ThemeExtension<VibeThemeExtension>? other,
    double t,
  ) {
    if (other is! VibeThemeExtension) return this;
    return this; // 색상 보간(애니메이션)은 복잡하므로 일단 생략하고 즉시 전환
  }
}
