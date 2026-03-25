import 'package:flutter_test/flutter_test.dart';
import 'package:qibla_time/features/prayer_times/domain/entities/home_insight.dart';
import 'package:qibla_time/features/prayer_times/domain/entities/ramadan_status.dart';
import 'package:qibla_time/features/prayer_times/domain/usecases/generate_home_insights.dart';
import 'package:qibla_time/features/tracking/models/tracking_models.dart';

void main() {
  group('GenerateHomeInsightsUseCase', () {
    const useCase = GenerateHomeInsightsUseCase();

    test('prioriza cuando falta una oracion para completar el dia', () {
      final now = DateTime(2026, 3, 25, 18);
      final tracking = TrackingState.fromData({
        '2026-03-25': {
          'fajr': true,
          'dhuhr': true,
          'asr': true,
          'maghrib': true,
          'isha': false,
        },
      });

      final summary = tracking.currentWeekSummary;
      final bundle = useCase(
        tracking: tracking,
        weeklySummary: summary,
        now: now,
      );

      expect(bundle.primary.kind, HomeInsightKind.progress);
      expect(bundle.primary.message, contains('Te falta 1 oracion'));
    });

    test('detecta mejora respecto a la semana pasada', () {
      final now = DateTime(2026, 3, 25, 18);
      final tracking = TrackingState.fromData({
        '2026-03-25': _day(5),
        '2026-03-24': _day(4),
        '2026-03-23': _day(4),
        '2026-03-22': _day(3),
        '2026-03-21': _day(4),
        '2026-03-20': _day(3),
        '2026-03-19': _day(4),
        '2026-03-18': _day(1),
        '2026-03-17': _day(1),
        '2026-03-16': _day(1),
        '2026-03-15': _day(1),
        '2026-03-14': _day(0),
        '2026-03-13': _day(1),
        '2026-03-12': _day(0),
      });

      final summary = tracking.currentWeekSummary;
      final bundle = useCase(
        tracking: tracking,
        weeklySummary: summary,
        now: now,
      );

      expect(
        [bundle.primary.kind, bundle.secondary?.kind],
        contains(HomeInsightKind.improvement),
      );
    });

    test('genera insight de Ramadan cuando aplica', () {
      final now = DateTime(2026, 3, 25, 18);
      final tracking = TrackingState.fromData({
        '2026-03-25': _day(3),
        '2026-03-24': _day(4),
        '2026-03-23': _day(4),
        '2026-03-22': _day(4),
        '2026-03-21': _day(4),
        '2026-03-20': _day(4),
        '2026-03-19': _day(4),
      });

      final bundle = useCase(
        tracking: tracking,
        weeklySummary: tracking.currentWeekSummary,
        now: now,
        ramadanStatus: const RamadanStatus(
          detectedByDate: true,
          automaticEnabled: true,
          forced: false,
          hijriDay: 12,
          hijriMonth: 9,
          hijriYear: 1447,
        ),
      );

      expect(
        [bundle.primary.kind, bundle.secondary?.kind],
        contains(HomeInsightKind.ramadan),
      );
    });
  });
}

Map<String, bool> _day(int completed) {
  const prayers = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];
  final result = <String, bool>{};
  for (var index = 0; index < prayers.length; index++) {
    result[prayers[index]] = index < completed;
  }
  return result;
}
