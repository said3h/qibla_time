import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

class WidgetSyncService {
  static const appGroupId = 'group.com.qiblatime.shared';
  static const iOSWidgetName = 'QiblaTimeWidget';
  static const androidWidgetName = 'PrayerWidgetProvider';

  Future<void> configure() async {
    await HomeWidget.setAppGroupId(appGroupId);
  }

  Future<void> syncNextPrayer(PrayerSnapshot snapshot) async {
    await Future.wait([
      HomeWidget.saveWidgetData<String>('next_prayer_name', snapshot.name),
      HomeWidget.saveWidgetData<String>('next_prayer_time', snapshot.timeLabel),
      HomeWidget.saveWidgetData<String>('next_prayer_countdown', snapshot.countdownLabel),
      HomeWidget.saveWidgetData<String>('next_prayer_theme', snapshot.themeKey),
    ]);
    await HomeWidget.updateWidget(
      iOSName: iOSWidgetName,
      androidName: androidWidgetName,
    );
  }
}

class PrayerSnapshot {
  const PrayerSnapshot({
    required this.name,
    required this.timeLabel,
    required this.countdownLabel,
    required this.themeKey,
  });

  final String name;
  final String timeLabel;
  final String countdownLabel;
  final String themeKey;
}

final widgetSyncServiceProvider = Provider<WidgetSyncService>((ref) {
  return WidgetSyncService();
});
