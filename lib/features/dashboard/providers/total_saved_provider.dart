import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nerve/features/saving/providers/saving_provider.dart';
import 'savings_period_provider.dart';

part 'total_saved_provider.g.dart';

@riverpod
double totalSaved(Ref ref) {
  final savingsAsync = ref.watch(savingProvider);
  final period = ref.watch(savingsPeriodProvider);

  return savingsAsync.maybeWhen(
    data: (list) {
      final now = DateTime.now();
      return list.fold(0.0, (sum, item) {
        bool include = false;
        switch (period) {
          case SavingsPeriod.total:
            include = true;
            break;
          case SavingsPeriod.yearly:
            include = item.createdAt.year == now.year;
            break;
          case SavingsPeriod.monthly:
            include =
                item.createdAt.year == now.year &&
                item.createdAt.month == now.month;
            break;
        }
        return include ? sum + item.amount : sum;
      });
    },
    orElse: () => 0.0,
  );
}
