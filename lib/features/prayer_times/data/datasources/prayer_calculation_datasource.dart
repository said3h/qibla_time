import 'package:adhan/adhan.dart';

import '../../domain/entities/prayer_location.dart';
import '../../domain/entities/prayer_schedule.dart';
import '../../domain/entities/prayer_settings.dart';

class PrayerCalculationDataSource {
  PrayerSchedule calculate({
    required PrayerLocation location,
    required PrayerSettings settings,
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();
    final coordinates = Coordinates(location.latitude, location.longitude);
    final params = settings.method.getParameters();
    params.madhab = settings.madhab;
    params.adjustments.fajr = settings.timeOffsetMinutes;
    params.adjustments.dhuhr = settings.timeOffsetMinutes;
    params.adjustments.asr = settings.timeOffsetMinutes;
    params.adjustments.maghrib = settings.timeOffsetMinutes;
    params.adjustments.isha = settings.timeOffsetMinutes;

    final prayerTimes = PrayerTimes(
      coordinates,
      DateComponents.from(reference),
      params,
    );

    return PrayerSchedule(
      date: DateTime(reference.year, reference.month, reference.day),
      fajr: prayerTimes.fajr,
      dhuhr: prayerTimes.dhuhr,
      asr: prayerTimes.asr,
      maghrib: prayerTimes.maghrib,
      isha: prayerTimes.isha,
    );
  }
}
