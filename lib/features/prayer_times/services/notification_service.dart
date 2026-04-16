import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../../core/services/logger_service.dart';
import '../../../l10n/l10n.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();
  static const _androidAdhanChannelPrefix = 'adhan_channel_v4_';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  FlutterLocalNotificationsPlugin get plugin => _plugin;

  Future<void> initialize() async {
    try {
      tz.initializeTimeZones();

      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          ),
        ),
        onDidReceiveNotificationResponse: (_) {},
      );
      await _deleteOldAdhanChannels();
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to initialize notifications',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> scheduleAdhan({
    required int id,
    required String prayerName,
    required DateTime scheduledAt,
    required String adhanFile,
  }) async {
    try {
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
          sound: adhanFile.replaceAll('.mp3', '.caf'),
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      final tzDate = tz.TZDateTime.from(scheduledAt, tz.local);
      final exactAlarmPermission = await Permission.scheduleExactAlarm.status;
      final canUseExactAlarm = exactAlarmPermission.isGranted;

      AndroidScheduleMode scheduleMode;
      if (canUseExactAlarm) {
        scheduleMode = AndroidScheduleMode.alarmClock;
      } else {
        scheduleMode = AndroidScheduleMode.inexact;
      }

      await _plugin.zonedSchedule(
        id: id,
        title: l10n.notificationAdhanTitle(prayerName),
        body: l10n.notificationAdhanBody,
        scheduledDate: tzDate,
        notificationDetails: details,
        androidScheduleMode: scheduleMode,
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to schedule adhan notification',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
  }) async {
    try {
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
        id: id,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(scheduledAt, tz.local),
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to schedule reminder notification',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> showInstant({
    required String title,
    required String body,
    String adhanFile = 'azan1.mp3',
  }) async {
    try {
      final l10n = appLocalizationsForDevice();
      final androidSound = _androidSoundNameFor(adhanFile);
      final androidChannelId = _androidChannelIdFor(adhanFile);

      await _ensureAndroidAdhanChannel(
        channelId: androidChannelId,
        soundName: androidSound,
        l10n: l10n,
      );

      await _plugin.show(
        id: 99,
        title: title,
        body: body,
        notificationDetails: NotificationDetails(
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
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to show instant notification',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> testAdhanSound(String adhanFile) async {
    try {
      final permissionGranted = await requestPermission();
      if (!permissionGranted) {
        return;
      }

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
          sound: adhanFile.replaceAll('.mp3', '.caf'),
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      await _plugin.show(
        id: 999,
        title: 'Test Adhan',
        body: 'Testing adhan sound',
        notificationDetails: details,
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to test adhan sound',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> cancel(int id) async => _plugin.cancel(id: id);

  Future<void> cancelAll() async => _plugin.cancelAll();

  /// Cancela únicamente las notificaciones relacionadas con oraciones:
  /// hoy (0-4), mañana (5-9), Ramadán imsak/iftar (100-101), Jumu'ah (102).
  /// No cancela la inspiración diaria (10001) ni los hadiths horarios (20000+).
  Future<void> cancelPrayerNotifications() async {
    for (final id in [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 100, 101, 102]) {
      await _plugin.cancel(id: id);
    }
  }

  Future<void> _deleteOldAdhanChannels() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;

    const oldPrefixes = [
      'adhan_channel_v1_',
      'adhan_channel_v2_',
      'adhan_channel_v3_'
    ];
    const adhanFiles = [
      'azan1.mp3',
      'azan2.mp3',
      'azan3.mp3',
      'azan4.mp3',
      'azan5.mp3',
      'azan6.mp3',
      'azan_madinah.mp3',
      'azan_makkah.mp3',
    ];

    for (final prefix in oldPrefixes) {
      for (final file in adhanFiles) {
        final channelId = '$prefix${_androidSoundNameFor(file)}';
        try {
          await android.deleteNotificationChannel(channelId: channelId);
        } catch (_) {}
      }
    }
  }

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
    try {
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
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to create Android adhan notification channel',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<bool> requestPermission() async {
    final status = await Permission.notification.status;
    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }
    if (status.isGranted) {
      return true;
    }

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }

    final ios = _plugin.resolvePlatformSpecificImplementation<
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

  Future<bool> needsManufacturerBatterySettings() async {
    if (!Platform.isAndroid) return false;
    final manufacturer =
        (await DeviceInfoPlugin().androidInfo).manufacturer.toLowerCase();
    return ['huawei', 'samsung', 'xiaomi', 'oppo', 'vivo', 'oneplus'].any(
      (m) => manufacturer.contains(m),
    );
  }

  Future<bool> areNotificationsEnabled() async {
    final status = await Permission.notification.status;
    return status.isGranted || status.isLimited || status.isProvisional;
  }

  Future<bool> isExactAlarmPermissionGranted() async {
    if (!Platform.isAndroid) return true;
    final status = await Permission.scheduleExactAlarm.status;
    return status.isGranted;
  }

  Future<bool> requestExactAlarmPermission() async {
    if (!Platform.isAndroid) return true;

    final status = await Permission.scheduleExactAlarm.status;
    if (status.isGranted) return true;
    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }

    final result = await Permission.scheduleExactAlarm.request();
    return result.isGranted;
  }
}
