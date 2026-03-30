import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_theme.dart';

const _themePreferenceKey = 'app_theme';

class ThemeController extends StateNotifier<String> {
  ThemeController() : super('dark') {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeName = prefs.getString(_themePreferenceKey) ?? 'dark';
    QiblaThemes.currentName = themeName;
    state = themeName;
  }

  Future<void> setTheme(String themeName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themePreferenceKey, themeName);
    QiblaThemes.currentName = themeName;
    state = themeName;
  }
}

final themeControllerProvider =
    StateNotifierProvider<ThemeController, String>((ref) {
  return ThemeController();
});
