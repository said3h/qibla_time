import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:qibla_time/features/nearby/models/nearby_place.dart';
import 'package:qibla_time/features/nearby/services/geoapify_places_service.dart';

void main() {
  test('requests halal restaurants around the requested coordinates', () async {
    late Uri requestedUri;
    final service = GeoapifyPlacesService(
      apiKey: 'test-key',
      client: MockClient((request) async {
        requestedUri = request.url;
        return http.Response(_restaurantResponse, 200);
      }),
    );

    final places = await service.fetchPlaces(
      category: NearbyPlaceCategory.halalRestaurant,
      latitude: 40.4168,
      longitude: -3.7038,
      radiusMeters: 10000,
    );

    expect(
      requestedUri.queryParameters['categories'],
      'catering.restaurant,catering.fast_food,catering.cafe',
    );
    expect(requestedUri.queryParameters['conditions'], 'halal');
    expect(
      requestedUri.queryParameters['filter'],
      'circle:-3.7038,40.4168,10000',
    );
    expect(requestedUri.queryParameters['apiKey'], 'test-key');
    expect(places, hasLength(1));
    expect(places.single.name, 'Halal Madrid');
    expect(places.single.address, 'Calle Mayor 1, Madrid');
    expect(places.single.source, 'Geoapify / OpenStreetMap');
    expect(places.single.category, NearbyPlaceCategory.halalRestaurant);
  });

  test('uses the documented butcher category', () async {
    late Uri requestedUri;
    final service = GeoapifyPlacesService(
      apiKey: 'test-key',
      client: MockClient((request) async {
        requestedUri = request.url;
        return http.Response('{"type":"FeatureCollection","features":[]}', 200);
      }),
    );

    final places = await service.fetchPlaces(
      category: NearbyPlaceCategory.halalButcher,
      latitude: 40.4168,
      longitude: -3.7038,
      radiusMeters: 5000,
    );

    expect(
      requestedUri.queryParameters['categories'],
      'commercial.food_and_drink.butcher',
    );
    expect(places, isEmpty);
  });

  test('rejects requests when the API key is not configured', () async {
    final service = GeoapifyPlacesService(apiKey: '');

    expect(
      () => service.fetchPlaces(
        category: NearbyPlaceCategory.halalRestaurant,
        latitude: 40.4168,
        longitude: -3.7038,
        radiusMeters: 5000,
      ),
      throwsA(isA<GeoapifyPlacesException>()),
    );
  });

  test('reports non-success HTTP responses without exposing the key', () async {
    final service = GeoapifyPlacesService(
      apiKey: 'secret-test-key',
      client: MockClient((_) async => http.Response('quota exceeded', 429)),
    );

    try {
      await service.fetchPlaces(
        category: NearbyPlaceCategory.halalRestaurant,
        latitude: 40.4168,
        longitude: -3.7038,
        radiusMeters: 5000,
      );
      fail('Expected GeoapifyPlacesException');
    } on GeoapifyPlacesException catch (error) {
      expect(error.message, contains('HTTP 429'));
      expect(error.message, isNot(contains('secret-test-key')));
    }
  });
}

final _restaurantResponse = jsonEncode({
  'type': 'FeatureCollection',
  'features': [
    {
      'type': 'Feature',
      'properties': {
        'place_id': 'restaurant-1',
        'name': 'Halal Madrid',
        'formatted': 'Calle Mayor 1, Madrid',
        'lat': 40.417,
        'lon': -3.704,
        'categories': ['catering.restaurant'],
        'conditions': ['halal'],
        'contact': {
          'phone': '+34123456789',
          'website': 'https://example.com',
        },
      },
      'geometry': {
        'type': 'Point',
        'coordinates': [-3.704, 40.417],
      },
    },
  ],
});
