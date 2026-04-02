import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../../l10n/l10n.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();
  static const _androidAdhanChannelPrefix = 'adhan_channel_v2_';

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
    final l10n = appLocalizationsForDevice();
    final androidSound = _androidSoundNameFor(adhanFile);
    final androidChannelId = _androidChannelIdFor(adhanFile);

    await _ensureAndroidAdhanChannel(
      channelId: androidChannelId,
      soundName: androidSound,
      l10n: l10n,
    );

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        androidChannelId,
        l10n.notificationAdhanChannelName,
        channelDescription: l10n.notificationAdhanChannelDescription,
        importance: Importance.max,
        priority: Priority.high,
        sound: RawResourceAndroidNotificationSound(androidSound),
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
      l10n.notificationAdhanTitle(prayerName),
      l10n.notificationAdhanBody,
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
    final l10n = appLocalizationsForDevice();
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'qiblatime_reminders',
        l10n.notificationReminderChannelName,
        channelDescription: l10n.notificationReminderChannelDescription,
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
    final l10n = appLocalizationsForDevice();
    final androidSound = _androidSoundNameFor(adhanFile);
    final androidChannelId = _androidChannelIdFor(adhanFile);

    await _ensureAndroidAdhanChannel(
      channelId: androidChannelId,
      soundName: androidSound,
      l10n: l10n,
    );

    await _plugin.show(
      99,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          androidChannelId,
          l10n.notificationAdhanChannelName,
          importance: Importance.max,
          priority: Priority.high,
          sound: RawResourceAndroidNotificationSound(androidSound),
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

  String _androidSoundNameFor(String adhanFile) {
    return 'adhan_${adhanFile.replaceAll('.mp3', '')}';
  }

  String _androidChannelIdFor(String adhanFile) {
    return '$_androidAdhanChannelPrefix${_androidSoundNameFor(adhanFile)}';
  }

  Future<void> _ensureAndroidAdhanChannel({
    required String channelId,
    required String soundName,
    required AppLocalizations l10n,
  }) async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) {
      return;
    }

    // Android 8+ fija el sonido al crear el canal. Usamos un canal por adhan
    // para evitar que un canal previo contaminado siga reproduciendo el sonido
    // por defecto o un adhan antiguo.
    await android.createNotificationChannel(
      AndroidNotificationChannel(
        channelId,
        l10n.notificationAdhanChannelName,
        description: l10n.notificationAdhanChannelDescription,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        sound: RawResourceAndroidNotificationSound(soundName),
      ),
    );
  }

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
