import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class I18n {
  final Locale locale;

  I18n(this.locale);

  static I18n of(BuildContext context) {
    return Localizations.of<I18n>(context, I18n) ?? I18n(const Locale('ko'));
  }

  bool get isKorean => locale.languageCode == 'ko';

  // Currency Formatting
  String formatCurrency(double amount) {
    final numberFormat = NumberFormat('#,###');
    if (isKorean) {
      return '${numberFormat.format(amount)}원';
    } else {
      return '\$${numberFormat.format(amount)}';
    }
  }

  // Settings
  String get settingsTitle => isKorean ? '설정' : 'Settings';
  String get languageSetting => isKorean ? '언어 설정' : 'Language';
  String get languageName => isKorean ? '한국어' : 'English';

  // Dashboard
  String get dashboardTitle => isKorean ? '대시보드' : 'Dashboard';
  String get totalSaved => isKorean ? '총 절약 금액' : 'Total Saved';
  String get keepResisting =>
      isKorean ? '계속해서 유혹을 이겨내세요!' : 'Keep resisting temptations!';
  String get startSavingToday =>
      isKorean ? '오늘부터 절약을 시작하세요!' : 'Start Saving Today!';
  String get recordFirstResistance => isKorean
      ? '첫 번째 저항을 기록하여 통계를 확인하세요.'
      : 'Record your resistance to see stats.';
  String get resistButtonLabel => isKorean ? 'Saving' : 'Saving';

  // Wishlist
  String get wishlistTitle => isKorean ? '위시리스트' : 'My Wishlist';
  String get wishlistEmpty =>
      isKorean ? '아직 위시리스트가 비어있어요' : 'Your wishlist is empty';
  String get wishlistAddTitle => isKorean ? '새 목표 추가' : 'Add New Goal';
  String get itemNameLabel => isKorean ? '항목 이름' : 'Item Name';
  String get priceLabel => isKorean ? '가격 / 목표 금액' : 'Price / Goal Amount';
  String get cancel => isKorean ? '취소' : 'Cancel';
  String get add => isKorean ? '추가' : 'Add';
  String get achieved => isKorean ? '달성' : 'Achieved';
  String get target => isKorean ? '목표' : 'Target';
  String get predictionPrefix => isKorean ? '예상 달성일: ' : 'Est. Completion: ';
  String get predictionUnknown => isKorean ? '데이터 부족' : 'Insufficient Data';

  // Saving Record
  String get recordSavingTitle => isKorean ? '절약 기록' : 'Record Saving';
  String get whatDidYouResist =>
      isKorean ? '어떤 유혹을 참았나요?' : 'What did you resist?';
  String get howMuchSaved => isKorean ? '얼마를 절약했나요?' : 'How much did you save?';
  String get amountLabel => isKorean ? '금액' : 'Amount';
  String get submitButton => isKorean ? 'Saved' : 'Saved';
  String get snackBarSelect =>
      isKorean ? '카테고리와 금액을 입력해주세요' : 'Please select category and enter amount';
  String get dialogGreatJob => isKorean ? 'Victory !' : 'Victory !';
  String get dialogCloser =>
      isKorean ? '에 한 발짝 더 가까워졌어요!' : 'You are one step closer to';
  String get dialogSaved =>
      isKorean ? '지갑이 두꺼워지는 소리' : 'Sound of wallet getting thicker';
  String get dialogNice => 'Nice! ✨';
  String get dialogAwesome => 'Nice! ✨';

  // Categories
  String categoryName(String id) {
    if (isKorean) {
      // Map English keys to Korean if necessary (e.g. 'Other' literal)
      switch (id) {
        case 'Other':
          return '기타';
        case 'Night Snack':
          return '야식';
        case 'Alcohol':
          return '술';
        case 'Coffee':
          return '커피';
        case 'Taxi':
          return '택시';
        default:
          return id;
      }
    } else {
      // Map Korean keys (from Provider) to English
      switch (id) {
        case '야식':
          return 'Night Snack';
        case '술':
          return 'Alcohol';
        case '커피':
          return 'Coffee';
        case '택시':
          return 'Taxi';
        case '기타':
          return 'Other';
        default:
          return id;
      }
    }
  }
}

class I18nDelegate extends LocalizationsDelegate<I18n> {
  const I18nDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'ko'].contains(locale.languageCode);

  @override
  Future<I18n> load(Locale locale) async => I18n(locale);

  @override
  bool shouldReload(I18nDelegate old) => false;
}
