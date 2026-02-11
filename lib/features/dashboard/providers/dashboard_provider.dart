import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter/foundation.dart';

import 'package:nerve/features/saving/providers/saving_provider.dart';
import 'package:nerve/features/wishlist/providers/wishlist_provider.dart';
import 'savings_period_provider.dart'; // Added Import
import '../domain/dashboard_model.dart';

part 'dashboard_provider.g.dart';

@riverpod
class DashboardNotifier extends _$DashboardNotifier {
  @override
  FutureOr<DashboardModel> build() async {
    debugPrint('📊 [DASHBOARD_PROVIDER] Building dashboard data');
    final savings = ref.watch(savingProvider).asData?.value ?? [];
    debugPrint('📊 [DASHBOARD_PROVIDER] Savings count: ${savings.length}');
    final wishlists = ref.watch(wishlistProvider).asData?.value ?? [];
    debugPrint('📊 [DASHBOARD_PROVIDER] Wishlists count: ${wishlists.length}');
    final period = ref.watch(savingsPeriodProvider); // Watch period
    debugPrint('📊 [DASHBOARD_PROVIDER] Period: $period');

    if (savings.isEmpty) {
      debugPrint('📊 [DASHBOARD_PROVIDER] No savings, returning empty model');
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
      final date = saving.createdAt;
      final savingDate = DateTime(date.year, date.month, date.day);

      // Filter Logic
      bool include = false;
      switch (period) {
        case SavingsPeriod.today:
          include = savingDate.isAtSameMomentAs(today);
          break;
        case SavingsPeriod.monthly:
          include = date.year == now.year && date.month == now.month;
          break;
        case SavingsPeriod.yearly:
          include = date.year == now.year;
          break;
      }

      if (include) {
        totalSaved += saving.amount;

        // Category Breakdown (Filtered)
        categoryBreakdown.update(
          saving.category,
          (value) => value + saving.amount,
          ifAbsent: () => saving.amount.toDouble(),
        );
      }

      // Independent Stats (Always calculate Today & Week regardless of filter?)
      // Actally, dashboard top card shows "Total Saved" which usually respects the filter.
      // But "average daily" etc might drastically change.
      // Let's stick to:
      // - totalSaved respects filter.
      // - categoryBreakdown respects filter.
      // - todaySaved, weekSaved, weeklyTrend are usually specific metrics.
      // However, if I select "Today", showing "Weekly Trend" might be weird if it's not filtered.
      // BUT, "Weekly Trend" usually means "Trend of the last 7 days". It doesn't make sense to filter it by "Today".
      // So I will keep "Today Saved", "Week Saved", "Weekly Trend" independently calculated from ALL data
      // OR should I?
      // "Statistics Tab... Filter System... Data Logic: 'Today' filter... sum only today's data".
      // This implies the MAIN numbers (summary) should be filtered.
      // I will keep weekly trend standard (last 7 days) because that's what a "Trend" is.

      if (savingDate.isAtSameMomentAs(today)) {
        todaySaved += saving.amount;
      }

      if (!savingDate.isBefore(weekStart)) {
        weekSaved += saving.amount;
        final dayIndex = savingDate.difference(weekStart).inDays;
        if (dayIndex >= 0 && dayIndex < 7) {
          weeklyTrend[dayIndex] += saving.amount;
        }
      }
    }

    // 2. Prediction Logic (Based on ALL time average? or Filtered?)
    // Prediction should probably use ALL data to be accurate.
    // "averageDaily" derived from "totalSaved" (if filtered) would be wrong if "Today" is selected.
    // So I need to calculate `allTimeTotal` for prediction.

    // Recalculate all-time total for average
    double allTimeTotal = 0;
    DateTime? firstSavingDate;
    if (savings.isNotEmpty) {
      firstSavingDate = savings.first.createdAt;
      allTimeTotal = savings.fold(0, (sum, item) => sum + item.amount);
    }

    DateTime? prediction;
    double? remaining;
    double averageDaily = 0;

    if (allTimeTotal > 0 && firstSavingDate != null) {
      final daysSinceStart = now.difference(firstSavingDate).inDays + 1;
      if (daysSinceStart > 0) {
        averageDaily = allTimeTotal / daysSinceStart;
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
      totalSaved: totalSaved, // Filtered
      todaySaved: todaySaved, // Always Today
      weekSaved: weekSaved, // Always Week
      categoryBreakdown: categoryBreakdown, // Filtered
      weeklyTrend: weeklyTrend, // Always 7-day trend
      topWishlistPrediction: prediction,
      topWishlistRemaining: remaining,
      averageDailySavings: averageDaily, // All-time average
    );
  }
}

final dashboardProvider = dashboardNotifierProvider;
