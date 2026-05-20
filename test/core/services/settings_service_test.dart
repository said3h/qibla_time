import 'package:flutter_test/flutter_test.dart';
import 'package:qibla_time/core/services/settings_service.dart';
import 'package:qibla_time/core/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    StorageService.resetPrefsForTesting();
    SharedPreferences.setMockInitialValues({});
  });

  group('SettingsService', () {
    test('uses safe defaults when preferences are empty', () async {
      final service = SettingsService.instance;

      expect(await service.getAdhan(), 'azan1.mp3');
      expect(await service.getNotificationsEnabled(), isTrue);
      expect(await service.getCalculationMethod(), 1);
      expect(await service.getMadhab(), 0);
      expect(await service.getQuranTajweedEnabled(), isFalse);
      expect(await service.getTafsirEnabled(), isFalse);
    });

    test('persists settings through the cached StorageService preferences',
        () async {
      final service = SettingsService.instance;

      await service.saveAdhan('azan_madinah.mp3');
      await service.saveNotificationsEnabled(false);
      await service.saveCalculationMethod(4);
      await service.saveMadhab(1);
      await service.saveQuranTajweedEnabled(true);
      await service.saveTafsirEnabled(true);

      expect(await service.getAdhan(), 'azan_madinah.mp3');
      expect(await service.getNotificationsEnabled(), isFalse);
      expect(await service.getCalculationMethod(), 4);
      expect(await service.getMadhab(), 1);
      expect(await service.getQuranTajweedEnabled(), isTrue);
      expect(await service.getTafsirEnabled(), isTrue);
    });

    test('migrates legacy prayer notification keys once', () async {
      SharedPreferences.setMockInitialValues({'adhan_fajr': false});
      StorageService.resetPrefsForTesting();
      final service = SettingsService.instance;

      final enabled = await service.getPrayerNotificationEnabled('fajr');
      final prefs = await StorageService.prefs;

      expect(enabled, isFalse);
      expect(prefs.getBool('prayer_notif_fajr'), isFalse);
      expect(prefs.containsKey('adhan_fajr'), isFalse);
    });

    test('removes blank profile values instead of storing empty strings',
        () async {
      final service = SettingsService.instance;

      await service.saveProfileDisplayName(' Said ');
      await service.saveProfileNationalityCode(' es ');
      expect(await service.getProfileDisplayName(), 'Said');
      expect(await service.getProfileNationalityCode(), 'ES');

      await service.saveProfileDisplayName('   ');
      await service.saveProfileNationalityCode(null);
      expect(await service.getProfileDisplayName(), isNull);
      expect(await service.getProfileNationalityCode(), isNull);
    });
  });
}
