import 'dart:ui';

import 'package:flutter/widgets.dart';

import '../core/localization/locale_controller.dart';
import 'generated/app_localizations.dart';

export 'generated/app_localizations.dart';
export 'generated/app_localizations_ar.dart';
export 'generated/app_localizations_de.dart';
export 'generated/app_localizations_en.dart';
export 'generated/app_localizations_es.dart';
export 'generated/app_localizations_nl.dart';

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

Locale currentAppLocale([Locale? locale]) {
  return _resolveSupportedLocale(
    locale ?? AppLocaleController.currentLocale ?? PlatformDispatcher.instance.locale,
  );
}

AppLocalizations appLocalizationsForCurrentLocale([Locale? locale]) {
  return lookupAppLocalizations(currentAppLocale(locale));
}

AppLocalizations appLocalizationsForDevice([Locale? locale]) {
  return appLocalizationsForCurrentLocale(locale);
}

AppLocalizations appLocalizationsForLocaleCode(String languageCode) {
  return appLocalizationsForDevice(Locale(languageCode));
}

String currentLanguageCode([Locale? locale]) {
  return currentAppLocale(locale).languageCode;
}

String deviceLanguageCode() {
  return _resolveSupportedLocale(PlatformDispatcher.instance.locale).languageCode;
}

Locale _resolveSupportedLocale(Locale locale) {
  for (final supported in AppLocalizations.supportedLocales) {
    if (supported.languageCode == locale.languageCode) {
      return supported;
    }
  }

  return AppLocalizations.supportedLocales.first;
}
