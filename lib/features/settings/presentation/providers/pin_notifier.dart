import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nerve/core/services/secure_storage_service.dart';

final pinProvider = StateNotifierProvider<PinNotifier, AsyncValue<String?>>((
  ref,
) {
  return PinNotifier(ref.read(secureStorageServiceProvider));
});

class PinNotifier extends StateNotifier<AsyncValue<String?>> {
  final SecureStorageService _storage;

  PinNotifier(this._storage) : super(const AsyncValue.loading()) {
    _loadPin();
  }

  // 저장된 PIN 로드
  Future<void> _loadPin() async {
    state = const AsyncValue.loading();
    final pin = await _storage.getPin();
    state = AsyncValue.data(pin);
  }

  // PIN 등록
  Future<void> registerPin(String pin) async {
    await _storage.savePin(pin);
    state = AsyncValue.data(pin);
  }

  // PIN 검증
  Future<bool> verifyPin(String input) async {
    // 현재 상태가 로딩 중이거나 에러라면 다시 로드 시도 (혹은 실패 처리)
    if (!state.hasValue) {
      final pin = await _storage.getPin();
      if (pin == null) return false; // PIN이 없는데 검증할 순 없음.
      return pin == input;
    }

    final savedPin = state.value;
    return savedPin == input;
  }
}
