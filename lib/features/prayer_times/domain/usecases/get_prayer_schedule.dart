import '../entities/resolved_prayer_schedule.dart';
import '../repositories/prayer_times_repository.dart';

class GetPrayerScheduleUseCase {
  const GetPrayerScheduleUseCase(this._repository);

  final PrayerTimesRepository _repository;

  Future<ResolvedPrayerSchedule?> call() {
    return _repository.getCurrentSchedule();
  }
}
