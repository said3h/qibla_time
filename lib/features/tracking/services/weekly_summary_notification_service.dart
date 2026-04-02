import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../l10n/l10n.dart';
import '../../prayer_times/services/notification_service.dart';
import '../models/tracking_models.dart';

final weeklySummaryNotificationServiceProvider =
    Provider<WeeklySummaryNotificationService>((ref) {
  return WeeklySummaryNotificationService();
});

class WeeklySummaryNotificationService {
  static const _notificationId = 103;
  static const _trackingPrefsKey = 'prayer_tracking_data';

  Future<void> scheduleWeeklySummaryNotification() async {
    final l10n = appLocalizationsForDevice();
    final tracking = await _loadTrackingState();
    final summary = tracking.currentWeekSummary;
    final scheduledAt = _nextSundayAtNine();

    await NotificationService.instance.cancel(_notificationId);
    await NotificationService.instance.scheduleReminder(
      id: _notificationId,
      title: l10n.notificationWeeklySummaryTitle,
      body: l10n.notificationWeeklySummaryBody(
        summary.prayersCompleted,
        summary.maxPossible,
        summary.strongestDay.shortLabel,
      ),
      scheduledAt: scheduledAt,
    );
  }

  Future<TrackingState> _loadTrackingState() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_trackingPrefsKey);
    if (raw == null || raw.isEmpty) {
      return TrackingState.empty();
    }

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final data = decoded.map(
        (date, prayers) => MapEntry(
          date,
          (prayers as Map<String, dynamic>).map(
            (key, value) => MapEntry(key, value as bool),
          ),
        ),
      );
      return TrackingState.fromData(data);
    } catch (_) {
      return TrackingState.empty();
    }
  }

  DateTime _nextSundayAtNine([DateTime? now]) {
    final current = now ?? DateTime.now();
    var daysUntilSunday = DateTime.sunday - current.weekday;
    if (daysUntilSunday < 0) {
      daysUntilSunday += 7;
    }

    final candidate = DateTime(
      current.year,
      current.month,
      current.day + daysUntilSunday,
      9,
    );

    if (!candidate.isAfter(current)) {
      return candidate.add(const Duration(days: 7));
    }
    return candidate;
  }
}
