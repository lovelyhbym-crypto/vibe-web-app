import 'package:flutter_riverpod/flutter_riverpod.dart';

class RewardState {
  final bool isMonochrome;
  final bool showConfetti;
  final bool isTriggered; // 폭죽 대기 신호

  RewardState({
    this.isMonochrome = true,
    this.showConfetti = false,
    this.isTriggered = false,
  });

  RewardState copyWith({
    bool? isMonochrome,
    bool? showConfetti,
    bool? isTriggered,
  }) {
    return RewardState(
      isMonochrome: isMonochrome ?? this.isMonochrome,
      showConfetti: showConfetti ?? this.showConfetti,
      isTriggered: isTriggered ?? this.isTriggered,
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

  // 폭죽 장전 (즉시 이동 전 호출)
  void triggerConfetti() {
    state = state.copyWith(isTriggered: true);
  }

  // 폭죽 소비 (위시리스트 화면에서 재생 후 호출)
  void consumeConfetti() {
    state = state.copyWith(isTriggered: false);
  }

  // 다시 흑백으로 리셋 (자정 등 초기화용)
  void resetToGloom() {
    state = state.copyWith(
      isMonochrome: true,
      showConfetti: false,
      isTriggered: false,
    );
  }
}

final rewardStateProvider =
    StateNotifierProvider<RewardStateNotifier, RewardState>((ref) {
      return RewardStateNotifier();
    });
