import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import 'hadith_service.dart';

/// Servicio para recordatorios de hadices cada hora
class HadithHourlyReminderService {
  final FlutterLocalNotificationsPlugin _plugin;
  final HadithService _hadithService;

  static const String _channelId = 'hadith_hourly_reminders';
  static const String _channelName = 'Recordatorio de Hadiz';
  static const String _channelDesc = 'Recordatorios hourly de hadices';
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
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDesc,
          importance: Importance.defaultImportance,
          playSound: false,
          enableVibration: false,
          showBadge: false,
        ));
  }

  /// Verifica si los recordatorios hourly estÃ¡n habilitados
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

  /// Programa todos los recordatorios hourly
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

  /// Programa un recordatorio para una hora especÃ­fica
  Future<void> _scheduleReminderForHour(int hour) async {
    // Nota: programar notificaciones hourly exactas requiere configuraciÃ³n especial
    // Esta es una implementaciÃ³n simplificada
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, 0);

    // Si ya pasÃ³ hoy, programar para maÃ±ana
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final hadith = await _hadithService.getRandomHadiths(count: 1);
    final hadithText = hadith.isNotEmpty
        ? hadith.first.translation
        : 'Recordatorio: Lee un hadiz del Profeta ï·º';

    // Usar notificaciÃ³n periÃ³dica diaria a la hora especificada
    await _plugin.zonedSchedule(
      20000 + hour,
      'ðŸ“– Hadiz del Momento',
      hadithText.length > 150 ? '${hadithText.substring(0, 147)}...' : hadithText,
      scheduledDate,
      _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: hour.toString(),
    );
  }

  /// Cancela todos los recordatorios
  Future<void> cancelAllReminders() async {
    final startHour = await getStartHour();
    final endHour = await getEndHour();

    for (int hour = startHour; hour <= endHour; hour++) {
      await _plugin.cancel(20000 + hour);
    }
  }

  /// ConfiguraciÃ³n de notificaciÃ³n
  NotificationDetails _notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
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

  /// EnvÃ­a una notificaciÃ³n inmediata (para testing)
  Future<void> sendTestNotification() async {
    final hadith = await _hadithService.getRandomHadiths(count: 1);
    final hadithText = hadith.isNotEmpty ? hadith.first.translation : 'Test de recordatorio de hadiz';

    await _plugin.show(
      20999,
      'ðŸ“– Recordatorio de Hadiz',
      hadithText,
      _notificationDetails(),
    );
  }
}
