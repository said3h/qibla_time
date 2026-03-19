import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _themePreferenceKey = 'app_theme';

class ThemeController extends StateNotifier<String> {
  ThemeController() : super('dark') {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString(_themePreferenceKey) ?? 'dark';
  }

  Future<void> setTheme(String themeName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themePreferenceKey, themeName);
    state = themeName;
  }
}

final themeControllerProvider =
    StateNotifierProvider<ThemeController, String>((ref) {
  return ThemeController();
});
