// lib/features/prayer_times/services/notification_service.dart
//
// REGLA DE NOMBRES POR PLATAFORMA:
//
//   Flutter assets:  'azan1.mp3'          → assets/audio/azan1.mp3
//   iOS bundle:      'azan1.mp3'          → ios/Runner/azan1.mp3
//   Android raw:     'adhan_azan1'        → res/raw/adhan_azan1.mp3
//
// Android no acepta recursos en res/raw/ que empiecen por número,
// por eso añadimos el prefijo 'adhan_' al convertir el nombre.

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // ── Inicialización ────────────────────────────────────────────

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

  // ── Programar Adhan ───────────────────────────────────────────

  /// [adhanFile] viene de AdhanModel.file — ej: 'azan1.mp3'
  Future<void> scheduleAdhan({
    required int id,
    required String prayerName,
    required DateTime scheduledAt,
    required String adhanFile,
  }) async {
    // Android res/raw: sin extensión y con prefijo para evitar nombre numérico
    // 'azan1.mp3' → 'adhan_azan1'
    final androidSound = 'adhan_${adhanFile.replaceAll('.mp3', '')}';

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'adhan_channel',
        'Adhan',
        channelDescription: 'Notificaciones de tiempo de oración',
        importance: Importance.max,
        priority: Priority.high,
        sound: UriAndroidNotificationSound(androidSound),
        playSound: true,
        enableVibration: true,
      ),
      iOS: DarwinNotificationDetails(
        sound: adhanFile,          // iOS acepta 'azan1.mp3' directamente
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _plugin.zonedSchedule(
      id,
      'QiblaTime — $prayerName',
      'Es la hora de la oración',
      tz.TZDateTime.from(scheduledAt, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Notificación inmediata (modo viajero, debug)
  Future<void> showInstant({
    required String title,
    required String body,
    String adhanFile = 'azan1.mp3',
  }) async {
    final androidSound = 'adhan_${adhanFile.replaceAll('.mp3', '')}';

    await _plugin.show(
      99, title, body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'adhan_channel', 'Adhan',
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
  Future<void> cancelAll()    async => _plugin.cancelAll();

  Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return await ios.requestPermissions(
            alert: true, badge: true, sound: true) ?? false;
    }
    return false;
  }
}
