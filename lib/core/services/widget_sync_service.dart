// lib/core/services/widget_sync_service.dart
//
// Sincroniza los datos de la próxima oración con los widgets
// nativos de Android e iOS usando el paquete home_widget.
//
// Android: guarda en SharedPreferences con nombre "HomeWidgetPreferences"
// iOS:     guarda en UserDefaults del App Group "group.com.qiblatime.qibla_time"
//
// Las keys deben coincidir EXACTAMENTE con las que leen
// PrayerWidgetProvider.kt y PrayerWidget.swift

import 'package:home_widget/home_widget.dart';

class WidgetSyncService {
  WidgetSyncService._();
  static final WidgetSyncService instance = WidgetSyncService._();

  // App Group ID — debe coincidir con Xcode y PrayerWidget.swift
  static const _appGroupId    = 'group.com.qiblatime.qibla_time';
  static const _androidWidget = 'com.qiblatime.qibla_time.PrayerWidgetProvider';
  static const _iosWidget     = 'PrayerWidget';

  // Keys — deben coincidir con el código nativo
  static const _keyName      = 'next_prayer_name';
  static const _keyTime      = 'next_prayer_time';
  static const _keyCountdown = 'next_prayer_countdown';

  /// Inicializa el servicio. Llama esto en main.dart al arrancar.
  Future<void> initialize() async {
    await HomeWidget.setAppGroupId(_appGroupId);
  }

  /// Alias para compatibilidad con código existente
  Future<void> configure() async => initialize();

  /// Llama esto cada vez que cambien los horarios o el countdown.
  /// [prayerName] — 'Asr · عصر'
  /// [prayerTime] — '17:14'
  /// [countdown]  — '2h 33min'
  Future<void> syncNextPrayer({
    required String prayerName,
    required String prayerTime,
    required String countdown,
  }) async {
    await Future.wait([
      HomeWidget.saveWidgetData<String>(_keyName,      prayerName),
      HomeWidget.saveWidgetData<String>(_keyTime,      prayerTime),
      HomeWidget.saveWidgetData<String>(_keyCountdown, countdown),
    ]);

    // Fuerza la actualización visual del widget en pantalla de inicio
    await HomeWidget.updateWidget(
      androidName: _androidWidget,
      iOSName:     _iosWidget,
    );
  }

  /// Formatea la cuenta atrás en texto legible
  /// [seconds] — segundos totales hasta la próxima oración
  static String formatCountdown(int seconds) {
    if (seconds <= 0) return '—';
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}min';
    return '${m}min';
  }
}
