import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';

class OnboardingService {
  Future<bool> isCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getBool(AppConstants.keyOnboardingCompleted);
    if (completed != null) {
      return completed;
    }

    if (_looksLikeExistingUser(prefs)) {
      await complete();
      return true;
    }

    return false;
  }

  Future<void> complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyOnboardingCompleted, true);
  }

  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keyOnboardingCompleted);
  }

  bool _looksLikeExistingUser(SharedPreferences prefs) {
    const migrationSignals = {
      AppConstants.keyCalculationMethod,
      AppConstants.keyPrayerNotifications,
      AppConstants.keyDhikrTotalCount,
      AppConstants.keyTravelerModeEnabled,
      AppConstants.keyTravelerLastLocationLabel,
      AppConstants.keyHadithFavorites,
      AppConstants.keyCloudLastBackup,
      'last_lat',
      'last_lng',
      'time_offset',
      'madhab_hanafi',
      'selected_adhan',
      'prayer_tracking_data',
    };

    return prefs.getKeys().any(migrationSignals.contains);
  }
}
