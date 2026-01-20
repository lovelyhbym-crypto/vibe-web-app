import 'package:flutter_riverpod/flutter_riverpod.dart';

class RewardState {
  final bool isMonochrome;
  final bool showConfetti;

  RewardState({this.isMonochrome = true, this.showConfetti = false});

  RewardState copyWith({bool? isMonochrome, bool? showConfetti}) {
    return RewardState(
      isMonochrome: isMonochrome ?? this.isMonochrome,
      showConfetti: showConfetti ?? this.showConfetti,
    );
  }
}

class RewardStateNotifier extends StateNotifier<RewardState> {
  RewardStateNotifier() : super(RewardState());

  // 컬러 잠금 해제 및 폭죽 발사
  void unlockColor() {
    state = state.copyWith(isMonochrome: false, showConfetti: true);

    // 3초 뒤 폭죽 상태만 해제
    Future.delayed(const Duration(seconds: 3), () {
      state = state.copyWith(showConfetti: false);
    });
  }

  // 다시 흑백으로 리셋 (자정 등 초기화용)
  void resetToGloom() {
    state = state.copyWith(isMonochrome: true, showConfetti: false);
  }
}

final rewardStateProvider =
    StateNotifierProvider<RewardStateNotifier, RewardState>((ref) {
      return RewardStateNotifier();
    });
