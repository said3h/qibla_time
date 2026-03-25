import 'dart:convert';

import '../../domain/entities/cached_prayer_schedule.dart';
import '../../domain/entities/prayer_location.dart';
import '../../domain/entities/prayer_schedule.dart';

class PrayerCacheEntryModel {
  const PrayerCacheEntryModel({
    required this.key,
    required this.location,
    required this.schedule,
    required this.validUntil,
  });

  final String key;
  final PrayerLocation location;
  final PrayerSchedule schedule;
  final DateTime validUntil;

  factory PrayerCacheEntryModel.fromJson(String key, String raw) {
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final times = decoded['times'] as Map<String, dynamic>;
    return PrayerCacheEntryModel(
      key: key,
      location: PrayerLocation(
        latitude: (decoded['lat'] as num).toDouble(),
        longitude: (decoded['lng'] as num).toDouble(),
      ),
      schedule: PrayerSchedule(
        date: DateTime.parse(decoded['date'] as String),
        fajr: DateTime.parse(times['fajr'] as String),
        dhuhr: DateTime.parse(times['dhuhr'] as String),
        asr: DateTime.parse(times['asr'] as String),
        maghrib: DateTime.parse(times['maghrib'] as String),
        isha: DateTime.parse(times['isha'] as String),
      ),
      validUntil: DateTime.parse(decoded['validUntil'] as String),
    );
  }

  CachedPrayerSchedule toEntity() {
    return CachedPrayerSchedule(
      key: key,
      location: location,
      schedule: schedule,
      validUntil: validUntil,
    );
  }

  String toJsonString() {
    return jsonEncode({
      'lat': location.latitude,
      'lng': location.longitude,
      'date': schedule.date.toIso8601String(),
      'validUntil': validUntil.toIso8601String(),
      'times': {
        'fajr': schedule.fajr.toIso8601String(),
        'dhuhr': schedule.dhuhr.toIso8601String(),
        'asr': schedule.asr.toIso8601String(),
        'maghrib': schedule.maghrib.toIso8601String(),
        'isha': schedule.isha.toIso8601String(),
      },
    });
  }
}
