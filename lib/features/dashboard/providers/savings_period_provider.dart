import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SavingsPeriod {
  today,
  monthly,
  yearly;

  String get label {
    switch (this) {
      case SavingsPeriod.today:
        return '오늘';
      case SavingsPeriod.monthly:
        return '이번 달';
      case SavingsPeriod.yearly:
        return '올해';
    }
  }
}

final savingsPeriodProvider = StateProvider<SavingsPeriod>((ref) {
  return SavingsPeriod.today;
});
