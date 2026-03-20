import 'package:flutter_test/flutter_test.dart';
import 'package:qibla_time/features/tracking/services/tracking_service.dart';

void main() {
  group('PrayerTrackingNotifier', () {
    test('normalizes prayer keys to lowercase canonical values', () async {
      final notifier = PrayerTrackingNotifier();
      final date = DateTime(2026, 3, 20);

      await notifier.togglePrayer('Fajr', date: date);

      expect(notifier.isPrayerCompleted('fajr', date), isTrue);
      expect(notifier.isPrayerCompleted('Fajr', date), isTrue);
      expect(notifier.getCompletedPrayers(date), contains('fajr'));
      expect(notifier.getCompletedPrayers(date), isNot(contains('Fajr')));
    });
  });
}
