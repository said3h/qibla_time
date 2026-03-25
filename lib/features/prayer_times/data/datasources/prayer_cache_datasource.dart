import 'package:hive/hive.dart';

import '../../../../core/services/storage_service.dart';
import '../../domain/entities/cached_prayer_schedule.dart';
import '../../domain/entities/prayer_cache_status.dart';
import '../../domain/entities/prayer_location.dart';
import '../../domain/entities/prayer_schedule.dart';
import '../models/prayer_cache_entry_model.dart';

class PrayerCacheDataSource {
  Box get _box => Hive.box(StorageService.prayerCacheBox);

  String buildKey(PrayerLocation location, DateTime date) {
    return 'prayers_${location.latitude.toStringAsFixed(2)}_${location.longitude.toStringAsFixed(2)}_${date.year}-${date.month}-${date.day}';
  }

  Future<void> save({
    required PrayerLocation location,
    required PrayerSchedule schedule,
  }) async {
    final date = schedule.date;
    final entry = PrayerCacheEntryModel(
      key: buildKey(location, date),
      location: location,
      schedule: schedule,
      validUntil: DateTime(date.year, date.month, date.day, 23, 59, 59)
          .add(const Duration(hours: 24)),
    );
    await _box.put(entry.key, entry.toJsonString());
  }

  Future<CachedPrayerSchedule?> getFor(
    PrayerLocation location,
    DateTime date,
  ) async {
    final key = buildKey(location, date);
    final raw = _box.get(key);
    if (raw is! String) {
      return null;
    }
    return PrayerCacheEntryModel.fromJson(key, raw).toEntity();
  }

  Future<List<CachedPrayerSchedule>> getAll() async {
    final entries = <CachedPrayerSchedule>[];
    for (final key in _box.keys) {
      final raw = _box.get(key);
      if (key is String && raw is String) {
        entries.add(PrayerCacheEntryModel.fromJson(key, raw).toEntity());
      }
    }
    return entries;
  }

  Future<void> deleteAll(List<String> keys) async {
    await _box.deleteAll(keys);
  }

  PrayerCacheStatus getStatus() {
    DateTime? validUntil;
    for (final value in _box.values) {
      if (value is! String) {
        continue;
      }
      final parsed = PrayerCacheEntryModel.fromJson('', value);
      if (validUntil == null || parsed.validUntil.isAfter(validUntil)) {
        validUntil = parsed.validUntil;
      }
    }
    return PrayerCacheStatus(entryCount: _box.length, validUntil: validUntil);
  }

  Future<void> clear() async {
    await _box.clear();
  }
}
