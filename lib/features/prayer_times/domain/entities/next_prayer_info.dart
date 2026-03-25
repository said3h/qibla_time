import 'prayer_name.dart';

class NextPrayerInfo {
  const NextPrayerInfo({
    required this.prayer,
    required this.time,
    required this.remaining,
  });

  final PrayerName prayer;
  final DateTime time;
  final Duration remaining;
}
