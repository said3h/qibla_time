import 'package:flutter_test/flutter_test.dart';
import 'package:qibla_time/features/prayer_times/services/notification_service.dart';

void main() {
  group('NotificationService', () {
    test('maps adhan mp3 files to Android raw resource names', () {
      final service = NotificationService.instance;

      expect(service.debugAndroidSoundNameFor('azan1.mp3'), 'adhan_azan1');
      expect(
        service.debugAndroidSoundNameFor('azan_madinah.mp3'),
        'adhan_azan_madinah',
      );
    });

    test('uses the current adhan channel version for custom sounds', () {
      final service = NotificationService.instance;

      expect(
        service.debugAndroidChannelIdFor('azan1.mp3'),
        'adhan_channel_v7_adhan_azan1',
      );
    });
  });
}
