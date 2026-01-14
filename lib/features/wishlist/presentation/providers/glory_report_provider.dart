import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../saving/providers/saving_provider.dart';
import '../../providers/wishlist_provider.dart';

class GloryReportState {
  final bool has30Savings;
  final bool hasAchieved;
  final bool has3ConsecutiveDays;

  bool get isReady => has30Savings && hasAchieved && has3ConsecutiveDays;

  const GloryReportState({
    required this.has30Savings,
    required this.hasAchieved,
    required this.has3ConsecutiveDays,
  });
}

final gloryReportProvider = Provider<GloryReportState>((ref) {
  final savingsAsync = ref.watch(savingProvider);
  final wishlistAsync = ref.watch(wishlistProvider);

  bool has30Savings = false;
  bool hasAchieved = false;
  bool has3ConsecutiveDays = false;

  // 1. Total Savings >= 30
  if (savingsAsync.hasValue) {
    final savings = savingsAsync.value!;
    has30Savings = savings.length >= 30;

    // 3. Consecutive Logic
    if (savings.isNotEmpty) {
      // Sort by date desc
      final sorted = List.of(savings)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      int consecutive = 1;
      for (int i = 0; i < sorted.length - 1; i++) {
        final current = sorted[i].createdAt;
        final next = sorted[i + 1].createdAt;

        // Normalize to dates
        final currentDate = DateTime(current.year, current.month, current.day);
        final nextDate = DateTime(next.year, next.month, next.day);

        final diff = currentDate.difference(nextDate).inDays;

        if (diff == 1) {
          consecutive++;
          if (consecutive >= 3) {
            has3ConsecutiveDays = true;
            break;
          }
        } else if (diff > 1) {
          consecutive = 1;
        }
      }
      // [DEBUG] CHEAT MODE: Force true for immediate review
      has3ConsecutiveDays = true;
    }
  }

  // 2. Achieved Count >= 1
  if (wishlistAsync.hasValue) {
    hasAchieved = wishlistAsync.value!.any((item) => item.isAchieved);
  }

  return GloryReportState(
    has30Savings: has30Savings,
    hasAchieved: hasAchieved,
    has3ConsecutiveDays: has3ConsecutiveDays,
  );
});
