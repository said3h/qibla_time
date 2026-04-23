// lib/features/prayer_times/services/adhan_manager.dart

import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/logger_service.dart';
import '../../period/services/period_mode_service.dart';
import '../../tracking/services/weekly_summary_notification_service.dart';
import '../presentation/providers/prayer_times_providers.dart';
import 'notification_service.dart';

final adhanManagerProvider = Provider<AdhanManager>((ref) => AdhanManager(ref));

class AdhanManager {
  AdhanManager(this._ref);

  final Ref _ref;

  Future<void> scheduleTodayAdhans() async {
    final startedAt = DateTime.now();
    AppLogger.info('AdhanManager.scheduleTodayAdhans: start at $startedAt');

    // On a clean install, scheduling before location permission is granted can
    // block startup or trigger permission flows too early. Bail out quickly and
    // rely on the next app open/resume after permissions are granted.
    final locationPermission = await Geolocator.checkPermission();
    final hasLocationPermission =
        locationPermission == LocationPermission.always ||
            locationPermission == LocationPermission.whileInUse;
    if (!hasLocationPermission) {
      AppLogger.info(
        'AdhanManager.scheduleTodayAdhans: locationPermission=$locationPermission; skipping schedule',
      );
      return;
    }
    final locationServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!locationServiceEnabled) {
      AppLogger.info(
        'AdhanManager.scheduleTodayAdhans: locationServiceEnabled=false; skipping schedule',
      );
      return;
    }

    final periodModeEnabled =
        await _ref.read(periodModeServiceProvider).isEnabled();
    if (periodModeEnabled) {
      AppLogger.info(
        'AdhanManager.scheduleTodayAdhans: periodModeEnabled=true; canceling prayer notifications',
      );
      await NotificationService.instance.cancelPrayerNotifications();
      return;
    }

    final resolvedSchedule =
        await _ref.read(getPrayerScheduleUseCaseProvider).call();
    if (resolvedSchedule == null) {
      // Location unavailable (GPS timeout, no cache). Do NOT cancel existing
      // notifications — they may have been correctly scheduled by a prior call
      // (e.g. yesterday's app open). Wiping them here means silence today if
      // the first startup happens while GPS hasn't fixed yet.
      AppLogger.warning(
        'AdhanManager.scheduleTodayAdhans: resolvedSchedule=null; '
        'skipping schedule (keeping existing notifications intact)',
      );
      return;
    }

    AppLogger.info(
      'AdhanManager.scheduleTodayAdhans: schedule resolved '
      'date=${resolvedSchedule.schedule.date} location=${resolvedSchedule.location.latitude},${resolvedSchedule.location.longitude}',
    );

    // Programa las oraciones que quedan hoy (IDs 0-4)
    AppLogger.info('AdhanManager.scheduleTodayAdhans: calling rescheduleToday');
    await _ref
        .read(reschedulePrayerNotificationsUseCaseProvider)
        .call(resolvedSchedule.schedule);

    // Programa todas las oraciones de mañana (IDs 5-9) para garantizar que el
    // adhan suene aunque el usuario no vuelva a abrir la app antes de Fajr.
    AppLogger.info('AdhanManager.scheduleTodayAdhans: scheduling tomorrow adhans');
    await _scheduleTomorrowAdhans();

    await _ref
        .read(weeklySummaryNotificationServiceProvider)
        .scheduleWeeklySummaryNotification();

    final finishedAt = DateTime.now();
    AppLogger.info(
      'AdhanManager.scheduleTodayAdhans: done at $finishedAt '
      '(took=${finishedAt.difference(startedAt).inMilliseconds}ms)',
    );
  }

  Future<void> _scheduleTomorrowAdhans() async {
    try {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final resolvedTomorrow = await _ref
          .read(prayerTimesRepositoryProvider)
          .getScheduleForDate(tomorrow);
      if (resolvedTomorrow == null) {
        return;
      }
      await _ref
          .read(prayerNotificationsDataSourceProvider)
          .scheduleTomorrow(resolvedTomorrow.schedule);
    } catch (e, stackTrace) {
      // No es bloqueante: si falla la programación de mañana, hoy sigue sonando.
      AppLogger.error(
        'Failed to schedule tomorrow adhans',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> cancelPrayer(String prayerName) async {
    const prayerIds = {
      'Fajr': 0,
      'Dhuhr': 1,
      'Asr': 2,
      'Maghrib': 3,
      'Isha': 4,
    };
    final id = prayerIds[prayerName];
    if (id != null) {
      await NotificationService.instance.cancel(id);
    }
  }
}
