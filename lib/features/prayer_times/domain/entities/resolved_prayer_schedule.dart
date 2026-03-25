import 'prayer_location.dart';
import 'prayer_schedule.dart';
import 'prayer_settings.dart';

class ResolvedPrayerSchedule {
  const ResolvedPrayerSchedule({
    required this.location,
    required this.settings,
    required this.schedule,
    required this.fromCache,
  });

  final PrayerLocation location;
  final PrayerSettings settings;
  final PrayerSchedule schedule;
  final bool fromCache;
}
