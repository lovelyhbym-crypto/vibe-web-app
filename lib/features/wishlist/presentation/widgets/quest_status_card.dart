import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vive_app/features/wishlist/domain/wishlist_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class QuestStatusCard extends ConsumerWidget {
  final WishlistModel item;

  const QuestStatusCard({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 복구 조건 계산
    final dayProgress = (item.consecutiveValidDays / 3).clamp(0.0, 1.0);
    final amountGoal = item.totalGoal * 0.1;
    final amountProgress = (item.questSavedAmount / amountGoal).clamp(0.0, 1.0);

    return Material(
      type: MaterialType.transparency,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.75),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.redAccent.withOpacity(0.6),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.redAccent.withOpacity(0.2),
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
                const Icon(
                  Icons.restore_from_trash_rounded,
                  color: Colors.redAccent,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  "🚨 긴급 복구 퀘스트",
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              "아래 조건 중 하나만 달성해도 파괴된 꿈을 복구할 수 있습니다.",
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 16),

            // 미션 1: 성실함 증명
            _buildMissionRow(
              title: "성실함 증명: 3일 연속 송금하기",
              progress: dayProgress,
              progressText: "${item.consecutiveValidDays} / 3일",
              isDone: item.consecutiveValidDays >= 3,
            ),

            const SizedBox(height: 12),

            // 미션 2: 비용 지불
            _buildMissionRow(
              title: "복구 비용 지불: 원래 가격의 10% 송금하기",
              progress: amountProgress,
              progressText:
                  "${formatCurrency(item.questSavedAmount)} / ${formatCurrency(amountGoal)}",
              isDone: item.questSavedAmount >= amountGoal,
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
