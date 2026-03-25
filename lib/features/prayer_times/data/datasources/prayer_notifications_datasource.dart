import '../../../../core/services/settings_service.dart';
import '../../domain/entities/prayer_name.dart';
import '../../domain/entities/prayer_schedule.dart';
import '../../services/notification_service.dart';

class PrayerNotificationsDataSource {
  PrayerNotificationsDataSource({
    SettingsService? settingsService,
    NotificationService? notificationService,
  })  : _settingsService = settingsService ?? SettingsService.instance,
        _notificationService = notificationService ?? NotificationService.instance;

  final SettingsService _settingsService;
  final NotificationService _notificationService;

  static const Map<PrayerName, int> _prayerIds = {
    PrayerName.fajr: 0,
    PrayerName.dhuhr: 1,
    PrayerName.asr: 2,
    PrayerName.maghrib: 3,
    PrayerName.isha: 4,
  };

  Future<void> rescheduleToday(PrayerSchedule schedule) async {
    await _notificationService.cancelAll();

    if (!await _settingsService.getNotificationsEnabled()) {
      return;
    }

    final adhanFile = await _settingsService.getAdhan();
    final now = DateTime.now();

    for (final prayer in schedule.times.entries) {
      if (prayer.value.isBefore(now)) {
        continue;
      }

      final enabled = await _settingsService.getPrayerNotificationEnabled(
        prayer.key.key,
      );
      if (!enabled) {
        continue;
      }

      await _notificationService.scheduleAdhan(
        id: _prayerIds[prayer.key]!,
        prayerName: prayer.key.displayName,
        scheduledAt: prayer.value,
        adhanFile: adhanFile,
      );
    }
  }
}
