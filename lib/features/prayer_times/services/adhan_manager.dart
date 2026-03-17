import 'package:adhan/adhan.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';
import 'prayer_service.dart';

final adhanManagerProvider = Provider((ref) => AdhanManager(ref));

class AdhanManager {
  final Ref _ref;

  AdhanManager(this._ref);

  Future<void> scheduleTodayAdhans() async {
    final prayerTimes = await _ref.read(prayerTimesProvider.future);
    if (prayerTimes == null) return;

    final prefs = await SharedPreferences.getInstance();
    await NotificationService.cancelAll();

    final prayers = {
      'Fajr': prayerTimes.fajr,
      'Dhuhr': prayerTimes.dhuhr,
      'Asr': prayerTimes.asr,
      'Maghrib': prayerTimes.maghrib,
      'Isha': prayerTimes.isha,
    };

    int id = 0;
    for (var entry in prayers.entries) {
      final prayerName = entry.key;
      final prayerTime = entry.value;
      
      // Check if user enabled Adhan for this prayer
      final isEnabled = prefs.getBool('adhan_${prayerName.toLowerCase()}') ?? true;
      
      if (isEnabled && prayerTime.isAfter(DateTime.now())) {
        await NotificationService.scheduleAdhan(
          id,
          'Adhan: $prayerName',
          prayerTime,
          'adhan', // Base sound name
        );
      }
      id++;
    }
  }
}
