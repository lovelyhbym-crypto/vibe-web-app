import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vive_app/features/wishlist/domain/wishlist_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class QuestStatusCard extends ConsumerWidget {
  final WishlistModel item;

  const QuestStatusCard({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // [Priority Engine] 상태별 테마 결정
    final priority = item.priority;
    Color themeColor;
    String titleText;
    String descText;
    IconData headerIcon;

    switch (priority) {
      case WishlistPriority.broken:
        themeColor = Colors.redAccent;
        titleText = "🔥 시스템 파괴! (복구 시 안개 완전 제거)";
        descText = "아래 조건 중 하나만 달성해도 파괴된 꿈을 복구하고 안개를 걷어낼 수 있습니다.";
        headerIcon = Icons.error_outline_rounded;
        break;
      case WishlistPriority.highBlur:
        themeColor = Colors.deepOrangeAccent;
        titleText = "🚨 위험! 목표가 잊히고 있습니다.";
        descText = "안개가 너무 짙습니다. 즉시 생존 신고하거나 10% 이상 저축하여 세탁하세요.";
        headerIcon = Icons.warning_amber_rounded;
        break;
      case WishlistPriority.lowBlur:
        themeColor = Colors.amberAccent;
        titleText = "⚠️ 주의! 나태의 안개 유입 중";
        descText = "0원 버튼으로 가볍게 세탁하거나, 저축하여 안개를 제거하세요.";
        headerIcon = Icons.wb_cloudy_outlined;
        break;
      default:
        // Should not happen if filtered correctly, but fallback
        themeColor = Colors.grey;
        titleText = "상태 양호";
        descText = "현재 특별한 조치가 필요하지 않습니다.";
        headerIcon = Icons.check_circle_outline;
    }

    // 복구 조건 계산
    final dayProgress = (item.consecutiveValidDays / 2).clamp(0.0, 1.0);
    final amountGoal = item.totalGoal * 0.1;
    final amountProgress = (item.questSavedAmount / amountGoal).clamp(
      0.0,
      1.0,
    ); // 시각적으로는 누적액 보여줌

    return Material(
      type: MaterialType.transparency,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.75),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: themeColor.withOpacity(0.6), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: themeColor.withOpacity(0.2),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(headerIcon, color: themeColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    titleText,
                    style: TextStyle(
                      color: themeColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              descText,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 16),

            // 미션 1: 성실함 증명
            _buildMissionRow(
              title: "성실함 증명: 2일 연속 송금하기",
              progress: dayProgress,
              progressText: "${item.consecutiveValidDays} / 2일",
              isDone: item.consecutiveValidDays >= 2,
            ),

            const SizedBox(height: 12),

            // 미션 2: 비용 지불
            _buildMissionRow(
              title: "복구 비용 지불: 원래 가격의 10% 일시불로 지불하기",
              progress: amountProgress,
              progressText:
                  "${formatCurrency(item.questSavedAmount)} / ${formatCurrency(amountGoal)}",
              isDone:
                  item.questSavedAmount >=
                  amountGoal, // Note: Logic is now single transaction, but visual keeps cumulative status
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissionRow({
    required String title,
    required double progress,
    required String progressText,
    required bool isDone,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isDone ? Colors.greenAccent : Colors.white,
                  fontSize: 12,
                  fontWeight: isDone ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ),
            if (isDone)
              const Icon(
                Icons.check_circle,
                color: Colors.greenAccent,
                size: 14,
              ),
          ],
        ),
        const SizedBox(height: 6),
        Stack(
          children: [
            Container(
              height: 4,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              height: 4,
              width:
                  (progress * 1000) /
                  10, // Just a trick for rendering if width is unknown, but here we are in Column
              // Use LayoutBuilder for better precision if needed, but FractionallySizedBox is easier
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress,
                child: Container(
                  decoration: BoxDecoration(
                    color: isDone ? Colors.greenAccent : Colors.redAccent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            progressText,
            style: TextStyle(
              color: isDone ? Colors.greenAccent : Colors.white54,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

String formatCurrency(double amount) {
  final format = NumberFormat.currency(
    locale: 'ko_KR',
    symbol: '₩',
    decimalDigits: 0,
  );
  return format.format(amount);
}
