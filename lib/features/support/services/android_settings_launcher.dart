import 'dart:io';

import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class AndroidSettingsLauncher {
  AndroidSettingsLauncher._();

  static const _channel = MethodChannel('com.qiblatime/android_settings');

  static Future<void> openNotificationSettings() async {
    await _openAndroidSettings('openNotificationSettings');
  }

  static Future<void> openExactAlarmSettings() async {
    await _openAndroidSettings('openExactAlarmSettings');
  }

  static Future<void> openBatterySettings({String? manufacturer}) async {
    await _openAndroidSettings(
      'openBatterySettings',
      arguments: {'manufacturer': manufacturer ?? ''},
    );
  }

  static Future<void> _openAndroidSettings(
    String method, {
    Object? arguments,
  }) async {
    if (!Platform.isAndroid) {
      await openAppSettings();
      return;
    }

    try {
      final opened = await _channel.invokeMethod<bool>(method, arguments);
      if (opened == true) return;
    } on PlatformException {
      // Fall through to the universal app settings page.
    } on MissingPluginException {
      // Useful in tests and non-Android builds.
    }

    await openAppSettings();
  }
}
