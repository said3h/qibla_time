import 'package:flutter_test/flutter_test.dart';
import 'package:qibla_time/features/prayer_times/domain/entities/prayer_name.dart';
import 'package:qibla_time/features/prayer_times/domain/entities/prayer_schedule.dart';
import 'package:qibla_time/features/prayer_times/domain/usecases/get_next_prayer_info.dart';

void main() {
  group('GetNextPrayerInfoUseCase', () {
    const useCase = GetNextPrayerInfoUseCase();
    final schedule = PrayerSchedule(
      date: DateTime(2026, 3, 25),
      fajr: DateTime(2026, 3, 25, 5, 10),
      dhuhr: DateTime(2026, 3, 25, 13, 20),
      asr: DateTime(2026, 3, 25, 17, 0),
      maghrib: DateTime(2026, 3, 25, 19, 40),
      isha: DateTime(2026, 3, 25, 21, 5),
    );

    test('returns the next upcoming prayer', () {
      final result = useCase.call(
        schedule,
        now: DateTime(2026, 3, 25, 16, 30),
      );

      expect(result, isNotNull);
      expect(result!.prayer, PrayerName.asr);
      expect(result.time, DateTime(2026, 3, 25, 17, 0));
      expect(result.remaining, const Duration(minutes: 30));
    });

    test('returns null after isha has passed', () {
      final result = useCase.call(
        schedule,
        now: DateTime(2026, 3, 25, 22, 0),
      );

      expect(result, isNull);
    });
  });
}
