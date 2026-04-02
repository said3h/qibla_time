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

    // Programar para cada hora en el rango
    for (int hour = startHour; hour <= endHour; hour++) {
      await _scheduleReminderForHour(hour);
    }
  }

  /// Programa un recordatorio para una hora específica
  Future<void> _scheduleReminderForHour(int hour) async {
    // Nota: programar notificaciones horarias exactas requiere configuración especial
    // Esta es una implementación simplificada
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, 0);

    // Si ya pasó hoy, programar para mañana
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final l10n = appLocalizationsForDevice();
    final hadith = await _hadithService.getRandomHadiths(count: 1);
    final hadithText = hadith.isNotEmpty
        ? hadith.first.translation
        : l10n.notificationHadithReminderFallbackBody;

    await _plugin.zonedSchedule(
      id: 20000 + hour,
      title: l10n.notificationHadithReminderTitle,
      body: hadithText.length > 150
          ? '${hadithText.substring(0, 147)}...'
          : hadithText,
      scheduledDate: scheduledDate,
      notificationDetails: _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: hour.toString(),
    );
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
    final l10n = appLocalizationsForDevice();
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
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: false,
        interruptionLevel: InterruptionLevel.passive,
      ),
    );
  }

  /// Envía una notificación inmediata (para testing)
  Future<void> sendTestNotification() async {
    final l10n = appLocalizationsForDevice();
    final hadith = await _hadithService.getRandomHadiths(count: 1);
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
