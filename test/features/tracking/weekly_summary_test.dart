import 'package:flutter_test/flutter_test.dart';
import 'package:qibla_time/features/tracking/services/tracking_service.dart';

void main() {
  group('TrackingState.currentWeekSummary', () {
    test('calcula totales, dias completos y mejor dia de la semana', () {
      final now = DateTime.now();
      final data = <String, Map<String, bool>>{};

      void setDay(DateTime date, List<String> completed) {
        data[_dateKey(date)] = {
          'fajr': completed.contains('fajr'),
          'dhuhr': completed.contains('dhuhr'),
          'asr': completed.contains('asr'),
          'maghrib': completed.contains('maghrib'),
          'isha': completed.contains('isha'),
        };
      }

      setDay(now.subtract(const Duration(days: 6)), ['fajr', 'dhuhr']);
      setDay(now.subtract(const Duration(days: 5)), ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha']);
      setDay(now.subtract(const Duration(days: 4)), ['fajr']);
      setDay(now.subtract(const Duration(days: 3)), ['fajr', 'dhuhr', 'asr']);
      setDay(now.subtract(const Duration(days: 2)), ['fajr', 'dhuhr', 'asr', 'maghrib']);
      setDay(now.subtract(const Duration(days: 1)), ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha']);
      setDay(now, ['fajr', 'dhuhr', 'asr']);

      final state = TrackingState.fromData(data);
      final summary = state.currentWeekSummary;

      expect(summary.days, hasLength(7));
      expect(summary.prayersCompleted, 23);
      expect(summary.fullDays, 2);
      expect(summary.maxPossible, 35);
      expect(summary.strongestDay.completed, 5);
      expect(summary.weakestDay.completed, 1);
      expect(summary.currentStreak, 1);
      expect(summary.hasAnyActivity, isTrue);
    });
  });
}

String _dateKey(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
