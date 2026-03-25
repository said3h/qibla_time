import 'package:flutter_test/flutter_test.dart';
import 'package:qibla_time/features/prayer_times/domain/entities/cached_prayer_schedule.dart';
import 'package:qibla_time/features/prayer_times/domain/entities/prayer_location.dart';
import 'package:qibla_time/features/prayer_times/domain/entities/prayer_schedule.dart';
import 'package:qibla_time/features/prayer_times/domain/usecases/select_prayer_schedule_source.dart';

void main() {
  group('SelectPrayerScheduleSourceUseCase', () {
    const useCase = SelectPrayerScheduleSourceUseCase();
    final now = DateTime(2026, 3, 25, 12, 0);
    const currentLocation = PrayerLocation(latitude: 48.8566, longitude: 2.3522);

    PrayerSchedule buildSchedule(DateTime date) {
      return PrayerSchedule(
        date: DateTime(date.year, date.month, date.day),
        fajr: DateTime(date.year, date.month, date.day, 5, 10),
        dhuhr: DateTime(date.year, date.month, date.day, 13, 20),
        asr: DateTime(date.year, date.month, date.day, 17, 0),
        maghrib: DateTime(date.year, date.month, date.day, 19, 40),
        isha: DateTime(date.year, date.month, date.day, 21, 5),
      );
    }

    test('uses cache when same day, still valid and near location', () {
      final cached = CachedPrayerSchedule(
        key: 'cache',
        location: currentLocation,
        schedule: buildSchedule(now),
        validUntil: now.add(const Duration(hours: 10)),
      );

      final source = useCase.call(
        cachedSchedule: cached,
        currentLocation: currentLocation,
        now: now,
      );

      expect(source, PrayerScheduleSource.cache);
    });

    test('falls back to calculation when cache is expired', () {
      final cached = CachedPrayerSchedule(
        key: 'cache',
        location: currentLocation,
        schedule: buildSchedule(now),
        validUntil: now.subtract(const Duration(minutes: 1)),
      );

      final source = useCase.call(
        cachedSchedule: cached,
        currentLocation: currentLocation,
        now: now,
      );

      expect(source, PrayerScheduleSource.calculation);
    });

    test('falls back to calculation when cache is too far away', () {
      final cached = CachedPrayerSchedule(
        key: 'cache',
        location: const PrayerLocation(latitude: 40.4168, longitude: -3.7038),
        schedule: buildSchedule(now),
        validUntil: now.add(const Duration(hours: 10)),
      );

      final source = useCase.call(
        cachedSchedule: cached,
        currentLocation: currentLocation,
        now: now,
      );

      expect(source, PrayerScheduleSource.calculation);
    });
  });
}
