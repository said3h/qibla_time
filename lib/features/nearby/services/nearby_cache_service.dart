import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/nearby_place.dart';
import '../models/nearby_place_search.dart';
import 'nearby_distance_service.dart';

class NearbyCacheService {
  static const formatVersion = 4;

  NearbyCacheService({
    SharedPreferences? prefs,
    NearbyDistanceService distanceService = const NearbyDistanceService(),
    this.ttl = const Duration(hours: 12),
    this.movementThresholdMeters = 750,
  })  : _prefs = prefs,
        _distanceService = distanceService;

  final SharedPreferences? _prefs;
  final NearbyDistanceService _distanceService;
  final Duration ttl;
  final double movementThresholdMeters;

  Future<NearbyCacheEntry?> read(NearbyPlaceSearch search) async {
    final prefs = await _preferences();
    final raw = prefs.getString(_key(search.category, search.radiusMeters));
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final entry = NearbyCacheEntry.fromJson(decoded);
      if (entry.formatVersion != formatVersion) return null;
      if (entry.category != search.category) return null;
      final age = DateTime.now().difference(entry.createdAt);
      if (age > ttl) return null;
      if (entry.radiusMeters != search.radiusMeters) return null;

      final movement = _distanceService.distanceMeters(
        fromLatitude: entry.originLatitude,
        fromLongitude: entry.originLongitude,
        toLatitude: search.origin.latitude,
        toLongitude: search.origin.longitude,
      );
      if (movement > movementThresholdMeters) return null;

      return entry;
    } catch (_) {
      return null;
    }
  }

  Future<void> write({
    required NearbyPlaceSearch search,
    required List<NearbyPlace> places,
  }) async {
    final prefs = await _preferences();
    final entry = NearbyCacheEntry(
      formatVersion: formatVersion,
      createdAt: DateTime.now(),
      category: search.category,
      originLatitude: search.origin.latitude,
      originLongitude: search.origin.longitude,
      radiusMeters: search.radiusMeters,
      places: places,
    );
    await prefs.setString(
      _key(search.category, search.radiusMeters),
      jsonEncode(entry.toJson()),
    );
  }

  Future<SharedPreferences> _preferences() async {
    final prefs = _prefs;
    if (prefs != null) return prefs;
    return SharedPreferences.getInstance();
  }

  String _key(NearbyPlaceCategory category, int radiusMeters) {
    return 'nearby:v$formatVersion:${category.name}:$radiusMeters';
  }
}

class NearbyCacheEntry {
  const NearbyCacheEntry({
    required this.formatVersion,
    required this.createdAt,
    required this.category,
    required this.originLatitude,
    required this.originLongitude,
    required this.radiusMeters,
    required this.places,
  });

  final int formatVersion;
  final DateTime createdAt;
  final NearbyPlaceCategory category;
  final double originLatitude;
  final double originLongitude;
  final int radiusMeters;
  final List<NearbyPlace> places;

  Map<String, dynamic> toJson() {
    return {
      'createdAt': createdAt.toIso8601String(),
      'formatVersion': formatVersion,
      'category': category.name,
      'originLatitude': originLatitude,
      'originLongitude': originLongitude,
      'radiusMeters': radiusMeters,
      'places': places.map((place) => place.toJson()).toList(),
    };
  }

  factory NearbyCacheEntry.fromJson(Map<String, dynamic> json) {
    return NearbyCacheEntry(
      formatVersion: (json['formatVersion'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      category: NearbyPlaceCategory.values.firstWhere(
        (category) => category.name == json['category'],
        orElse: () => NearbyPlaceCategory.mosque,
      ),
      originLatitude: (json['originLatitude'] as num).toDouble(),
      originLongitude: (json['originLongitude'] as num).toDouble(),
      radiusMeters: (json['radiusMeters'] as num).toInt(),
      places: (json['places'] as List<dynamic>? ?? const <dynamic>[])
          .map((item) => NearbyPlace.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
