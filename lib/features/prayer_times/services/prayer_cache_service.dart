import 'dart:convert';

import 'package:adhan/adhan.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';

import '../../../core/services/storage_service.dart';

class PrayerCacheStatus {
  const PrayerCacheStatus({
    required this.entryCount,
    required this.validUntil,
  });

  final int entryCount;
  final DateTime? validUntil;
}

class PrayerCacheService {
  Box get _box => Hive.box(StorageService.prayerCacheBox);

  String buildKey(Position position, DateTime date) {
    return 'prayers_${position.latitude.toStringAsFixed(2)}_${position.longitude.toStringAsFixed(2)}_${date.year}-${date.month}-${date.day}';
  }

  Future<void> storePrayerTimes({
    required Position position,
    required DateTime date,
    required PrayerTimes prayerTimes,
  }) async {
    final key = buildKey(position, date);
    final payload = {
      'lat': position.latitude,
      'lng': position.longitude,
      'date': date.toIso8601String(),
      'validUntil': DateTime(date.year, date.month, date.day, 23, 59, 59)
          .add(const Duration(hours: 24))
          .toIso8601String(),
      'times': {
        'fajr': prayerTimes.fajr.toIso8601String(),
        'dhuhr': prayerTimes.dhuhr.toIso8601String(),
        'asr': prayerTimes.asr.toIso8601String(),
        'maghrib': prayerTimes.maghrib.toIso8601String(),
        'isha': prayerTimes.isha.toIso8601String(),
      },
    };
    await _box.put(key, jsonEncode(payload));
  }

  PrayerCacheStatus getStatus() {
    DateTime? validUntil;
    for (final value in _box.values) {
      if (value is! String) continue;
      final decoded = jsonDecode(value) as Map<String, dynamic>;
      final parsed = DateTime.tryParse(decoded['validUntil'] as String? ?? '');
      if (parsed != null && (validUntil == null || parsed.isAfter(validUntil))) {
        validUntil = parsed;
      }
    }
    return PrayerCacheStatus(entryCount: _box.length, validUntil: validUntil);
  }

  Future<void> clear() async {
    await _box.clear();
  }

  Future<void> invalidateIfFarFrom(Position position, {double kmThreshold = 50}) async {
    final keysToDelete = <dynamic>[];
    for (final key in _box.keys) {
      final value = _box.get(key);
      if (value is! String) continue;
      final decoded = jsonDecode(value) as Map<String, dynamic>;
      final lat = (decoded['lat'] as num?)?.toDouble();
      final lng = (decoded['lng'] as num?)?.toDouble();
      if (lat == null || lng == null) continue;
      final distanceMeters = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        lat,
        lng,
      );
      if (distanceMeters > kmThreshold * 1000) {
        keysToDelete.add(key);
      }
    }
    await _box.deleteAll(keysToDelete);
  }
}

final prayerCacheServiceProvider = Provider<PrayerCacheService>((ref) {
  return PrayerCacheService();
});

final prayerCacheStatusProvider = Provider<PrayerCacheStatus>((ref) {
  return ref.watch(prayerCacheServiceProvider).getStatus();
});
