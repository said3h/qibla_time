import '../entities/prayer_schedule.dart';

abstract class PrayerNotificationsRepository {
  Future<void> rescheduleToday(PrayerSchedule schedule);
}
