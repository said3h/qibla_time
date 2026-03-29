import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  FlutterLocalNotificationsPlugin get plugin => _plugin;

  Future<void> initialize() async {
    tz.initializeTimeZones();

    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        ),
      ),
    );
  }

  Future<void> scheduleAdhan({
    required int id,
    required String prayerName,
    required DateTime scheduledAt,
    required String adhanFile,
  }) async {
    final androidSound = 'adhan_${adhanFile.replaceAll('.mp3', '')}';

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'adhan_channel',
        'Adhan',
        channelDescription: 'Notificaciones de horario de oraciÃ³n',
        importance: Importance.max,
        priority: Priority.high,
        sound: UriAndroidNotificationSound(androidSound),
        playSound: true,
        enableVibration: true,
      ),
      iOS: DarwinNotificationDetails(
        sound: adhanFile,
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _plugin.zonedSchedule(
      id,
      'Qibla Time - $prayerName',
      'Es la hora de la oraciÃ³n',
      tz.TZDateTime.from(scheduledAt, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
  }) async {
    final details = NotificationDetails(
      android: const AndroidNotificationDetails(
        'qiblatime_reminders',
        'Qibla Time - Recordatorios',
        channelDescription: 'Recordatorios contextuales de RamadÃ¡n y Yumu\'ah',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledAt, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> showInstant({
    required String title,
    required String body,
    String adhanFile = 'azan1.mp3',
  }) async {
    final androidSound = 'adhan_${adhanFile.replaceAll('.mp3', '')}';

    await _plugin.show(
      99,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'adhan_channel',
          'Adhan',
          importance: Importance.max,
          priority: Priority.high,
          sound: UriAndroidNotificationSound(androidSound),
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(
          sound: adhanFile,
          presentAlert: true,
          presentSound: true,
        ),
      ),
    );
  }

  Future<void> cancel(int id) async => _plugin.cancel(id);

  Future<void> cancelAll() async => _plugin.cancelAll();

  Future<bool> requestPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }

    final ios = _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return await ios.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }

    return false;
  }

  Future<bool> areNotificationsEnabled() async {
    final status = await Permission.notification.status;
    return status.isGranted || status.isLimited || status.isProvisional;
  }
}
