import '../../../../core/localization/locale_controller.dart';
import '../../../../core/services/settings_service.dart';
import '../../../../l10n/l10n.dart';
import '../../domain/entities/prayer_name.dart';
import '../../domain/entities/prayer_schedule.dart';
import '../../domain/entities/ramadan_status.dart';
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

  static const int _ramadanImsakReminderId = 100;
  static const int _ramadanIftarReminderId = 101;
  static const int _jumuahReminderId = 102;
  static const Duration _imsakReminderLead = Duration(minutes: 15);
  static const Duration _iftarReminderLead = Duration(minutes: 15);
  static const Duration _jumuahReminderLead = Duration(minutes: 45);

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
        prayerName: prayer.key.localizedDisplayName(
          AppLocaleController.effectiveLanguageCode(),
        ),
        scheduledAt: prayer.value,
        adhanFile: adhanFile,
      );
    }

    await _scheduleRamadanReminders(schedule, now: now);
    await _scheduleJumuahReminder(schedule, now: now);
  }

  Future<bool> areNotificationsEnabled() {
    return _settingsService.getNotificationsEnabled();
  }

  Future<void> setNotificationsEnabled(bool value) {
    return _settingsService.saveNotificationsEnabled(value);
  }

  Future<bool> isSystemPermissionGranted() {
    return _notificationService.areNotificationsEnabled();
  }

  Future<void> _scheduleRamadanReminders(
    PrayerSchedule schedule, {
    required DateTime now,
  }) async {
    final l10n = appLocalizationsForCurrentLocale();
    final ramadanStatus = RamadanStatus.fromDate(
      now,
      automaticEnabled: await _settingsService.getRamadanModeAutomatic(),
      forced: await _settingsService.getRamadanModeForced(),
    );

    if (!ramadanStatus.isEnabled) {
      return;
    }

    final imsakReminderAt = schedule.fajr.subtract(_imsakReminderLead);
    if (imsakReminderAt.isAfter(now)) {
      await _notificationService.scheduleReminder(
        id: _ramadanImsakReminderId,
        title: l10n.prayerNotificationImsakTitle,
        body: l10n.prayerNotificationImsakBody,
        scheduledAt: imsakReminderAt,
      );
    }

    final iftarReminderAt = schedule.maghrib.subtract(_iftarReminderLead);
    if (iftarReminderAt.isAfter(now)) {
      await _notificationService.scheduleReminder(
        id: _ramadanIftarReminderId,
        title: l10n.prayerNotificationIftarTitle,
        body: l10n.prayerNotificationIftarBody,
        scheduledAt: iftarReminderAt,
      );
    }
  }

  Future<void> _scheduleJumuahReminder(
    PrayerSchedule schedule, {
    required DateTime now,
  }) async {
    final l10n = appLocalizationsForCurrentLocale();
    if (now.weekday != DateTime.friday) {
      return;
    }

    var reminderTime = schedule.dhuhr.subtract(_jumuahReminderLead);
    if (!reminderTime.isAfter(now)) {
      reminderTime = schedule.dhuhr.subtract(const Duration(minutes: 15));
    }
    if (!reminderTime.isAfter(now)) {
      return;
    }

    await _notificationService.scheduleReminder(
      id: _jumuahReminderId,
      title: l10n.prayerNotificationJumuahTitle,
      body: l10n.prayerNotificationJumuahBody,
      scheduledAt: reminderTime,
    );
  }
}
