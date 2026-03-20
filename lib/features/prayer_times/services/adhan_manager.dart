// lib/features/prayer_times/services/adhan_manager.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/settings_service.dart';
import 'notification_service.dart';
import 'prayer_service.dart';

final adhanManagerProvider = Provider<AdhanManager>((ref) => AdhanManager(ref));

class AdhanManager {
  final Ref _ref;
  AdhanManager(this._ref);

  static const Map<String, int> _prayerIds = {
    'Fajr':    0,
    'Dhuhr':   1,
    'Asr':     2,
    'Maghrib': 3,
    'Isha':    4,
  };

  Future<void> scheduleTodayAdhans() async {
    final settings = SettingsService.instance;
    final notif    = NotificationService.instance;

    await notif.cancelAll();

    if (!await settings.getNotificationsEnabled()) return;

    // getAdhan() devuelve 'azan1.mp3', 'azan2.mp3', etc.
    final adhanFile = await settings.getAdhan();

    final prayerTimes = await _ref.read(prayerTimesProvider.future);
    if (prayerTimes == null) return;

    final prayers = {
      'Fajr':    prayerTimes.fajr,
      'Dhuhr':   prayerTimes.dhuhr,
      'Asr':     prayerTimes.asr,
      'Maghrib': prayerTimes.maghrib,
      'Isha':    prayerTimes.isha,
    };

    final now = DateTime.now();

    for (final entry in prayers.entries) {
      final name = entry.key;
      final time = entry.value;

      if (time.isBefore(now)) continue;

      final enabled = await settings.getPrayerNotificationEnabled(
        name.toLowerCase(),
      );
      if (!enabled) continue;

      await notif.scheduleAdhan(
        id:          _prayerIds[name]!,
        prayerName:  name,
        scheduledAt: time,
        adhanFile:   adhanFile,  // 'azan1.mp3' — NotificationService convierte
      );
    }
  }

  Future<void> cancelPrayer(String prayerName) async {
    final id = _prayerIds[prayerName];
    if (id != null) await NotificationService.instance.cancel(id);
  }
}
