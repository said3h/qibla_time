import 'prayer_location.dart';
import 'prayer_schedule.dart';

class CachedPrayerSchedule {
  const CachedPrayerSchedule({
    required this.key,
    required this.location,
    required this.schedule,
    required this.validUntil,
  });

  final String key;
  final PrayerLocation location;
  final PrayerSchedule schedule;
  final DateTime validUntil;
}
