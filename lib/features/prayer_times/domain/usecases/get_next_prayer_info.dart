import '../entities/next_prayer_info.dart';
import '../entities/prayer_schedule.dart';

class GetNextPrayerInfoUseCase {
  const GetNextPrayerInfoUseCase();

  NextPrayerInfo? call(
    PrayerSchedule schedule, {
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();

    for (final entry in schedule.times.entries) {
      if (!entry.value.isBefore(reference)) {
        final remaining = entry.value.difference(reference);
        return NextPrayerInfo(
          prayer: entry.key,
          time: entry.value,
          remaining: remaining.isNegative ? Duration.zero : remaining,
        );
      }
    }

    return null;
  }
}
