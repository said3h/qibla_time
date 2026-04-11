import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PeriodModeService {
  static const preferenceKey = 'period_mode_enabled';

  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(preferenceKey) ?? false;
  }

  Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(preferenceKey, value);
  }
}

final periodModeServiceProvider = Provider<PeriodModeService>((ref) {
  return PeriodModeService();
});

final periodModeEnabledProvider = FutureProvider<bool>((ref) async {
  return ref.watch(periodModeServiceProvider).isEnabled();
});
