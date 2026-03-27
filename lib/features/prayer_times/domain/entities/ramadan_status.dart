import 'package:hijri/hijri_calendar.dart';

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

  String get headerLabel =>
      detectedByDate ? 'Ramadán día $hijriDay' : 'Modo Ramadán manual';

  String get blessingMessage => detectedByDate
      ? 'Que Allah acepte tu ayuno y tus obras de hoy.'
      : 'Vista especial de Ramadán activada manualmente para pruebas.';

  String get dailySuggestion {
    const suggestions = [
      'Recuerda aumentar el dhikr hoy.',
      'Intenta leer un poco más de Corán hoy.',
      'Aprovecha este día para hacer dua con calma.',
      'Una pequeña sadaqah también cuenta durante Ramadán.',
    ];

    final index = (hijriDay - 1).abs() % suggestions.length;
    return suggestions[index];
  }
}
