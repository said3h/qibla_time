import 'dart:convert';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import 'storage_service.dart';
import '../../features/hafiz/services/hafiz_service.dart';

class CloudSyncSnapshot {
  const CloudSyncSnapshot({
    required this.deviceId,
    required this.exportedAt,
    required this.payload,
  });

  final String deviceId;
  final DateTime exportedAt;
  final Map<String, dynamic> payload;

  String toJsonString() {
    return jsonEncode({
      'deviceId': deviceId,
      'exportedAt': exportedAt.toIso8601String(),
      'payload': payload,
    });
  }
}

class CloudSyncService {
  Box get _syncBox => Hive.box(StorageService.syncBox);

  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.keyCloudBackupEnabled) ?? false;
  }

  Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyCloudBackupEnabled, value);
  }

  Future<bool> isWifiOnly() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.keyCloudWifiOnly) ?? true;
  }

  Future<void> setWifiOnly(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyCloudWifiOnly, value);
  }

  Future<DateTime?> getLastBackup() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(AppConstants.keyCloudLastBackup);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  Future<String> getDeviceId() async {
    final existing = _syncBox.get('device_id');
    if (existing is String && existing.isNotEmpty) return existing;
    final random = Random();
    final value = 'anon-${DateTime.now().millisecondsSinceEpoch}-${random.nextInt(9999)}';
    await _syncBox.put('device_id', value);
    return value;
  }

  Future<CloudSyncSnapshot> createBackupSnapshot(HafizService hafizService) async {
    final prefs = await SharedPreferences.getInstance();
    final prefPayload = <String, dynamic>{};
    for (final key in prefs.getKeys()) {
      prefPayload[key] = prefs.get(key);
    }
    final hafiz = hafizService.exportSnapshot();
    final snapshot = CloudSyncSnapshot(
      deviceId: await getDeviceId(),
      exportedAt: DateTime.now(),
      payload: {
        'preferences': prefPayload,
        'hafiz': hafiz,
      },
    );
    await prefs.setString(AppConstants.keyCloudLastBackup, snapshot.exportedAt.toIso8601String());
    await _syncBox.put('last_snapshot', snapshot.toJsonString());
    return snapshot;
  }

  Future<void> restoreFromJson(HafizService hafizService, String rawJson) async {
    final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
    final payload = decoded['payload'] as Map<String, dynamic>;
    final prefsPayload = payload['preferences'] as Map<String, dynamic>? ?? {};
    final prefs = await SharedPreferences.getInstance();
    for (final entry in prefsPayload.entries) {
      final value = entry.value;
      if (value is bool) {
        await prefs.setBool(entry.key, value);
      } else if (value is int) {
        await prefs.setInt(entry.key, value);
      } else if (value is double) {
        await prefs.setDouble(entry.key, value);
      } else if (value is String) {
        await prefs.setString(entry.key, value);
      } else if (value is List) {
        await prefs.setStringList(entry.key, value.map((item) => item.toString()).toList());
      }
    }
    final hafizPayload = payload['hafiz'] as Map<String, dynamic>? ?? {};
    await hafizService.restoreSnapshot(hafizPayload);
  }
}

final cloudSyncServiceProvider = Provider<CloudSyncService>((ref) => CloudSyncService());
