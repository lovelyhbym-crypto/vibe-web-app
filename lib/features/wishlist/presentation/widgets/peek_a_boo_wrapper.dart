import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// NERVE Peek-a-boo Discovery 시스템
///
/// 상세 화면 내 숨겨진 사이드 메뉴나 추가 액션의 존재를 시각적 힌트로 제공합니다.
///
/// **애니메이션 시퀀스:**
/// 1. 400ms: 우→좌로 화면 너비의 20% 돌출 (Curves.easeOutQuart)
/// 2. 300ms: 정지 (사용자 인지 시간)
/// 3. 400ms: 제자리로 복귀 (Curves.elasticOut - 탱글거리는 탄성감)
///
/// **철학:** "설명하지 마라. 시스템이 스스로 존재를 드러내게 하라."
class PeekABooWrapper extends StatelessWidget {
  /// 애니메이션을 적용할 자식 위젯
  final Widget child;

  /// 애니메이션 실행 여부 (최초 진입 시에만 true)
  final bool showAnimation;

  const PeekABooWrapper({
    super.key,
    required this.child,
    required this.showAnimation,
  });

  @override
  Widget build(BuildContext context) {
    // 최초 진입이 아니면 애니메이션 없이 바로 표시
    if (!showAnimation) return child;

    return child
        .animate()
        // 1. 400ms 동안 오른쪽에서 20% 돌출
        .moveX(
          begin: 0,
          end: -MediaQuery.of(context).size.width * 0.2,
          duration: 400.ms,
          curve: Curves.easeOutQuart,
        )
        // 2. 300ms 동안 멈춤 (사용자 인지 시간)
        .then(delay: 300.ms)
        // 3. 400ms 동안 다시 제자리로 복귀 (탄성 효과)
        .moveX(
          begin: 0,
          end: MediaQuery.of(context).size.width * 0.2,
          duration: 400.ms,
          curve: Curves.elasticOut,
        );
  }
}
