import '../entities/cached_prayer_schedule.dart';
import '../entities/prayer_location.dart';

enum PrayerScheduleSource {
  cache,
  calculation,
}

class SelectPrayerScheduleSourceUseCase {
  const SelectPrayerScheduleSourceUseCase();

  PrayerScheduleSource call({
    required CachedPrayerSchedule? cachedSchedule,
    required PrayerLocation currentLocation,
    required DateTime now,
    double kmThreshold = 50,
  }) {
    if (cachedSchedule == null) {
      return PrayerScheduleSource.calculation;
    }

    final sameDay =
        cachedSchedule.schedule.date.year == now.year &&
        cachedSchedule.schedule.date.month == now.month &&
        cachedSchedule.schedule.date.day == now.day;

    if (!sameDay || cachedSchedule.validUntil.isBefore(now)) {
      return PrayerScheduleSource.calculation;
    }

    final distanceKm = _distanceKm(
      currentLocation.latitude,
      currentLocation.longitude,
      cachedSchedule.location.latitude,
      cachedSchedule.location.longitude,
    );

    if (distanceKm > kmThreshold) {
      return PrayerScheduleSource.calculation;
    }

    return PrayerScheduleSource.cache;
  }

  double _distanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final latDistance = (lat1 - lat2).abs();
    final lonDistance = (lon1 - lon2).abs();
    return (latDistance * 111.0) + (lonDistance * 111.0);
  }
}
