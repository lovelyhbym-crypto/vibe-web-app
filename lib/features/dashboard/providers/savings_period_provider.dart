import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SavingsPeriod {
  total,
  yearly,
  monthly;

  String get label {
    switch (this) {
      case SavingsPeriod.total:
        return '전체'; // All Time
      case SavingsPeriod.yearly:
        return '올해'; // This Year
      case SavingsPeriod.monthly:
        return '이번 달'; // This Month
    }
  }
}

final savingsPeriodProvider = StateProvider<SavingsPeriod>((ref) {
  return SavingsPeriod.total;
});
