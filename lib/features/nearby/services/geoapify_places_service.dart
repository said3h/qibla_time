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

    final verifiedCategories = switch (category) {
      NearbyPlaceCategory.halalRestaurant =>
        'catering.restaurant,catering.fast_food,catering.cafe',
      NearbyPlaceCategory.halalButcher => 'commercial.food_and_drink.butcher',
      NearbyPlaceCategory.mosque => throw StateError('unreachable'),
    };
    final candidateCategories = switch (category) {
      NearbyPlaceCategory.halalRestaurant =>
        'catering.fast_food.kebab,catering.fast_food.pita',
      NearbyPlaceCategory.halalButcher => 'commercial.food_and_drink.butcher',
      NearbyPlaceCategory.mosque => throw StateError('unreachable'),
    };

    final responses = await Future.wait([
      _fetchQuery(
        categories: verifiedCategories,
        condition: 'halal',
        category: category,
        latitude: latitude,
        longitude: longitude,
        radiusMeters: radiusMeters,
        fallbackVerification: HalalVerificationStatus.verified,
      ),
      _fetchQuery(
        categories: candidateCategories,
        category: category,
        latitude: latitude,
        longitude: longitude,
        radiusMeters: radiusMeters,
        fallbackVerification: HalalVerificationStatus.possible,
      ),
    ]);
    final successful = responses.where((response) => response.error == null);
    if (successful.isEmpty) throw responses.first.error!;

    final byId = <String, NearbyPlace>{};
    for (final response in responses) {
      for (final place in response.places) {
        final existing = byId[place.id];
        if (existing == null ||
            place.halalVerification == HalalVerificationStatus.verified) {
          byId[place.id] = place;
        }
      }
    }
    return byId.values.toList();
  }

  Future<_GeoapifyQueryResult> _fetchQuery({
    required String categories,
    String? condition,
    required NearbyPlaceCategory category,
    required double latitude,
    required double longitude,
    required int radiusMeters,
    required HalalVerificationStatus fallbackVerification,
  }) async {
    final uri = _endpoint.replace(
      queryParameters: {
        'categories': categories,
        if (condition != null) 'conditions': condition,
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
      return _GeoapifyQueryResult(
        places: _parseResponse(
          response.body,
          category,
          fallbackVerification,
        ),
      );
    } on TimeoutException {
      return const _GeoapifyQueryResult(
        error: GeoapifyPlacesException('Geoapify request timed out'),
      );
    } on FormatException {
      return const _GeoapifyQueryResult(
        error: GeoapifyPlacesException('Geoapify returned invalid JSON'),
      );
    } on GeoapifyPlacesException catch (error) {
      return _GeoapifyQueryResult(error: error);
    } on http.ClientException catch (error) {
      return _GeoapifyQueryResult(
        error: GeoapifyPlacesException('Geoapify network error: $error'),
      );
    } catch (error) {
      return _GeoapifyQueryResult(
        error: GeoapifyPlacesException(
          'Geoapify response error: ${error.runtimeType}',
        ),
      );
    }
  }

  List<NearbyPlace> _parseResponse(
    String body,
    NearbyPlaceCategory category,
    HalalVerificationStatus fallbackVerification,
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
          final conditions = (properties['conditions'] as List<dynamic>?)
                  ?.map((value) => value.toString())
                  .toList() ??
              const <String>[];
          final verification = [...categories, ...conditions].any(
            (value) => value == 'halal' || value.startsWith('halal.'),
          )
              ? HalalVerificationStatus.verified
              : fallbackVerification;
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
            halalVerification: verification,
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

class _GeoapifyQueryResult {
  const _GeoapifyQueryResult({
    this.places = const <NearbyPlace>[],
    this.error,
  });

  final List<NearbyPlace> places;
  final GeoapifyPlacesException? error;
}

class GeoapifyPlacesException implements Exception {
  const GeoapifyPlacesException(this.message);

  final String message;

  @override
  String toString() => 'GeoapifyPlacesException: $message';
}
