import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

@immutable
class AccessibilitySettings {
  const AccessibilitySettings({
    required this.fontScale,
    required this.highContrast,
    required this.useSystemBoldText,
  });

  final double fontScale;
  final bool highContrast;
  final bool useSystemBoldText;

  AccessibilitySettings copyWith({
    double? fontScale,
    bool? highContrast,
    bool? useSystemBoldText,
  }) {
    return AccessibilitySettings(
      fontScale: fontScale ?? this.fontScale,
      highContrast: highContrast ?? this.highContrast,
      useSystemBoldText: useSystemBoldText ?? this.useSystemBoldText,
    );
  }

  static const defaults = AccessibilitySettings(
    fontScale: 1.0,
    highContrast: false,
    useSystemBoldText: true,
  );
}

class AccessibilityController extends StateNotifier<AccessibilitySettings> {
  AccessibilityController() : super(AccessibilitySettings.defaults) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = AccessibilitySettings(
      fontScale: prefs.getDouble(AppConstants.keyAccessibilityFontScale) ?? 1.0,
      highContrast: prefs.getBool(AppConstants.keyAccessibilityHighContrast) ?? false,
      useSystemBoldText: prefs.getBool(AppConstants.keyAccessibilityUseSystemBold) ?? true,
    );
  }

  Future<void> setFontScale(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(AppConstants.keyAccessibilityFontScale, value);
    state = state.copyWith(fontScale: value);
  }

  Future<void> setHighContrast(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyAccessibilityHighContrast, value);
    state = state.copyWith(highContrast: value);
  }

  Future<void> setUseSystemBoldText(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyAccessibilityUseSystemBold, value);
    state = state.copyWith(useSystemBoldText: value);
  }

  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keyAccessibilityFontScale);
    await prefs.remove(AppConstants.keyAccessibilityHighContrast);
    await prefs.remove(AppConstants.keyAccessibilityUseSystemBold);
    state = AccessibilitySettings.defaults;
  }
}

final accessibilityControllerProvider =
    StateNotifierProvider<AccessibilityController, AccessibilitySettings>((ref) {
  return AccessibilityController();
});
