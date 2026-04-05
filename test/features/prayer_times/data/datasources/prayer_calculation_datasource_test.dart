import 'package:adhan/adhan.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qibla_time/features/prayer_times/data/datasources/prayer_calculation_datasource.dart';
import 'package:qibla_time/features/prayer_times/domain/entities/prayer_location.dart';
import 'package:qibla_time/features/prayer_times/domain/entities/prayer_settings.dart';

void main() {
  group('PrayerCalculationDataSource.calculate', () {
    final dataSource = PrayerCalculationDataSource();
    const paris = PrayerLocation(latitude: 48.8566, longitude: 2.3522);
    const baseSettings = PrayerSettings(
      method: CalculationMethod.muslim_world_league,
      madhab: Madhab.shafi,
      timeOffsetMinutes: 0,
      fajrAngle: 18,
      ishaAngle: 17,
      methodName: 'Muslim World League',
    );
    final date = DateTime(2026, 4, 5, 15, 30);

    test('returns a normalized schedule with prayers in chronological order', () {
      final schedule = dataSource.calculate(
        location: paris,
        settings: baseSettings,
        now: date,
      );

      expect(schedule.date, DateTime(2026, 4, 5));
      expect(schedule.fajr.isBefore(schedule.dhuhr), isTrue);
      expect(schedule.dhuhr.isBefore(schedule.asr), isTrue);
      expect(schedule.asr.isBefore(schedule.maghrib), isTrue);
      expect(schedule.maghrib.isBefore(schedule.isha), isTrue);
    });

    test('applies the configured minute offset to all supported prayers', () {
      final withoutOffset = dataSource.calculate(
        location: paris,
        settings: baseSettings,
        now: date,
      );
      const offsetSettings = PrayerSettings(
        method: CalculationMethod.muslim_world_league,
        madhab: Madhab.shafi,
        timeOffsetMinutes: 10,
        fajrAngle: 18,
        ishaAngle: 17,
        methodName: 'Muslim World League',
      );

      final withOffset = dataSource.calculate(
        location: paris,
        settings: offsetSettings,
        now: date,
      );

      expect(
        withOffset.fajr.difference(withoutOffset.fajr),
        const Duration(minutes: 10),
      );
      expect(
        withOffset.dhuhr.difference(withoutOffset.dhuhr),
        const Duration(minutes: 10),
      );
      expect(
        withOffset.asr.difference(withoutOffset.asr),
        const Duration(minutes: 10),
      );
      expect(
        withOffset.maghrib.difference(withoutOffset.maghrib),
        const Duration(minutes: 10),
      );
      expect(
        withOffset.isha.difference(withoutOffset.isha),
        const Duration(minutes: 10),
      );
    });
  });
}
