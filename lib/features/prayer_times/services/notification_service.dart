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

  // v5: bump forzado para eliminar canales v4 que podían estar corruptos
  // (sin sonido si el canal fue creado antes de que res/raw/ existiera).
  static const _androidAdhanChannelPrefix = 'adhan_channel_v5_';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  FlutterLocalNotificationsPlugin get plugin => _plugin;

  Future<void> initialize() async {
    try {
      tz.initializeTimeZones();

      AppLogger.info('NotificationService: initializing...');

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

      AppLogger.info('NotificationService: initialized OK');
    } catch (e, stackTrace) {
      AppLogger.error(
        'NotificationService: FAILED to initialize',
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

      AppLogger.info(
        'scheduleAdhan: id=$id prayer=$prayerName at=$scheduledAt '
        'sound=$androidSound channel=$androidChannelId',
      );

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
          priority: Priority.max,
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

      AndroidScheduleMode scheduleMode;
      if (Platform.isAndroid) {
        final exactAlarmPermission = await Permission.scheduleExactAlarm.status;
        final canUseExactAlarm = exactAlarmPermission.isGranted;
        scheduleMode = canUseExactAlarm
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle;
        AppLogger.info(
          'scheduleAdhan: exactAlarm=${exactAlarmPermission.name} '
          'mode=${canUseExactAlarm ? "exactAllowWhileIdle" : "inexactAllowWhileIdle"}',
        );
      } else {
        scheduleMode = AndroidScheduleMode.exactAllowWhileIdle;
      }

      await _plugin.zonedSchedule(
        id: id,
        title: l10n.notificationAdhanTitle(prayerName),
        body: l10n.notificationAdhanBody,
        scheduledDate: tzDate,
        notificationDetails: details,
        androidScheduleMode: scheduleMode,
      );

      AppLogger.info('scheduleAdhan: SCHEDULED id=$id OK');
    } catch (e, stackTrace) {
      AppLogger.error(
        'scheduleAdhan: FAILED id=$id prayer=$prayerName',
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

      AppLogger.info('scheduleReminder: id=$id title="$title" at=$scheduledAt');

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

      // En Android 12+ exactAllowWhileIdle lanza SecurityException si el permiso
      // SCHEDULE_EXACT_ALARM no está concedido. Aplicamos el mismo guard que scheduleAdhan.
      AndroidScheduleMode scheduleMode = AndroidScheduleMode.inexactAllowWhileIdle;
      if (Platform.isAndroid) {
        final exactAlarmPermission = await Permission.scheduleExactAlarm.status;
        final canUseExactAlarm = exactAlarmPermission.isGranted;
        scheduleMode = canUseExactAlarm
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle;
        AppLogger.info(
          'scheduleReminder: exactAlarm=${exactAlarmPermission.name} '
          'mode=${canUseExactAlarm ? "exactAllowWhileIdle" : "inexactAllowWhileIdle"}',
        );
      }

      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(scheduledAt, tz.local),
        notificationDetails: details,
        androidScheduleMode: scheduleMode,
      );

      AppLogger.info('scheduleReminder: SCHEDULED id=$id OK');
    } catch (e, stackTrace) {
      AppLogger.error(
        'scheduleReminder: FAILED id=$id title="$title"',
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
      'adhan_channel_v3_',
      'adhan_channel_v4_', // eliminado en v5: canales creados sin sonido válido
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
        AppLogger.info('_ensureAndroidAdhanChannel: not Android, skipping');
        return;
      }

      AppLogger.info(
        '_ensureAndroidAdhanChannel: creating channel=$channelId sound=$soundName',
      );

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

      AppLogger.info('_ensureAndroidAdhanChannel: channel=$channelId created OK');
    } catch (e, stackTrace) {
      AppLogger.error(
        '_ensureAndroidAdhanChannel: FAILED channel=$channelId',
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

  /// Dispara una notificación inmediata para verificar que el sistema funciona.
  /// Solo usar en debug/QA. Llama esto desde Settings o desde un botón temporal
  /// para confirmar que el canal, el sonido y los permisos están bien.
  Future<void> sendTestNotification() async {
    try {
      AppLogger.info('sendTestNotification: starting...');

      final notifPermission = await Permission.notification.status;
      AppLogger.info('sendTestNotification: notification=${notifPermission.name}');

      if (Platform.isAndroid) {
        final exactAlarm = await Permission.scheduleExactAlarm.status;
        AppLogger.info('sendTestNotification: scheduleExactAlarm=${exactAlarm.name}');

        final android = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

        if (android == null) {
          AppLogger.error(
            'sendTestNotification: AndroidFlutterLocalNotificationsPlugin es NULL. '
            'R8/ProGuard puede haber eliminado la clase en release.',
          );
          return;
        }

        final channels = await android.getNotificationChannels();
        AppLogger.info(
          'sendTestNotification: active channels=${channels?.map((c) => '${c.id}(sound=${c.sound})').toList()}',
        );

        if (notifPermission.isDenied || notifPermission.isPermanentlyDenied) {
          AppLogger.error(
            'sendTestNotification: ABORTED — permiso de notificación denegado',
          );
          return;
        }
      }

      const testAdhanFile = 'azan1.mp3';
      final androidSound = _androidSoundNameFor(testAdhanFile);
      final androidChannelId = _androidChannelIdFor(testAdhanFile);
      final l10n = appLocalizationsForDevice();

      AppLogger.info(
        'sendTestNotification: usando channel=$androidChannelId sound=$androidSound',
      );

      await _ensureAndroidAdhanChannel(
        channelId: androidChannelId,
        soundName: androidSound,
        l10n: l10n,
      );

      await _plugin.show(
        id: 9999,
        title: '🔔 Test QiblaTime',
        body: 'Si ves esto, las notificaciones funcionan',
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            androidChannelId,
            l10n.notificationAdhanChannelName,
            importance: Importance.max,
            priority: Priority.max,
            sound: RawResourceAndroidNotificationSound(androidSound),
            playSound: true,
            enableVibration: true,
          ),
          iOS: const DarwinNotificationDetails(
            sound: 'azan1.caf',
            presentAlert: true,
            presentSound: true,
          ),
        ),
      );

      AppLogger.info('sendTestNotification: FIRED OK — debería aparecer ahora');
    } catch (e, stackTrace) {
      AppLogger.error(
        'sendTestNotification: FAILED — error=${e.runtimeType}: $e',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
