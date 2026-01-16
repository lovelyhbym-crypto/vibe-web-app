import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

class SecureStorageService {
  final _storage = const FlutterSecureStorage();
  static const _pinKey = 'RESET_PIN_CODE';

  // PIN 저장
  Future<void> savePin(String pin) async {
    await _storage.write(key: _pinKey, value: pin);
  }

  // PIN 읽기 (없으면 null 반환)
  Future<String?> getPin() async {
    return await _storage.read(key: _pinKey);
  }

  // PIN 삭제
  Future<void> deletePin() async {
    await _storage.delete(key: _pinKey);
  }
}
