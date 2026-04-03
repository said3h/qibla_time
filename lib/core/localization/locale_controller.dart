import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/generated/app_localizations.dart';

const _localePreferenceKey = 'app_locale_code';

class AppLocaleController extends StateNotifier<Locale?> {
  AppLocaleController() : super(currentLocale) {
    _loadSavedLocale();
  }

  static Locale? currentLocale;

  static Future<void> prime() async {
    currentLocale = await _readSavedLocale();
  }

  Future<void> setLocale(Locale? locale) async {
    final prefs = await SharedPreferences.getInstance();
    final supportedLocale = _supportedLocaleFor(locale);

    if (supportedLocale == null) {
      await prefs.remove(_localePreferenceKey);
    } else {
      await prefs.setString(_localePreferenceKey, supportedLocale.languageCode);
    }

    currentLocale = supportedLocale;
    state = supportedLocale;
  }

  Future<void> resetToSystem() async {
    await setLocale(null);
  }

  Future<void> _loadSavedLocale() async {
    final savedLocale = await _readSavedLocale();
    if (savedLocale?.languageCode == currentLocale?.languageCode &&
        savedLocale?.countryCode == currentLocale?.countryCode) {
      state = currentLocale;
      return;
    }

    currentLocale = savedLocale;
    state = savedLocale;
  }

  static Future<Locale?> _readSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_localePreferenceKey);
    if (languageCode == null || languageCode.isEmpty) {
      return null;
    }

    return _supportedLocaleFor(Locale(languageCode));
  }

  static Locale? _supportedLocaleFor(Locale? locale) {
    if (locale == null) {
      return null;
    }

    for (final supported in AppLocalizations.supportedLocales) {
      if (supported.languageCode == locale.languageCode) {
        return supported;
      }
    }

    return null;
  }

  static String effectiveLanguageCode([Locale? manualLocale]) {
    final locale = manualLocale ?? currentLocale;
    if (locale != null) {
      final supportedLocale = _supportedLocaleFor(locale);
      if (supportedLocale != null) {
        return supportedLocale.languageCode;
      }
    }

    final systemLocale = PlatformDispatcher.instance.locale;
    final supportedSystemLocale = _supportedLocaleFor(systemLocale);
    if (supportedSystemLocale != null) {
      return supportedSystemLocale.languageCode;
    }

    return 'es';
  }

  /// Returns the effective language code:
  /// 1. Manual locale if set
  /// 2. System locale if supported by app
  /// 3. Fallback to Spanish
  String get currentLanguageCode {
    return effectiveLanguageCode(state);
  }
}

final appLocaleControllerProvider =
    StateNotifierProvider<AppLocaleController, Locale?>((ref) {
  return AppLocaleController();
});

final currentLanguageCodeProvider = Provider<String>((ref) {
  final locale = ref.watch(appLocaleControllerProvider);
  return AppLocaleController.effectiveLanguageCode(locale);
});
