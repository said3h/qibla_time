import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

class SettingsService {
  SettingsService._();
  static final SettingsService instance = SettingsService._();

  static const _keyAdhan = 'selected_adhan';
  static const _keyNotifications = 'prayer_notifications';
  static const _keyCalcMethod = 'calculation_method';
  static const _keyMadhab = 'prayer_madhab';

  Future<void> saveAdhan(String fileName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAdhan, fileName);
  }

  Future<String> getAdhan() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAdhan) ?? 'azan1.mp3';
  }

  Future<void> saveNotificationsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotifications, value);
  }

  Future<bool> getNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyNotifications) ?? true;
  }

  String _prayerNotificationKey(String prayerKey) => 'prayer_notif_$prayerKey';
  String _legacyPrayerNotificationKey(String prayerKey) => 'adhan_$prayerKey';

  Future<void> savePrayerNotificationEnabled(
    String prayerKey,
    bool value,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prayerNotificationKey(prayerKey), value);
    await prefs.remove(_legacyPrayerNotificationKey(prayerKey));
  }

  Future<bool> getPrayerNotificationEnabled(String prayerKey) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _prayerNotificationKey(prayerKey);
    final legacyKey = _legacyPrayerNotificationKey(prayerKey);

    final currentValue = prefs.getBool(key);
    if (currentValue != null) {
      return currentValue;
    }

    final legacyValue = prefs.getBool(legacyKey);
    if (legacyValue != null) {
      await prefs.setBool(key, legacyValue);
      await prefs.remove(legacyKey);
      return legacyValue;
    }

    return true;
  }

  Future<void> saveCalculationMethod(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyCalcMethod, value);
  }

  Future<int> getCalculationMethod() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyCalcMethod) ?? 1;
  }

  Future<void> saveMadhab(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyMadhab, value);
  }

  Future<int> getMadhab() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyMadhab) ?? 0;
  }

  Future<void> saveRamadanModeAutomatic(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyRamadanModeAutomatic, value);
  }

  Future<bool> getRamadanModeAutomatic() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.keyRamadanModeAutomatic) ?? true;
  }

  Future<void> saveRamadanModeForced(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyRamadanModeForced, value);
  }

  Future<bool> getRamadanModeForced() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.keyRamadanModeForced) ?? false;
  }

  Future<void> saveProfileDisplayName(String? value) async {
    final prefs = await SharedPreferences.getInstance();
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      await prefs.remove(AppConstants.keyProfileDisplayName);
      return;
    }
    await prefs.setString(AppConstants.keyProfileDisplayName, normalized);
  }

  Future<String?> getProfileDisplayName() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(AppConstants.keyProfileDisplayName)?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }

  Future<void> saveProfileNationalityCode(String? value) async {
    final prefs = await SharedPreferences.getInstance();
    final normalized = value?.trim().toUpperCase();
    if (normalized == null || normalized.isEmpty) {
      await prefs.remove(AppConstants.keyProfileNationalityCode);
      return;
    }
    await prefs.setString(AppConstants.keyProfileNationalityCode, normalized);
  }

  Future<String?> getProfileNationalityCode() async {
    final prefs = await SharedPreferences.getInstance();
    final value =
        prefs.getString(AppConstants.keyProfileNationalityCode)?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return value.toUpperCase();
  }

  Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
