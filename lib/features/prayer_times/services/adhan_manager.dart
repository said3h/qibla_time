// lib/features/prayer_times/services/adhan_manager.dart

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/logger_service.dart';
import '../../period/services/period_mode_service.dart';
import '../../tracking/services/weekly_summary_notification_service.dart';
import '../presentation/providers/prayer_times_providers.dart';
import '../domain/entities/prayer_notification_window.dart';
import 'notification_service.dart';

final adhanManagerProvider = Provider<AdhanManager>((ref) => AdhanManager(ref));

class AdhanManager {
  AdhanManager(this._ref, {ScheduleRunGate? scheduleGate})
      : _scheduleGate = scheduleGate ?? ScheduleRunGate();

  final Ref _ref;
  final ScheduleRunGate _scheduleGate;

  Future<void> scheduleTodayAdhans() async {
    await _scheduleGate.run(_scheduleTodayAdhans);
  }

  Future<void> _scheduleTodayAdhans() async {
    final startedAt = DateTime.now();
    AppLogger.info('AdhanManager.scheduleTodayAdhans: start at $startedAt');

    final hasManualLocation =
        await _ref.read(prayerLocationDataSourceProvider).hasManualLocation();
    if (!hasManualLocation) {
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
      final locationServiceEnabled =
          await Geolocator.isLocationServiceEnabled();
      if (!locationServiceEnabled) {
        AppLogger.info(
          'AdhanManager.scheduleTodayAdhans: locationServiceEnabled=false; skipping schedule',
        );
        return;
      }
    } else {
      AppLogger.info(
        'AdhanManager.scheduleTodayAdhans: using manual city location',
      );
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

    // Prepare the complete window before cancelling existing alarms. Use one
    // location/settings snapshot and calendar dates (not 24-hour increments).
    final date = resolvedSchedule.schedule.date;
    final calculator = _ref.read(prayerCalculationDataSourceProvider);
    final schedules = [
      resolvedSchedule.schedule,
      for (var day = 1; day < prayerNotificationDays; day++)
        calculator.calculate(
          location: resolvedSchedule.location,
          settings: resolvedSchedule.settings,
          now: DateTime(date.year, date.month, date.day + day),
        ),
    ];

    // Programa las oraciones que quedan hoy (IDs 0-4)
    AppLogger.info('AdhanManager.scheduleTodayAdhans: calling rescheduleToday');
    await _ref
        .read(reschedulePrayerNotificationsUseCaseProvider)
        .call(resolvedSchedule.schedule);

    for (var day = 1; day < schedules.length; day++) {
      await _ref.read(prayerNotificationsDataSourceProvider).scheduleFutureDay(
            schedules[day],
            dayOffset: day,
          );
    }

    await _ref
        .read(weeklySummaryNotificationServiceProvider)
        .scheduleWeeklySummaryNotification();

    final finishedAt = DateTime.now();
    AppLogger.info(
      'AdhanManager.scheduleTodayAdhans: done at $finishedAt '
      '(took=${finishedAt.difference(startedAt).inMilliseconds}ms)',
    );
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

@visibleForTesting
class ScheduleRunGate {
  Future<void>? _activeTask;

  Future<void> run(Future<void> Function() action) async {
    final activeTask = _activeTask;
    if (activeTask != null) {
      AppLogger.info(
        'AdhanManager.scheduleTodayAdhans: schedule already running; joining existing task',
      );
      return activeTask;
    }

    final task = Future<void>.sync(action);
    _activeTask = task;
    try {
      await task;
    } finally {
      if (identical(_activeTask, task)) {
        _activeTask = null;
      }
    }
  }
}
