import 'package:adhan/adhan.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qibla_time/features/prayer_times/data/datasources/prayer_calculation_datasource.dart';
import 'package:qibla_time/features/prayer_times/domain/entities/prayer_location.dart';
import 'package:qibla_time/features/prayer_times/domain/entities/prayer_schedule.dart';
import 'package:qibla_time/features/prayer_times/domain/entities/prayer_settings.dart';

void main() {
  group('PrayerCalculationDataSource.calculate', () {
    final dataSource = PrayerCalculationDataSource();
    const paris = PrayerLocation(latitude: 48.8566, longitude: 2.3522);
    const madrid = PrayerLocation(latitude: 40.4168, longitude: -3.7038);
    const makkah = PrayerLocation(latitude: 21.3891, longitude: 39.8579);
    const london = PrayerLocation(latitude: 51.5074, longitude: -0.1278);
    const oslo = PrayerLocation(latitude: 59.9139, longitude: 10.7522);
    const baseSettings = PrayerSettings(
      method: CalculationMethod.muslim_world_league,
      madhab: Madhab.shafi,
      timeOffsetMinutes: 0,
      fajrAngle: 18,
      ishaAngle: 17,
      methodName: 'Muslim World League',
    );
    final date = DateTime(2026, 4, 5, 15, 30);

    test('returns a normalized schedule with prayers in chronological order',
        () {
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

    test('calculates valid prayer times for Madrid on a concrete date', () {
      final schedule = dataSource.calculate(
        location: madrid,
        settings: baseSettings,
        now: DateTime(2026, 6, 18, 21, 45),
      );

      expect(schedule.date, DateTime(2026, 6, 18));
      _expectValidPrayerSchedule(schedule);
    });

    test('calculates valid prayer times for Makkah on a concrete date', () {
      final schedule = dataSource.calculate(
        location: makkah,
        settings: baseSettings,
        now: DateTime(2026, 3, 10, 4, 15),
      );

      expect(schedule.date, DateTime(2026, 3, 10));
      _expectValidPrayerSchedule(schedule);
    });

    test('calculates valid prayer times for London during daylight saving time',
        () {
      final schedule = dataSource.calculate(
        location: london,
        settings: baseSettings,
        now: DateTime(2026, 7, 12, 12, 0),
      );

      expect(schedule.date, DateTime(2026, 7, 12));
      _expectValidPrayerSchedule(schedule);
    });

    test('handles a high latitude city without invalid prayer times', () {
      final schedule = dataSource.calculate(
        location: oslo,
        settings: baseSettings,
        now: DateTime(2026, 5, 15, 8, 30),
      );

      expect(schedule.date, DateTime(2026, 5, 15));
      _expectValidPrayerSchedule(schedule);
    });

    test('normalizes schedule date even when now includes time components', () {
      final schedule = dataSource.calculate(
        location: madrid,
        settings: baseSettings,
        now: DateTime(2026, 11, 3, 23, 59, 58, 999),
      );

      expect(schedule.date, DateTime(2026, 11, 3));
      _expectValidPrayerSchedule(schedule);
    });
  });
}

void _expectValidPrayerSchedule(PrayerSchedule schedule) {
  final sunrise = schedule.sunrise;
  expect(schedule.fajr, isA<DateTime>());
  expect(sunrise, isA<DateTime>());
  expect(schedule.dhuhr, isA<DateTime>());
  expect(schedule.asr, isA<DateTime>());
  expect(schedule.maghrib, isA<DateTime>());
  expect(schedule.isha, isA<DateTime>());
  expect(schedule.fajr.isBefore(sunrise!), isTrue);
  expect(sunrise.isBefore(schedule.dhuhr), isTrue);
  expect(schedule.dhuhr.isBefore(schedule.asr), isTrue);
  expect(schedule.asr.isBefore(schedule.maghrib), isTrue);
  expect(schedule.maghrib.isBefore(schedule.isha), isTrue);
}
