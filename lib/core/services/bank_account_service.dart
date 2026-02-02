import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

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

  // 토스 딥링크 실행 및 폴백 (Step 1 & 2)
  Future<bool> launchToss({
    required String accountNo,
    required int amount,
    required VoidCallback onFallback,
  }) async {
    // 계좌번호 정제
    final cleanAccountNo = accountNo.replaceAll(RegExp(r'[^0-9]'), '');
    final String url =
        'supertoss://send?bank=092&accountNo=$cleanAccountNo&amount=$amount';
    final Uri uri = Uri.parse(url);

    try {
      final bool canLaunch = await canLaunchUrl(uri);
      if (canLaunch) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Cannot launch Toss app';
      }
    } catch (e) {
      // 딥링크 실패 시 폴백: 계좌번호 클립보드 복사
      await Clipboard.setData(ClipboardData(text: accountNo));
      onFallback();
      return false;
    }
  }
}
