import '../entities/prayer_location.dart';
import '../entities/resolved_prayer_schedule.dart';

abstract class PrayerTimesRepository {
  Future<ResolvedPrayerSchedule?> getCurrentSchedule();

  Future<ResolvedPrayerSchedule?> getScheduleForDate(DateTime date);

  Future<PrayerLocation?> getCurrentLocation();

  Future<void> invalidateCacheForLocation(
    PrayerLocation location, {
    double kmThreshold = 50,
  });
}
