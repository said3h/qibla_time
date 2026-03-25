import '../entities/cached_prayer_schedule.dart';
import '../entities/prayer_location.dart';

class FindInvalidPrayerCacheEntriesUseCase {
  const FindInvalidPrayerCacheEntriesUseCase();

  List<String> call({
    required List<CachedPrayerSchedule> entries,
    required PrayerLocation currentLocation,
    required DateTime now,
    double kmThreshold = 50,
  }) {
    final invalidKeys = <String>[];

    for (final entry in entries) {
      final sameDay =
          entry.schedule.date.year == now.year &&
          entry.schedule.date.month == now.month &&
          entry.schedule.date.day == now.day;
      final distanceKm = _distanceKm(
        currentLocation.latitude,
        currentLocation.longitude,
        entry.location.latitude,
        entry.location.longitude,
      );

      if (!sameDay || entry.validUntil.isBefore(now) || distanceKm > kmThreshold) {
        invalidKeys.add(entry.key);
      }
    }

    return invalidKeys;
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
