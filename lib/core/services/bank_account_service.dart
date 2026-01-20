import 'package:shared_preferences/shared_preferences.dart';

class BankAccountService {
  static const String _prefsBankCode = 'prefs_bank_code';
  static const String _prefsAccountNumber = 'prefs_account_number';

  // 계좌 정보 저장
  Future<void> saveAccountInfo(String bankCode, String accountNo) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsBankCode, bankCode);
    await prefs.setString(_prefsAccountNumber, accountNo);
  }

  // 계좌 정보 불러오기
  Future<Map<String, String?>> getAccountInfo() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return {
      'bankCode': prefs.getString(_prefsBankCode),
      'accountNumber': prefs.getString(_prefsAccountNumber),
    };
  }
}
