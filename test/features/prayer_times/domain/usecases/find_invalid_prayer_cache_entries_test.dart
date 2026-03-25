import 'package:flutter_test/flutter_test.dart';
import 'package:qibla_time/features/prayer_times/domain/entities/cached_prayer_schedule.dart';
import 'package:qibla_time/features/prayer_times/domain/entities/prayer_location.dart';
import 'package:qibla_time/features/prayer_times/domain/entities/prayer_schedule.dart';
import 'package:qibla_time/features/prayer_times/domain/usecases/find_invalid_prayer_cache_entries.dart';

void main() {
  group('FindInvalidPrayerCacheEntriesUseCase', () {
    const useCase = FindInvalidPrayerCacheEntriesUseCase();
    final now = DateTime(2026, 3, 25, 12, 0);

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

    test('invalidates cache entries from another day', () {
      final keys = useCase.call(
        entries: [
          CachedPrayerSchedule(
            key: 'yesterday',
            location: const PrayerLocation(latitude: 48.8566, longitude: 2.3522),
            schedule: buildSchedule(now.subtract(const Duration(days: 1))),
            validUntil: now.add(const Duration(hours: 1)),
          ),
        ],
        currentLocation: const PrayerLocation(latitude: 48.8566, longitude: 2.3522),
        now: now,
      );

      expect(keys, ['yesterday']);
    });

    test('invalidates cache entries that are too far away', () {
      final keys = useCase.call(
        entries: [
          CachedPrayerSchedule(
            key: 'far-away',
            location: const PrayerLocation(latitude: 40.4168, longitude: -3.7038),
            schedule: buildSchedule(now),
            validUntil: now.add(const Duration(hours: 1)),
          ),
        ],
        currentLocation: const PrayerLocation(latitude: 48.8566, longitude: 2.3522),
        now: now,
      );

      expect(keys, ['far-away']);
    });
  });
}
