import 'package:flutter_test/flutter_test.dart';
import 'package:qibla_time/features/tracking/models/tracking_models.dart';

void main() {
  group('TrackingState streaks', () {
    test('counts the current streak from yesterday when today is incomplete', () {
      final now = _todayAtNoon();
      final state = TrackingState.fromData({
        _key(now): _completedDay(3),
        _key(now.subtract(const Duration(days: 1))): _completedDay(5),
        _key(now.subtract(const Duration(days: 2))): _completedDay(5),
        _key(now.subtract(const Duration(days: 3))): _completedDay(0),
      });

      expect(state.currentStreak, 2);
    });

    test('includes today in the current streak when all prayers are complete', () {
      final now = _todayAtNoon();
      final state = TrackingState.fromData({
        _key(now): _completedDay(5),
        _key(now.subtract(const Duration(days: 1))): _completedDay(5),
        _key(now.subtract(const Duration(days: 2))): _completedDay(5),
        _key(now.subtract(const Duration(days: 3))): _completedDay(1),
      });

      expect(state.currentStreak, 3);
    });

    test('tracks the best streak across interrupted history', () {
      final now = _todayAtNoon();
      final state = TrackingState.fromData({
        _key(now.subtract(const Duration(days: 8))): _completedDay(5),
        _key(now.subtract(const Duration(days: 7))): _completedDay(5),
        _key(now.subtract(const Duration(days: 6))): _completedDay(5),
        _key(now.subtract(const Duration(days: 5))): _completedDay(0),
        _key(now.subtract(const Duration(days: 4))): _completedDay(5),
        _key(now.subtract(const Duration(days: 3))): _completedDay(5),
        _key(now.subtract(const Duration(days: 2))): _completedDay(1),
      });

      expect(state.bestStreak, 3);
    });
  });
}

Map<String, bool> _completedDay(int completed) {
  const prayers = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];
  return {
    for (var i = 0; i < prayers.length; i++) prayers[i]: i < completed,
  };
}

String _key(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

DateTime _todayAtNoon() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day, 12);
}
