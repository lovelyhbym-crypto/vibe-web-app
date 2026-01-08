import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vive_app/features/saving/providers/saving_provider.dart';
import 'package:vive_app/features/wishlist/providers/wishlist_provider.dart';
import '../domain/dashboard_model.dart';

part 'dashboard_provider.g.dart';

@riverpod
class DashboardNotifier extends _$DashboardNotifier {
  @override
  FutureOr<DashboardModel> build() async {
    final savings = ref.watch(savingProvider).asData?.value ?? [];
    final wishlists = ref.watch(wishlistProvider).asData?.value ?? [];

    if (savings.isEmpty) {
      return DashboardModel.empty();
    }

    // 1. Calculate General Metrics
    double totalSaved = 0;
    double todaySaved = 0;
    double weekSaved = 0;
    final Map<String, double> categoryBreakdown = {};
    final List<double> weeklyTrend = List.filled(7, 0.0);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(const Duration(days: 6));

    for (final saving in savings) {
      totalSaved += saving.amount;

      // Category Breakdown
      categoryBreakdown.update(
        saving.category,
        (value) => value + saving.amount,
        ifAbsent: () => saving.amount.toDouble(), // explicitly cast to double
      );

      // Date calculations
      final date = saving.createdAt;
      final savingDate = DateTime(date.year, date.month, date.day);

      if (savingDate.isAtSameMomentAs(today)) {
        todaySaved += saving.amount;
      }

      // Weekly Stats
      if (!savingDate.isBefore(weekStart)) {
        weekSaved += saving.amount;
        final dayIndex = savingDate.difference(weekStart).inDays;
        if (dayIndex >= 0 && dayIndex < 7) {
          weeklyTrend[dayIndex] += saving.amount;
        }
      }
    }

    // 2. Prediction Logic
    DateTime? prediction;
    double? remaining;
    double averageDaily = 0;

    DateTime? firstSavingDate;
    if (savings.isNotEmpty) {
      // Assuming savings are sorted by createdAt, oldest first. If not, find min.
      // The original code used `savings.last.createdAt` which implies the last added saving.
      // If we want the *first* saving date to calculate average, we should use the oldest.
      // For simplicity, let's assume `savings.first` is the oldest if sorted, or `savings.last` if it means the most recent.
      // Sticking to the original intent of `savings.last` for "first saving date" in the context of calculating days since start.
      // If `savings` is ordered by creation date ascending, `savings.first` is the oldest.
      // If `savings` is ordered by creation date descending, `savings.last` is the oldest.
      // Let's assume `savings.first` is the oldest for calculating average daily from the start of saving.
      firstSavingDate = savings.first.createdAt;
    }

    if (totalSaved > 0 && firstSavingDate != null) {
      // Calculate daily average from the first saving date
      final daysSinceStart = now.difference(firstSavingDate).inDays + 1;
      if (daysSinceStart > 0) {
        averageDaily = totalSaved / daysSinceStart;
      }
    }

    if (wishlists.isNotEmpty) {
      final topItem = wishlists.first;
      remaining = topItem.totalGoal - topItem.savedAmount;

      if (remaining > 0 && averageDaily > 0) {
        final daysToFinish = (remaining / averageDaily).ceil();
        prediction = now.add(Duration(days: daysToFinish));
      }
    }

    return DashboardModel(
      totalSaved: totalSaved,
      todaySaved: todaySaved,
      weekSaved: weekSaved,
      categoryBreakdown: categoryBreakdown,
      weeklyTrend: weeklyTrend,
      topWishlistPrediction: prediction,
      topWishlistRemaining: remaining,
      averageDailySavings: averageDaily,
    );
  }
}

final dashboardProvider = dashboardNotifierProvider;
