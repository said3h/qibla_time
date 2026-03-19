import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../../core/services/settings_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static final SettingsService _settingsService = SettingsService();

  static Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(settings);
  }

  /// Programa una notificación de Adhan con el sonido seleccionado por el usuario
  static Future<void> scheduleAdhan(
    int id,
    String title,
    DateTime scheduledTime,
  ) async {
    // Obtener el adhan seleccionado por el usuario
    final selectedAdhan = await _settingsService.getAdhan();
    
    // Para Android: quitar extensión .mp3 para RawResourceAndroidNotificationSound
    final androidSoundName = selectedAdhan.replaceAll('.mp3', '').toLowerCase();
    
    // Para iOS: usar extensión .caf (o .mp3 si está en el bundle)
    final iosSoundName = selectedAdhan.replaceAll('.mp3', '');

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      'It is time for prayer',
      tz.TZDateTime.from(scheduledTime, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'adhan_channel',
          'Adhan Notifications',
          channelDescription: 'Notifications for prayer times',
          importance: Importance.max,
          priority: Priority.high,
          sound: RawResourceAndroidNotificationSound(androidSoundName),
          fullScreenIntent: true,
        ),
        iOS: DarwinNotificationDetails(
          sound: iosSoundName,
          presentSound: true,
          presentAlert: true,
          presentBadge: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Programa una notificación con sonido por defecto del sistema
  static Future<void> scheduleAdhanWithDefaultSound(
    int id,
    String title,
    DateTime scheduledTime,
  ) async {
    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      'It is time for prayer',
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'adhan_channel',
          'Adhan Notifications',
          channelDescription: 'Notifications for prayer times',
          importance: Importance.max,
          priority: Priority.high,
          // Usar sonido por defecto del sistema
          sound: null,
        ),
        iOS: DarwinNotificationDetails(
          sound: 'default',
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }

  static Future<void> cancel(int id) async {
    await _notificationsPlugin.cancel(id);
  }
}
