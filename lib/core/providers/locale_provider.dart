import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'locale_provider.g.dart';

@Riverpod(keepAlive: true)
class LocaleNotifier extends _$LocaleNotifier {
  static const _localeKey = 'app_locale';

  @override
  Future<Locale> build() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString(_localeKey);

    if (savedCode != null) {
      return Locale(savedCode);
    }

    // Default to Korean if no preference is saved
    return const Locale('ko');
  }

  Future<void> setLocale(Locale locale) async {
    state = AsyncValue.data(locale);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale.languageCode);
  }

  Future<void> toggleLocale() async {
    final current = state.asData?.value ?? const Locale('ko');
    if (current.languageCode == 'ko') {
      await setLocale(const Locale('en'));
    } else {
      await setLocale(const Locale('ko'));
    }
  }
}

final localeProvider = localeNotifierProvider;
