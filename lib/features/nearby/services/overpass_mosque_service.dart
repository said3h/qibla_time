import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/services/logger_service.dart';
import '../models/nearby_place.dart';

class OverpassMosqueService {
  OverpassMosqueService({
    http.Client? client,
    Uri? endpoint,
    this.timeout = const Duration(seconds: 12),
    this.maxAttempts = 2,
  })  : _client = client ?? http.Client(),
        endpoint =
            endpoint ?? Uri.parse('https://overpass-api.de/api/interpreter');

  final http.Client _client;
  final Uri endpoint;
  final Duration timeout;
  final int maxAttempts;

  Future<List<NearbyPlace>> fetchMosques({
    required double latitude,
    required double longitude,
    required int radiusMeters,
  }) async {
    return fetchPlaces(
      category: NearbyPlaceCategory.mosque,
      latitude: latitude,
      longitude: longitude,
      radiusMeters: radiusMeters,
    );
  }

  Future<List<NearbyPlace>> fetchHalalRestaurants({
    required double latitude,
    required double longitude,
    required int radiusMeters,
  }) {
    return fetchPlaces(
      category: NearbyPlaceCategory.halalRestaurant,
      latitude: latitude,
      longitude: longitude,
      radiusMeters: radiusMeters,
    );
  }

  Future<List<NearbyPlace>> fetchHalalButchers({
    required double latitude,
    required double longitude,
    required int radiusMeters,
  }) {
    return fetchPlaces(
      category: NearbyPlaceCategory.halalButcher,
      latitude: latitude,
      longitude: longitude,
      radiusMeters: radiusMeters,
    );
  }

  Future<List<NearbyPlace>> fetchPlaces({
    required NearbyPlaceCategory category,
    required double latitude,
    required double longitude,
    required int radiusMeters,
  }) async {
    final query = _buildQuery(
      category: category,
      latitude: latitude,
      longitude: longitude,
      radiusMeters: radiusMeters,
    );

    final response = await _postWithLimitedRetry(query);

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map<String, dynamic>) {
      throw const OverpassException('invalid_response');
    }

    final elements = decoded['elements'];
    if (elements is! List) {
      return const <NearbyPlace>[];
    }

    final places = <NearbyPlace>[];
    final seenOsmIds = <String>{};
    var acceptedBeforeDedupe = 0;
    for (final element in elements) {
      if (element is! Map<String, dynamic>) continue;
      final place = parseElement(element, category: category);
      if (place == null) continue;
      acceptedBeforeDedupe++;
      if (!seenOsmIds.add(place.id)) continue;
      if (places.any((existing) => _looksLikeSamePlace(existing, place))) {
        continue;
      }
      places.add(place);
    }
    if (kDebugMode) {
      AppLogger.info(
        'Nearby Overpass ${category.name}: raw=${elements.length}, '
        'accepted=$acceptedBeforeDedupe, deduped=${places.length}',
      );
    }
    return places;
  }

  Future<http.Response> _postWithLimitedRetry(String query) async {
    Object? lastError;
    final attempts = maxAttempts.clamp(1, 3);
    for (var attempt = 1; attempt <= attempts; attempt++) {
      try {
        final response = await _client.post(
          endpoint,
          headers: const {
            'Content-Type': 'application/x-www-form-urlencoded; charset=utf-8',
            'Accept': 'application/json',
            'User-Agent': 'QiblaTime/1.6.0 (support.qiblatime@gmail.com)',
          },
          body: {'data': query},
        ).timeout(timeout);
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return response;
        }
        final error = OverpassException('http_${response.statusCode}');
        if (!_shouldRetryStatus(response.statusCode) || attempt == attempts) {
          throw error;
        }
        lastError = error;
      } catch (error) {
        lastError = error;
        if (!_shouldRetryError(error) || attempt == attempts) rethrow;
      }
    }
    throw lastError ?? const OverpassException('request_failed');
  }

  bool _shouldRetryStatus(int statusCode) {
    return statusCode == 429 ||
        statusCode == 502 ||
        statusCode == 503 ||
        statusCode == 504;
  }

  bool _shouldRetryError(Object error) {
    return error is TimeoutException || error is http.ClientException;
  }

  NearbyPlace? parseElement(
    Map<String, dynamic> element, {
    NearbyPlaceCategory category = NearbyPlaceCategory.mosque,
  }) {
    final tags = (element['tags'] as Map<String, dynamic>?)
            ?.map((key, value) => MapEntry(key, value.toString())) ??
        const <String, String>{};
    if (!_matchesCategory(tags, category)) return null;

    final coordinates = _coordinatesFor(element);
    if (coordinates == null) return null;

    final type = element['type']?.toString() ?? 'osm';
    final id = element['id']?.toString() ?? _dedupeKeyFromTags(tags);
    return NearbyPlace(
      id: '$type/$id',
      category: category,
      latitude: coordinates.latitude,
      longitude: coordinates.longitude,
      source: 'OpenStreetMap',
      name: _readFirst(
        tags,
        const ['name', 'brand', 'operator', 'name:en', 'name:ar'],
      ),
      address: _addressFromTags(tags),
      phone: _readFirst(tags, const ['phone', 'contact:phone']),
      website: _readFirst(tags, const ['website', 'contact:website']),
      openingHours: _readFirst(tags, const ['opening_hours']),
      wheelchair: _readFirst(tags, const ['wheelchair']),
      sourceTags: _filteredTags(tags),
    );
  }

  static String _buildQuery({
    required NearbyPlaceCategory category,
    required double latitude,
    required double longitude,
    required int radiusMeters,
  }) {
    final lat = latitude.toStringAsFixed(6);
    final lng = longitude.toStringAsFixed(6);
    final radius = radiusMeters.clamp(1000, 50000);
    final selectors = switch (category) {
      NearbyPlaceCategory.mosque => '''
  node(around:$radius,$lat,$lng)["amenity"="place_of_worship"]["religion"="muslim"];
  way(around:$radius,$lat,$lng)["amenity"="place_of_worship"]["religion"="muslim"];
  relation(around:$radius,$lat,$lng)["amenity"="place_of_worship"]["religion"="muslim"];
  node(around:$radius,$lat,$lng)["building"="mosque"];
  way(around:$radius,$lat,$lng)["building"="mosque"];
  relation(around:$radius,$lat,$lng)["building"="mosque"];''',
      NearbyPlaceCategory.halalRestaurant => '''
  node(around:$radius,$lat,$lng)["amenity"~"^(restaurant|fast_food|cafe)\$"]["diet:halal"~"^(yes|only)\$",i];
  way(around:$radius,$lat,$lng)["amenity"~"^(restaurant|fast_food|cafe)\$"]["diet:halal"~"^(yes|only)\$",i];
  relation(around:$radius,$lat,$lng)["amenity"~"^(restaurant|fast_food|cafe)\$"]["diet:halal"~"^(yes|only)\$",i];
  node(around:$radius,$lat,$lng)["amenity"~"^(restaurant|fast_food|cafe)\$"]["halal"~"^(yes|only)\$",i];
  way(around:$radius,$lat,$lng)["amenity"~"^(restaurant|fast_food|cafe)\$"]["halal"~"^(yes|only)\$",i];
  relation(around:$radius,$lat,$lng)["amenity"~"^(restaurant|fast_food|cafe)\$"]["halal"~"^(yes|only)\$",i];
  node(around:$radius,$lat,$lng)["amenity"~"^(restaurant|fast_food|cafe)\$"]["certified:halal"~"^(yes|only)\$",i];
  way(around:$radius,$lat,$lng)["amenity"~"^(restaurant|fast_food|cafe)\$"]["certified:halal"~"^(yes|only)\$",i];
  relation(around:$radius,$lat,$lng)["amenity"~"^(restaurant|fast_food|cafe)\$"]["certified:halal"~"^(yes|only)\$",i];
  node(around:$radius,$lat,$lng)["amenity"~"^(restaurant|fast_food|cafe)\$"]["cuisine"~"(^|[;, ]+)halal([;, ]+|\$)",i];
  way(around:$radius,$lat,$lng)["amenity"~"^(restaurant|fast_food|cafe)\$"]["cuisine"~"(^|[;, ]+)halal([;, ]+|\$)",i];
  relation(around:$radius,$lat,$lng)["amenity"~"^(restaurant|fast_food|cafe)\$"]["cuisine"~"(^|[;, ]+)halal([;, ]+|\$)",i];
  node(around:$radius,$lat,$lng)["amenity"~"^(restaurant|fast_food|cafe)\$"]["name"~"halal",i];
  way(around:$radius,$lat,$lng)["amenity"~"^(restaurant|fast_food|cafe)\$"]["name"~"halal",i];
  relation(around:$radius,$lat,$lng)["amenity"~"^(restaurant|fast_food|cafe)\$"]["name"~"halal",i];''',
      NearbyPlaceCategory.halalButcher => '''
  node(around:$radius,$lat,$lng)["shop"="butcher"]["diet:halal"~"^(yes|only)\$",i];
  way(around:$radius,$lat,$lng)["shop"="butcher"]["diet:halal"~"^(yes|only)\$",i];
  relation(around:$radius,$lat,$lng)["shop"="butcher"]["diet:halal"~"^(yes|only)\$",i];
  node(around:$radius,$lat,$lng)["shop"="butcher"]["halal"~"^(yes|only)\$",i];
  way(around:$radius,$lat,$lng)["shop"="butcher"]["halal"~"^(yes|only)\$",i];
  relation(around:$radius,$lat,$lng)["shop"="butcher"]["halal"~"^(yes|only)\$",i];
  node(around:$radius,$lat,$lng)["shop"="butcher"]["certified:halal"~"^(yes|only)\$",i];
  way(around:$radius,$lat,$lng)["shop"="butcher"]["certified:halal"~"^(yes|only)\$",i];
  relation(around:$radius,$lat,$lng)["shop"="butcher"]["certified:halal"~"^(yes|only)\$",i];
  node(around:$radius,$lat,$lng)["shop"="butcher"]["butcher"~"^halal\$",i];
  way(around:$radius,$lat,$lng)["shop"="butcher"]["butcher"~"^halal\$",i];
  relation(around:$radius,$lat,$lng)["shop"="butcher"]["butcher"~"^halal\$",i];
  node(around:$radius,$lat,$lng)["shop"="butcher"]["name"~"halal",i];
  way(around:$radius,$lat,$lng)["shop"="butcher"]["name"~"halal",i];
  relation(around:$radius,$lat,$lng)["shop"="butcher"]["name"~"halal",i];''',
    };
    return '''
[out:json][timeout:12];
(
$selectors
);
out center tags;
''';
  }

  bool _matchesCategory(
    Map<String, String> tags,
    NearbyPlaceCategory category,
  ) {
    if (_isInactive(tags)) return false;
    return switch (category) {
      NearbyPlaceCategory.mosque => _isMuslimPlaceOfWorship(tags),
      NearbyPlaceCategory.halalRestaurant => _isHalalRestaurant(tags),
      NearbyPlaceCategory.halalButcher => _isHalalButcher(tags),
    };
  }

  bool _isHalalRestaurant(Map<String, String> tags) {
    const supportedAmenities = {'restaurant', 'fast_food', 'cafe'};
    return supportedAmenities.contains(tags['amenity']?.toLowerCase()) &&
        _isExplicitlyHalal(tags);
  }

  bool _isHalalButcher(Map<String, String> tags) {
    if (tags['shop']?.toLowerCase() != 'butcher') return false;
    return _isExplicitlyHalal(tags) ||
        tags['butcher']?.toLowerCase() == 'halal';
  }

  bool _isExplicitlyHalal(Map<String, String> tags) {
    if (_hasHalalDenial(tags)) return false;

    const directKeys = ['diet:halal', 'halal', 'certified:halal'];
    for (final key in directKeys) {
      final value = tags[key]?.toLowerCase();
      if (value == 'yes' || value == 'only') return true;
    }

    if (_hasHalalToken(tags['cuisine'])) return true;
    return _hasHalalToken(tags['name']);
  }

  bool _hasHalalDenial(Map<String, String> tags) {
    const directKeys = ['diet:halal', 'halal', 'certified:halal'];
    return directKeys.any((key) {
      final value = tags[key]?.toLowerCase();
      return value == 'no' || value == 'none' || value == 'false';
    });
  }

  bool _hasHalalToken(String? value) {
    if (value == null) return false;
    return RegExp(r'(^|[^a-z])halal([^a-z]|$)', caseSensitive: false)
        .hasMatch(value);
  }

  bool _isInactive(Map<String, String> tags) {
    return tags['disused']?.toLowerCase() == 'yes' ||
        tags['abandoned']?.toLowerCase() == 'yes' ||
        tags['historic']?.toLowerCase() == 'yes' ||
        tags['disused:amenity'] != null ||
        tags['abandoned:amenity'] != null ||
        tags['disused:shop'] != null ||
        tags['abandoned:shop'] != null;
  }

  bool _isMuslimPlaceOfWorship(Map<String, String> tags) {
    final religion = tags['religion']?.toLowerCase();
    final amenity = tags['amenity']?.toLowerCase();
    final building = tags['building']?.toLowerCase();

    if (amenity == 'place_of_worship' && religion == 'muslim') {
      return true;
    }

    if (building == 'mosque') {
      final incompatibleReligion = religion != null && religion != 'muslim';
      if (incompatibleReligion) return false;
      return !_isInactive(tags);
    }

    return false;
  }

  _Coordinates? _coordinatesFor(Map<String, dynamic> element) {
    final lat = (element['lat'] as num?)?.toDouble();
    final lon = (element['lon'] as num?)?.toDouble();
    if (lat != null && lon != null) {
      return _Coordinates(lat, lon);
    }

    final center = element['center'];
    if (center is Map<String, dynamic>) {
      final centerLat = (center['lat'] as num?)?.toDouble();
      final centerLon = (center['lon'] as num?)?.toDouble();
      if (centerLat != null && centerLon != null) {
        return _Coordinates(centerLat, centerLon);
      }
    }

    return null;
  }

  String? _addressFromTags(Map<String, String> tags) {
    final fullAddress = _readFirst(tags, const ['addr:full']);
    if (fullAddress != null) return fullAddress;

    final parts = [
      _joinStreetAndHouse(tags),
      tags['addr:city'],
      tags['addr:postcode'],
      tags['addr:country'],
    ].whereType<String>().where((value) => value.trim().isNotEmpty).toList();
    if (parts.isEmpty) return null;
    return parts.join(', ');
  }

  String? _joinStreetAndHouse(Map<String, String> tags) {
    final street = tags['addr:street'];
    final houseNumber = tags['addr:housenumber'];
    if (street == null && houseNumber == null) return null;
    return [street, houseNumber]
        .whereType<String>()
        .where((value) => value.trim().isNotEmpty)
        .join(' ');
  }

  String? _readFirst(Map<String, String> tags, List<String> keys) {
    for (final key in keys) {
      final value = tags[key]?.trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  Map<String, String> _filteredTags(Map<String, String> tags) {
    const allowed = {
      'amenity',
      'religion',
      'building',
      'denomination',
      'operator',
      'shop',
      'diet:halal',
      'halal',
      'certified:halal',
      'butcher',
      'cuisine',
      'brand',
    };
    return Map<String, String>.fromEntries(
      tags.entries.where((entry) => allowed.contains(entry.key)),
    );
  }

  bool _looksLikeSamePlace(NearbyPlace a, NearbyPlace b) {
    final aName = _normalizeName(a.name);
    final bName = _normalizeName(b.name);
    if (aName == null || bName == null || aName != bName) return false;

    final distance = _distanceMeters(
      a.latitude,
      a.longitude,
      b.latitude,
      b.longitude,
    );
    return distance <= 25;
  }

  String _dedupeKeyFromTags(Map<String, String> tags) {
    return '${tags['name'] ?? 'unnamed'}-${tags.hashCode}';
  }

  String? _normalizeName(String? value) {
    final normalized = value
        ?.toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\u0600-\u06ff]+'), ' ')
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
    if (normalized == null || normalized.isEmpty) return null;
    return normalized;
  }

  double _distanceMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const metersPerDegree = 111320.0;
    final avgLatRadians = ((lat1 + lat2) / 2) * math.pi / 180;
    final latMeters = (lat1 - lat2) * metersPerDegree;
    final lonMeters = (lon1 - lon2) * metersPerDegree * math.cos(avgLatRadians);
    return math.sqrt(latMeters * latMeters + lonMeters * lonMeters);
  }
}

class OverpassException implements Exception {
  const OverpassException(this.reason);

  final String reason;

  @override
  String toString() => 'OverpassException($reason)';
}

class _Coordinates {
  const _Coordinates(this.latitude, this.longitude);

  final double latitude;
  final double longitude;
}
