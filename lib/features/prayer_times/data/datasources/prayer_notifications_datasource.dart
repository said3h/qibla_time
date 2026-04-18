import '../../../../core/localization/locale_controller.dart';
import '../../../../core/services/logger_service.dart';
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

  // IDs 0-4: oraciones de hoy
  static const Map<PrayerName, int> _prayerIds = {
    PrayerName.fajr: 0,
    PrayerName.dhuhr: 1,
    PrayerName.asr: 2,
    PrayerName.maghrib: 3,
    PrayerName.isha: 4,
  };

  // IDs 5-9: oraciones de mañana — garantizan adhan aunque el usuario no abra
  // la app antes del primer salah del día siguiente.
  static const Map<PrayerName, int> _tomorrowPrayerIds = {
    PrayerName.fajr: 5,
    PrayerName.dhuhr: 6,
    PrayerName.asr: 7,
    PrayerName.maghrib: 8,
    PrayerName.isha: 9,
  };

  static const int _ramadanImsakReminderId = 100;
  static const int _ramadanIftarReminderId = 101;
  static const int _jumuahReminderId = 102;
  static const Duration _imsakReminderLead = Duration(minutes: 15);
  static const Duration _iftarReminderLead = Duration(minutes: 15);
  static const Duration _jumuahReminderLead = Duration(minutes: 45);

  Future<void> rescheduleToday(PrayerSchedule schedule) async {
    AppLogger.info('PrayerNotificationsDataSource.rescheduleToday: start');

    // Cancelamos solo los IDs de oración para no tocar las notificaciones de
    // inspiración diaria (10001) ni de hadiths horarios (20000+).
    await _notificationService.cancelPrayerNotifications();

    final notificationsEnabled = await _settingsService.getNotificationsEnabled();
    AppLogger.info(
      'rescheduleToday: globalNotificationsEnabled=$notificationsEnabled',
    );
    if (!notificationsEnabled) {
      return;
    }

    final adhanFile = await _settingsService.getAdhan();
    AppLogger.info('rescheduleToday: adhanFile=$adhanFile');
    final now = DateTime.now();
    int scheduled = 0;

    for (final prayer in schedule.times.entries) {
      if (prayer.value.isBefore(now)) {
        AppLogger.info(
          'rescheduleToday: SKIP ${prayer.key.key} (past: ${prayer.value})',
        );
        continue;
      }

      final enabled = await _settingsService.getPrayerNotificationEnabled(
        prayer.key.key,
      );
      AppLogger.info(
        'rescheduleToday: ${prayer.key.key} enabled=$enabled at=${prayer.value}',
      );
      if (!enabled) {
        continue;
      }

      // Try-catch por iteración: si una oración falla (p. ej. permiso de alarma
      // exacta revocado), las demás se siguen programando.
      try {
        await _notificationService.scheduleAdhan(
          id: _prayerIds[prayer.key]!,
          prayerName: prayer.key.localizedDisplayName(
            AppLocaleController.effectiveLanguageCode(),
          ),
          scheduledAt: prayer.value,
          adhanFile: adhanFile,
        );
        scheduled++;
      } catch (e, stackTrace) {
        AppLogger.error(
          'rescheduleToday: FAILED ${prayer.key.key}',
          error: e,
          stackTrace: stackTrace,
        );
      }
    }

    AppLogger.info(
      'rescheduleToday: done. $scheduled prayers scheduled.',
    );

    await _scheduleRamadanReminders(schedule, now: now);
    await _scheduleJumuahReminder(schedule, now: now);
  }

  /// Programa todas las oraciones del día siguiente con IDs 5-9.
  /// Se llama justo después de [rescheduleToday] para garantizar que el adhan
  /// suene aunque el usuario no abra la app antes del primer salah de mañana.
  Future<void> scheduleTomorrow(PrayerSchedule tomorrowSchedule) async {
    if (!await _settingsService.getNotificationsEnabled()) {
      return;
    }

    final adhanFile = await _settingsService.getAdhan();
    final now = DateTime.now();

    for (final prayer in tomorrowSchedule.times.entries) {
      // Salvaguarda: no programar si por alguna razón el tiempo ya pasó
      if (!prayer.value.isAfter(now)) {
        continue;
      }

      final enabled = await _settingsService.getPrayerNotificationEnabled(
        prayer.key.key,
      );
      if (!enabled) {
        continue;
      }

      try {
        await _notificationService.scheduleAdhan(
          id: _tomorrowPrayerIds[prayer.key]!,
          prayerName: prayer.key.localizedDisplayName(
            AppLocaleController.effectiveLanguageCode(),
          ),
          scheduledAt: prayer.value,
          adhanFile: adhanFile,
        );
      } catch (e, stackTrace) {
        AppLogger.error(
          'Failed to schedule tomorrow adhan for ${prayer.key.key}',
          error: e,
          stackTrace: stackTrace,
        );
      }
    }
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
