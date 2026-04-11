// lib/features/prayer_times/services/adhan_manager.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      await NotificationService.instance.cancelAll();
      return;
    }

    final resolvedSchedule = await _ref.read(getPrayerScheduleUseCaseProvider).call();
    if (resolvedSchedule == null) {
      await NotificationService.instance.cancelAll();
      await _ref
          .read(weeklySummaryNotificationServiceProvider)
          .scheduleWeeklySummaryNotification();
      return;
    }

    await _ref
        .read(reschedulePrayerNotificationsUseCaseProvider)
        .call(resolvedSchedule.schedule);
    await _ref
        .read(weeklySummaryNotificationServiceProvider)
        .scheduleWeeklySummaryNotification();
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
