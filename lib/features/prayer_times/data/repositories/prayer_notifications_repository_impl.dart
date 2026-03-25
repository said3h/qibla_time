import '../../domain/entities/prayer_schedule.dart';
import '../../domain/repositories/prayer_notifications_repository.dart';
import '../datasources/prayer_notifications_datasource.dart';

class PrayerNotificationsRepositoryImpl
    implements PrayerNotificationsRepository {
  PrayerNotificationsRepositoryImpl(this._dataSource);

  final PrayerNotificationsDataSource _dataSource;

  @override
  Future<void> rescheduleToday(PrayerSchedule schedule) {
    return _dataSource.rescheduleToday(schedule);
  }
}
