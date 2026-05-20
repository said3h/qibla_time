import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qibla_time/features/prayer_times/services/adhan_manager.dart';
import 'package:qibla_time/features/prayer_times/services/notification_service.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationService', () {
    const androidSettingsChannel =
        MethodChannel('com.qiblatime/android_settings');

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(androidSettingsChannel, null);
      tz.setLocalLocation(tz.UTC);
    });

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

    test('configures local timezone from the Android channel before scheduling',
        () async {
      tz_data.initializeTimeZones();
      tz.setLocalLocation(tz.UTC);

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(androidSettingsChannel, (call) async {
        expect(call.method, 'getTimeZoneId');
        return 'Europe/Madrid';
      });

      await NotificationService.instance.debugConfigureLocalTimeZone(
        forceAndroidForTesting: true,
      );

      expect(tz.local.name, 'Europe/Madrid');
    });

    test('keeps current timezone when the Android channel is unavailable',
        () async {
      tz_data.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Europe/Paris'));

      await NotificationService.instance.debugConfigureLocalTimeZone(
        forceAndroidForTesting: true,
      );

      expect(tz.local.name, 'Europe/Paris');
    });
  });

  group('ScheduleRunGate', () {
    test('joins concurrent schedule calls instead of running them twice',
        () async {
      final gate = ScheduleRunGate();
      final completer = Completer<void>();
      var runs = 0;

      final first = gate.run(() async {
        runs++;
        await completer.future;
      });
      final second = gate.run(() async {
        runs++;
      });

      await Future<void>.delayed(Duration.zero);

      expect(runs, 1);

      completer.complete();
      await Future.wait([first, second]);
      expect(runs, 1);
    });

    test('allows a new schedule after the active one finishes', () async {
      final gate = ScheduleRunGate();
      var runs = 0;

      await gate.run(() async {
        runs++;
      });
      await gate.run(() async {
        runs++;
      });

      expect(runs, 2);
    });
  });
}
