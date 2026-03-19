import 'package:shared_preferences/shared_preferences.dart';

/// Servicio para gestionar las preferencias del usuario
class SettingsService {
  // Singleton
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  // Claves de preferencias
  static const String _adhanKey = 'selected_adhan';
  static const String _calculationMethodKey = 'calculation_method';
  static const String _madhabKey = 'madhab';
  static const String _notificationsEnabledKey = 'notifications_enabled';

  // ==================== ADHAN ====================
  
  /// Guarda el archivo de adhan seleccionado
  Future<void> saveAdhan(String fileName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_adhanKey, fileName);
  }

  /// Obtiene el archivo de adhan seleccionado
  Future<String> getAdhan() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_adhanKey) ?? 'adhan_makkah.mp3';
  }

  // ==================== CALCULATION METHOD ====================
  
  /// Guarda el método de cálculo seleccionado
  Future<void> saveCalculationMethod(int methodId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_calculationMethodKey, methodId);
  }

  /// Obtiene el método de cálculo seleccionado
  Future<int> getCalculationMethod() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_calculationMethodKey) ?? 1; // Default: Muslim World League
  }

  // ==================== MADHAB ====================
  
  /// Guarda el Madhab seleccionado (0 = Shafi, 1 = Hanafi)
  Future<void> saveMadhab(int madhabId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_madhabKey, madhabId);
  }

  /// Obtiene el Madhab seleccionado
  Future<int> getMadhab() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_madhabKey) ?? 0; // Default: Shafi
  }

  // ==================== NOTIFICATIONS ====================
  
  /// Guarda si las notificaciones están habilitadas
  Future<void> saveNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, enabled);
  }

  /// Obtiene si las notificaciones están habilitadas
  Future<bool> getNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationsEnabledKey) ?? true;
  }

  // ==================== RESET ====================
  
  /// Restablece todas las preferencias a los valores por defecto
  Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
