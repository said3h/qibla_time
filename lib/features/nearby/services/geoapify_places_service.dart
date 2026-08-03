import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/nearby_place.dart';

class GeoapifyPlacesService {
  GeoapifyPlacesService({
    String apiKey = const String.fromEnvironment('GEOAPIFY_API_KEY'),
    http.Client? client,
    Uri? endpoint,
    this.timeout = const Duration(seconds: 20),
  })  : _apiKey = apiKey.trim(),
        _client = client ?? http.Client(),
        _endpoint = endpoint ?? Uri.parse('https://api.geoapify.com/v2/places');

  final String _apiKey;
  final http.Client _client;
  final Uri _endpoint;
  final Duration timeout;

  bool get isConfigured => _apiKey.isNotEmpty;

  Future<List<NearbyPlace>> fetchPlaces({
    required NearbyPlaceCategory category,
    required double latitude,
    required double longitude,
    required int radiusMeters,
  }) async {
    if (!isConfigured) {
      throw const GeoapifyPlacesException('Geoapify API key is not configured');
    }
    if (category == NearbyPlaceCategory.mosque) {
      throw const GeoapifyPlacesException(
        'Mosque searches remain on the OpenStreetMap provider',
      );
    }

    final categories = switch (category) {
      NearbyPlaceCategory.halalRestaurant =>
        'catering.restaurant,catering.fast_food,catering.cafe',
      NearbyPlaceCategory.halalButcher => 'commercial.food_and_drink.butcher',
      NearbyPlaceCategory.mosque => throw StateError('unreachable'),
    };
    final uri = _endpoint.replace(
      queryParameters: {
        'categories': categories,
        'conditions': 'halal',
        'filter': 'circle:$longitude,$latitude,$radiusMeters',
        'bias': 'proximity:$longitude,$latitude',
        'limit': '100',
        'apiKey': _apiKey,
      },
    );

    try {
      final response = await _client.get(
        uri,
        headers: const {
          'Accept': 'application/json',
          'User-Agent': 'QiblaTime/1.6.0',
        },
      ).timeout(timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw GeoapifyPlacesException(
          'Geoapify returned HTTP ${response.statusCode}',
        );
      }
      return _parseResponse(response.body, category);
    } on TimeoutException {
      throw const GeoapifyPlacesException('Geoapify request timed out');
    } on FormatException {
      throw const GeoapifyPlacesException('Geoapify returned invalid JSON');
    } on http.ClientException catch (error) {
      throw GeoapifyPlacesException('Geoapify network error: $error');
    }
  }

  List<NearbyPlace> _parseResponse(
    String body,
    NearbyPlaceCategory category,
  ) {
    final decoded = jsonDecode(body) as Map<String, dynamic>;
    final features = decoded['features'] as List<dynamic>? ?? const [];
    return features
        .map((feature) {
          final item = feature as Map<String, dynamic>;
          final properties =
              item['properties'] as Map<String, dynamic>? ?? const {};
          final geometry =
              item['geometry'] as Map<String, dynamic>? ?? const {};
          final coordinates = geometry['coordinates'] as List<dynamic>?;
          final latitude = _number(properties['lat']) ??
              (coordinates != null && coordinates.length > 1
                  ? _number(coordinates[1])
                  : null);
          final longitude = _number(properties['lon']) ??
              (coordinates != null && coordinates.isNotEmpty
                  ? _number(coordinates[0])
                  : null);
          if (latitude == null || longitude == null) return null;

          final contact = properties['contact'] as Map<String, dynamic>?;
          final openingHours = properties['opening_hours'];
          final categories = (properties['categories'] as List<dynamic>?)
                  ?.map((value) => value.toString())
                  .toList() ??
              const <String>[];
          final placeId = properties['place_id']?.toString() ??
              '${latitude.toStringAsFixed(6)},${longitude.toStringAsFixed(6)}';

          return NearbyPlace(
            id: 'geoapify/$placeId',
            category: category,
            latitude: latitude,
            longitude: longitude,
            source: 'Geoapify / OpenStreetMap',
            name: _text(properties['name']),
            address: _text(properties['formatted']),
            phone: _text(contact?['phone'] ?? properties['phone']),
            website: _text(contact?['website'] ?? properties['website']),
            openingHours: _text(
              openingHours is Map<String, dynamic>
                  ? openingHours['text'] ?? openingHours['raw']
                  : openingHours,
            ),
            wheelchair: _text(properties['wheelchair']),
            sourceTags: {
              if (categories.isNotEmpty) 'categories': categories.join(','),
              if (properties['conditions'] != null)
                'conditions': properties['conditions'].toString(),
            },
          );
        })
        .whereType<NearbyPlace>()
        .toList();
  }

  double? _number(Object? value) => value is num ? value.toDouble() : null;

  String? _text(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }
}

class GeoapifyPlacesException implements Exception {
  const GeoapifyPlacesException(this.message);

  final String message;

  @override
  String toString() => 'GeoapifyPlacesException: $message';
}
