import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../l10n/l10n.dart';
import 'hadith_service.dart';
import '../../prayer_times/services/notification_service.dart';

/// Servicio para recordatorios de hadices cada hora
class HadithHourlyReminderService {
  final FlutterLocalNotificationsPlugin _plugin;
  final HadithService _hadithService;

  static const String _channelId = 'hadith_hourly_reminders';
  static const String _prefsKey = 'hadith_hourly_enabled';
  static const String _prefsStartHour = 'hadith_hourly_start';
  static const String _prefsEndHour = 'hadith_hourly_end';

  HadithHourlyReminderService({
    required FlutterLocalNotificationsPlugin plugin,
    required HadithService hadithService,
  })  : _plugin = plugin,
        _hadithService = hadithService;

  /// Inicializa el canal de notificaciones
  Future<void> initializeChannel() async {
    final l10n = appLocalizationsForDevice();
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(AndroidNotificationChannel(
          _channelId,
          l10n.notificationHadithReminderChannelName,
          description: l10n.notificationHadithReminderChannelDescription,
          importance: Importance.defaultImportance,
          playSound: false,
          enableVibration: false,
          showBadge: false,
        ));
  }

  /// Verifica si los recordatorios horarios están habilitados
  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefsKey) ?? false;
  }

  /// Habilita o deshabilita los recordatorios
  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, enabled);

    if (enabled) {
      await scheduleAllReminders();
    } else {
      await cancelAllReminders();
    }
  }

  /// Obtiene la hora de inicio
  Future<int> getStartHour() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_prefsStartHour) ?? 9; // 9 AM
  }

  /// Obtiene la hora de fin
  Future<int> getEndHour() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_prefsEndHour) ?? 21; // 9 PM
  }

  /// Configura el rango de horas
  Future<void> setHourRange(int start, int end) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsStartHour, start);
    await prefs.setInt(_prefsEndHour, end);
    await scheduleAllReminders();
  }

  /// Programa todos los recordatorios horarios
  Future<void> scheduleAllReminders() async {
    if (!await isEnabled()) return;

    final startHour = await getStartHour();
    final endHour = await getEndHour();

    // Cancelar primero todos los existentes
    await cancelAllReminders();

    // Resolve once for the whole batch to avoid repeated IPC calls.
    final scheduleMode = await _resolveScheduleMode();

    // Programar para cada hora en el rango
    for (int hour = startHour; hour <= endHour; hour++) {
      await _scheduleReminderForHour(hour, scheduleMode);
    }
  }

  /// Programa un recordatorio para una hora específica
  Future<void> _scheduleReminderForHour(
    int hour,
    AndroidScheduleMode scheduleMode,
  ) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, 0);

    // Si ya pasó hoy, programar para mañana
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final language = currentLanguageCode();
    final l10n = appLocalizationsForLocaleCode(language);
    final hadith = await _hadithService.getRandomHadiths(
      count: 1,
      forcedLanguage: language,
    );
    final hadithText = hadith.isNotEmpty
        ? hadith.first.translation
        : l10n.notificationHadithReminderFallbackBody;

    // Same guard as NotificationService.scheduleAdhan: use
    // canScheduleExactNotifications() which covers both SCHEDULE_EXACT_ALARM
    // (user-granted, Android 12+) and USE_EXACT_ALARM (auto-granted, Android 13+).
    try {
      await _plugin.zonedSchedule(
        id: 20000 + hour,
        title: l10n.notificationHadithReminderTitle,
        body: hadithText.length > 150
            ? '${hadithText.substring(0, 147)}...'
            : hadithText,
        scheduledDate: scheduledDate,
        notificationDetails: _notificationDetails(),
        androidScheduleMode: scheduleMode,
        payload: hour.toString(),
      );
    } catch (e) {
      // If scheduling fails (e.g. permission revoked between check and call),
      // retry once with inexact mode before giving up.
      await _plugin.zonedSchedule(
        id: 20000 + hour,
        title: l10n.notificationHadithReminderTitle,
        body: hadithText.length > 150
            ? '${hadithText.substring(0, 147)}...'
            : hadithText,
        scheduledDate: scheduledDate,
        notificationDetails: _notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: hour.toString(),
      );
    }
  }

  /// Returns the appropriate [AndroidScheduleMode] for the current device.
  ///
  /// Mirrors the logic in [NotificationService._canScheduleExactAlarm]:
  /// uses [canScheduleExactNotifications] (→ AlarmManager.canScheduleExactAlarms)
  /// instead of permission_handler, which only checks SCHEDULE_EXACT_ALARM and
  /// misses the USE_EXACT_ALARM auto-grant path available on Android 13+.
  Future<AndroidScheduleMode> _resolveScheduleMode() async {
    if (!Platform.isAndroid) return AndroidScheduleMode.exactAllowWhileIdle;
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final canExact = await android?.canScheduleExactNotifications() ?? false;
    return canExact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
  }

  /// Cancela todos los recordatorios
  Future<void> cancelAllReminders() async {
    final startHour = await getStartHour();
    final endHour = await getEndHour();

    for (int hour = startHour; hour <= endHour; hour++) {
      await _plugin.cancel(id: 20000 + hour);
    }
  }

  /// Configuración de notificación
  NotificationDetails _notificationDetails() {
    final l10n = appLocalizationsForCurrentLocale();
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        l10n.notificationHadithReminderChannelName,
        channelDescription: l10n.notificationHadithReminderChannelDescription,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        playSound: false,
        enableVibration: false,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: false,
        interruptionLevel: InterruptionLevel.passive,
      ),
    );
  }

  /// Envía una notificación inmediata (para testing)
  Future<void> sendTestNotification() async {
    final language = currentLanguageCode();
    final l10n = appLocalizationsForLocaleCode(language);
    final hadith = await _hadithService.getRandomHadiths(
      count: 1,
      forcedLanguage: language,
    );
    final hadithText = hadith.isNotEmpty
        ? hadith.first.translation
        : l10n.notificationHadithReminderTestBody;

    await _plugin.show(
      id: 20999,
      title: l10n.notificationHadithReminderTestTitle,
      body: hadithText,
      notificationDetails: _notificationDetails(),
    );
  }
}

final hadithHourlyReminderServiceProvider =
    Provider<HadithHourlyReminderService>((ref) {
  return HadithHourlyReminderService(
    plugin: NotificationService.instance.plugin,
    hadithService: ref.read(hadithServiceProvider),
  );
});
