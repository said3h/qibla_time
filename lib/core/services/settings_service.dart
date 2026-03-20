// lib/core/services/settings_service.dart
//
// Añadido: getPrayerNotificationEnabled / savePrayerNotificationEnabled
// para controlar cada oración individualmente (como muestra el prototipo)

import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  SettingsService._();
  static final SettingsService instance = SettingsService._();

  // ── Adhan ────────────────────────────────────────────────────
  static const _keyAdhan = 'selected_adhan';

  Future<void> saveAdhan(String fileName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAdhan, fileName);
  }

  Future<String> getAdhan() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAdhan) ?? 'azan1.mp3';
  }

  // ── Notificaciones globales ───────────────────────────────────
  static const _keyNotifications = 'prayer_notifications';

  Future<void> saveNotificationsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotifications, value);
  }

  Future<bool> getNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyNotifications) ?? true;
  }

  // ── Notificaciones por oración ───────────────────────────────
  // Keys: 'prayer_notif_fajr', 'prayer_notif_dhuhr', etc.

  String _prayerNotificationKey(String prayerKey) => 'prayer_notif_$prayerKey';
  String _legacyPrayerNotificationKey(String prayerKey) => 'adhan_$prayerKey';

  Future<void> savePrayerNotificationEnabled(
    String prayerKey,  // 'fajr', 'dhuhr', 'asr', 'maghrib', 'isha'
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

    // Por defecto todas activadas
    return true;
  }

  // ── Método de cálculo ────────────────────────────────────────
  static const _keyCalcMethod = 'calculation_method';

  Future<void> saveCalculationMethod(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyCalcMethod, value);
  }

  Future<int> getCalculationMethod() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyCalcMethod) ?? 1; // 1 = Muslim World League
  }

  // ── Madhab ───────────────────────────────────────────────────
  static const _keyMadhab = 'prayer_madhab';

  Future<void> saveMadhab(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyMadhab, value);
  }

  Future<int> getMadhab() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyMadhab) ?? 0; // 0 = Shafi
  }

  // ── Reset ─────────────────────────────────────────────────────
  Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
