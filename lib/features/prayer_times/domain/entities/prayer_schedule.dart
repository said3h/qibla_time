import 'prayer_name.dart';

class PrayerSchedule {
  const PrayerSchedule({
    required this.date,
    required this.fajr,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
  });

  final DateTime date;
  final DateTime fajr;
  final DateTime dhuhr;
  final DateTime asr;
  final DateTime maghrib;
  final DateTime isha;
  Map<PrayerName, DateTime> get times => {
        PrayerName.fajr: fajr,
        PrayerName.dhuhr: dhuhr,
        PrayerName.asr: asr,
        PrayerName.maghrib: maghrib,
        PrayerName.isha: isha,
      };

  DateTime timeFor(PrayerName prayer) => times[prayer]!;
}
