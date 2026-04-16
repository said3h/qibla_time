// lib/features/prayer_times/services/adhan_manager.dart

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
    final periodModeEnabled =
        await _ref.read(periodModeServiceProvider).isEnabled();
    if (periodModeEnabled) {
      await NotificationService.instance.cancelPrayerNotifications();
      return;
    }

    final resolvedSchedule =
        await _ref.read(getPrayerScheduleUseCaseProvider).call();
    if (resolvedSchedule == null) {
      await NotificationService.instance.cancelPrayerNotifications();
      await _ref
          .read(weeklySummaryNotificationServiceProvider)
          .scheduleWeeklySummaryNotification();
      return;
    }

    // Programa las oraciones que quedan hoy (IDs 0-4)
    await _ref
        .read(reschedulePrayerNotificationsUseCaseProvider)
        .call(resolvedSchedule.schedule);

    // Programa todas las oraciones de mañana (IDs 5-9) para garantizar que el
    // adhan suene aunque el usuario no vuelva a abrir la app antes de Fajr.
    await _scheduleTomorrowAdhans();

    await _ref
        .read(weeklySummaryNotificationServiceProvider)
        .scheduleWeeklySummaryNotification();
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
