import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../hadith/services/hadith_service.dart';
import 'notification_service.dart';
import '../services/quran_service.dart';

/// Servicio para notificaciones diarias inspiracionales (Corán + Hadiz)
class DailyInspirationNotificationService {
  final FlutterLocalNotificationsPlugin _plugin;
  final HadithService _hadithService;

  static const String _channelId = 'daily_inspiration';
  static const String _channelName = 'Reflexión Diaria';
  static const String _channelDesc = 'Versículo del Corán y Hadiz del día';
  static const String _prefsKey = 'daily_inspiration_enabled';
  static const String _prefsHourKey = 'daily_inspiration_hour';

  DailyInspirationNotificationService({
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

    await _plugin.zonedSchedule(
      10001, // ID único para notificación diaria
      content.title,
      content.body,
      scheduledDate,
      _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Cancela la notificación diaria
  Future<void> cancelDailyNotification() async {
    await _plugin.cancel(10001);
  }

  /// Genera el contenido de la notificación
  Future<NotificationContent> _generateNotificationContent() async {
    try {
      // Obtener hadiz del día
      final hadith = await _hadithService.getHadithOfDay();

      // Obtener versículo del día (llamada estática)
      final quranVerse = await QuranVerseService.getDailyVerse('es');

      // Construir título
      final title = 'Reflexión del Día';

      // Construir cuerpo con hadiz o versículo (alternar)
      final now = DateTime.now();
      final useHadith = now.day % 2 == 0; // Alternar días

      String body;
      if (useHadith && hadith != null) {
        final translation = hadith.translation;
        body = translation.length > 150
            ? '${translation.substring(0, 147)}...'
            : translation;
        body += ' — ${hadith.reference}';
      } else if (quranVerse != null) {
        final translation = quranVerse.translationText;
        body = translation.length > 150
            ? '${translation.substring(0, 147)}...'
            : translation;
        body += ' — ${quranVerse.reference}';
      } else {
        body = 'Tu reflexión espiritual diaria de Qibla Time';
      }

      return NotificationContent(
        title: title,
        body: body,
        isHadith: useHadith,
      );
    } catch (e) {
      // Fallback en caso de error
      return NotificationContent(
        title: 'Qibla Time - Reflexión Diaria',
        body: 'Tu recordatorio espiritual de hoy',
        isHadith: true,
      );
    }
  }

  /// Configuración de notificación
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
      10002,
      content.title,
      content.body,
      _notificationDetails(),
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
