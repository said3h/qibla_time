import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../l10n/l10n.dart';
import '../../hadith/services/hadith_service.dart';
import 'notification_service.dart';
import '../services/quran_service.dart';

/// Servicio para notificaciones diarias inspiracionales (Corán + Hadiz)
class DailyInspirationNotificationService {
  final FlutterLocalNotificationsPlugin _plugin;
  final HadithService _hadithService;

  static const String _channelId = 'daily_inspiration';
  static const String _prefsKey = 'daily_inspiration_enabled';
  static const String _prefsHourKey = 'daily_inspiration_hour';

  DailyInspirationNotificationService({
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
          l10n.notificationDailyReflectionChannelName,
          description: l10n.notificationDailyReflectionChannelDescription,
          importance: Importance.defaultImportance,
          playSound: false,
          enableVibration: false,
          showBadge: false,
        ));
  }

  /// Verifica si las notificaciones diarias están habilitadas
  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefsKey) ?? false;
  }

  /// Habilita o deshabilita las notificaciones diarias
  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, enabled);

    if (enabled) {
      await scheduleDailyNotification();
    } else {
      await cancelDailyNotification();
    }
  }

  /// Obtiene la hora configurada para la notificación
  Future<int> getNotificationHour() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_prefsHourKey) ?? 8; // Default: 8 AM
  }

  /// Configura la hora para la notificación
  Future<void> setNotificationHour(int hour) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsHourKey, hour);
    await scheduleDailyNotification();
  }

  /// Programa la notificación diaria
  Future<void> scheduleDailyNotification() async {
    if (!await isEnabled()) return;

    final hour = await getNotificationHour();
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      0,
    );

    // Si ya pasó la hora hoy, programar para mañana
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final content = await _generateNotificationContent();

    // Same guard as NotificationService.scheduleAdhan: use
    // canScheduleExactNotifications() which covers both SCHEDULE_EXACT_ALARM
    // (user-granted, Android 12+) and USE_EXACT_ALARM (auto-granted, Android 13+).
    // Falling back to inexactAllowWhileIdle avoids SecurityException on Android 12
    // devices that have not granted exact-alarm permission.
    final scheduleMode = await _resolveScheduleMode();

    try {
      await _plugin.zonedSchedule(
        id: 10001,
        title: content.title,
        body: content.body,
        scheduledDate: scheduledDate,
        notificationDetails: _notificationDetails(),
        androidScheduleMode: scheduleMode,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      // If scheduling fails (e.g. permission revoked between check and call),
      // retry once with inexact mode before giving up.
      await _plugin.zonedSchedule(
        id: 10001,
        title: content.title,
        body: content.body,
        scheduledDate: scheduledDate,
        notificationDetails: _notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
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

  /// Cancela la notificación diaria
  Future<void> cancelDailyNotification() async {
    await _plugin.cancel(id: 10001);
  }

  /// Genera el contenido de la notificación
  Future<NotificationContent> _generateNotificationContent() async {
    final language = currentLanguageCode();
    final l10n = appLocalizationsForLocaleCode(language);
    try {
      final hadith = await _hadithService.getHadithOfDay(
        forcedLanguage: language,
      );
      final quranVerse = await QuranVerseService.getDailyVerse(language);
      final title = l10n.notificationDailyReflectionTitle;
      final now = DateTime.now();
      final useHadith = now.day % 2 == 0;

      String body;
      if (useHadith && hadith != null) {
        final translation = hadith.translation;
        body = translation.length > 150
            ? '${translation.substring(0, 147)}...'
            : translation;
        body += ' — ${hadith.reference}';
      } else {
        final translation = quranVerse.translationText;
        body = translation.length > 150
            ? '${translation.substring(0, 147)}...'
            : translation;
        body += ' — ${quranVerse.reference}';
      }

      return NotificationContent(
        title: title,
        body: body,
        isHadith: useHadith,
      );
    } catch (_) {
      return NotificationContent(
        title: l10n.notificationDailyReflectionErrorTitle,
        body: l10n.notificationDailyReflectionErrorBody,
        isHadith: true,
      );
    }
  }

  /// Configuración de notificación
  NotificationDetails _notificationDetails() {
    final l10n = appLocalizationsForCurrentLocale();
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        l10n.notificationDailyReflectionChannelName,
        channelDescription: l10n.notificationDailyReflectionChannelDescription,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        playSound: false,
        enableVibration: false,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: false,
        interruptionLevel: InterruptionLevel.passive,
      ),
    );
  }

  /// Envía una notificación inmediata (para testing)
  Future<void> sendTestNotification() async {
    final content = await _generateNotificationContent();

    await _plugin.show(
      id: 10002,
      title: content.title,
      body: content.body,
      notificationDetails: _notificationDetails(),
    );
  }
}

/// Contenido de notificación
class NotificationContent {
  const NotificationContent({
    required this.title,
    required this.body,
    required this.isHadith,
  });

  final String title;
  final String body;
  final bool isHadith;
}

// ── Providers ──────────────────────────────────────────────────

final dailyInspirationNotificationServiceProvider =
    Provider<DailyInspirationNotificationService>((ref) {
  return DailyInspirationNotificationService(
    plugin: NotificationService.instance.plugin,
    hadithService: ref.read(hadithServiceProvider),
  );
});

/// Provider que indica si las notificaciones diarias están habilitadas
final dailyInspirationEnabledProvider = FutureProvider<bool>((ref) async {
  return ref.read(dailyInspirationNotificationServiceProvider).isEnabled();
});
