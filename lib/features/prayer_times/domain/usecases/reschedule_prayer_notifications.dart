import '../entities/prayer_schedule.dart';
import '../repositories/prayer_notifications_repository.dart';

class ReschedulePrayerNotificationsUseCase {
  const ReschedulePrayerNotificationsUseCase(this._repository);

  final PrayerNotificationsRepository _repository;

  Future<void> call(PrayerSchedule schedule) {
    return _repository.rescheduleToday(schedule);
  }
}
