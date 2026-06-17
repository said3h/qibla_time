import 'package:adhan/adhan.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qibla_time/features/prayer_times/domain/entities/prayer_location.dart';
import 'package:qibla_time/features/prayer_times/domain/entities/prayer_schedule.dart';
import 'package:qibla_time/features/prayer_times/domain/entities/prayer_settings.dart';
import 'package:qibla_time/features/prayer_times/domain/entities/resolved_prayer_schedule.dart';
import 'package:qibla_time/features/prayer_times/screens/home_screen.dart';

void main() {
  group('shouldRefreshPrayerTimesIfStale', () {
    test('refreshes when no schedule is loaded', () {
      expect(
        shouldRefreshPrayerTimesIfStale(
          resolvedSchedule: null,
          now: DateTime(2026, 6, 18, 9),
          lastRefreshAt: null,
        ),
        isTrue,
      );
    });

    test('refreshes when the loaded schedule is from another day', () {
      expect(
        shouldRefreshPrayerTimesIfStale(
          resolvedSchedule: _resolvedSchedule(DateTime(2026, 6, 17)),
          now: DateTime(2026, 6, 18, 9),
          lastRefreshAt: DateTime(2026, 6, 18, 8),
        ),
        isTrue,
      );
    });

    test('refreshes after the stale threshold passes', () {
      expect(
        shouldRefreshPrayerTimesIfStale(
          resolvedSchedule: _resolvedSchedule(DateTime(2026, 6, 18)),
          now: DateTime(2026, 6, 18, 13),
          lastRefreshAt: DateTime(2026, 6, 18, 8, 59),
        ),
        isTrue,
      );
    });

    test('keeps a same-day recent schedule', () {
      expect(
        shouldRefreshPrayerTimesIfStale(
          resolvedSchedule: _resolvedSchedule(DateTime(2026, 6, 18)),
          now: DateTime(2026, 6, 18, 11),
          lastRefreshAt: DateTime(2026, 6, 18, 9),
        ),
        isFalse,
      );
    });
  });
}

ResolvedPrayerSchedule _resolvedSchedule(DateTime date) {
  final day = DateTime(date.year, date.month, date.day);
  return ResolvedPrayerSchedule(
    location: const PrayerLocation(latitude: 40.4168, longitude: -3.7038),
    settings: const PrayerSettings(
      method: CalculationMethod.muslim_world_league,
      madhab: Madhab.shafi,
      timeOffsetMinutes: 0,
      fajrAngle: 18,
      ishaAngle: 17,
      methodName: 'Muslim World League',
    ),
    schedule: PrayerSchedule(
      date: day,
      fajr: day.add(const Duration(hours: 5)),
      sunrise: day.add(const Duration(hours: 6, minutes: 30)),
      dhuhr: day.add(const Duration(hours: 13)),
      asr: day.add(const Duration(hours: 17)),
      maghrib: day.add(const Duration(hours: 21)),
      isha: day.add(const Duration(hours: 22, minutes: 30)),
    ),
    fromCache: true,
  );
}
