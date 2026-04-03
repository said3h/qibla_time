import 'package:hijri/hijri_calendar.dart';

import '../../../../l10n/l10n.dart';

HijriCalendar currentHijriDate([DateTime? date]) {
  HijriCalendar.setLocal('en');
  return HijriCalendar.fromDate(date ?? DateTime.now());
}

bool isRamadanMonth([DateTime? date]) {
  return currentHijriDate(date).hMonth == 9;
}

class RamadanStatus {
  const RamadanStatus({
    required this.detectedByDate,
    required this.automaticEnabled,
    required this.forced,
    required this.hijriDay,
    required this.hijriMonth,
    required this.hijriYear,
  });

  factory RamadanStatus.fromDate(
    DateTime date, {
    required bool automaticEnabled,
    required bool forced,
  }) {
    final hijri = currentHijriDate(date);
    return RamadanStatus(
      detectedByDate: hijri.hMonth == 9,
      automaticEnabled: automaticEnabled,
      forced: forced,
      hijriDay: hijri.hDay,
      hijriMonth: hijri.hMonth,
      hijriYear: hijri.hYear,
    );
  }

  final bool detectedByDate;
  final bool automaticEnabled;
  final bool forced;
  final int hijriDay;
  final int hijriMonth;
  final int hijriYear;

  bool get isEnabled => forced || (automaticEnabled && detectedByDate);

  bool get isManualPreview => forced && !detectedByDate;

  String get headerLabel {
    final l10n = appLocalizationsForCurrentLocale();
    return detectedByDate
        ? l10n.ramadanStatusHeaderDay(hijriDay)
        : l10n.ramadanStatusHeaderManual;
  }

  String get blessingMessage {
    final l10n = appLocalizationsForCurrentLocale();
    return detectedByDate
        ? l10n.ramadanStatusBlessingDetected
        : l10n.ramadanStatusBlessingManual;
  }

  String get dailySuggestion {
    final l10n = appLocalizationsForCurrentLocale();
    final suggestions = [
      l10n.ramadanStatusSuggestionDhikr,
      l10n.ramadanStatusSuggestionQuran,
      l10n.ramadanStatusSuggestionDua,
      l10n.ramadanStatusSuggestionSadaqah,
    ];

    final index = (hijriDay - 1).abs() % suggestions.length;
    return suggestions[index];
  }
}
