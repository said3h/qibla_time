import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:qibla_time/features/nearby/services/overpass_mosque_service.dart';
import 'package:qibla_time/features/nearby/models/nearby_place.dart';

void main() {
  test('parses a valid Overpass mosque response', () async {
    final service = OverpassMosqueService(
      client: MockClient((_) async => http.Response(
            jsonEncode({
              'elements': [
                {
                  'type': 'node',
                  'id': 1,
                  'lat': 38.345,
                  'lon': -0.49,
                  'tags': {
                    'amenity': 'place_of_worship',
                    'religion': 'muslim',
                    'name': 'Alicante Mosque',
                    'addr:street': 'Main Street',
                    'addr:housenumber': '12',
                    'phone': '+341234',
                    'website': 'https://example.org',
                    'opening_hours': 'Mo-Fr 10:00-20:00',
                    'wheelchair': 'yes',
                  },
                }
              ],
            }),
            200,
          )),
    );

    final places = await service.fetchMosques(
      latitude: 38.34,
      longitude: -0.48,
      radiusMeters: 5000,
    );

    expect(places, hasLength(1));
    expect(places.first.name, 'Alicante Mosque');
    expect(places.first.address, 'Main Street 12');
    expect(places.first.phone, '+341234');
    expect(places.first.website, 'https://example.org');
    expect(places.first.openingHours, 'Mo-Fr 10:00-20:00');
    expect(places.first.wheelchair, 'yes');
  });

  test('returns an empty list for an empty Overpass response', () async {
    final service = OverpassMosqueService(
      client: MockClient((_) async => http.Response(
            jsonEncode({'elements': []}),
            200,
          )),
    );

    final places = await service.fetchMosques(
      latitude: 0,
      longitude: 0,
      radiusMeters: 5000,
    );

    expect(places, isEmpty);
  });

  test('accepts only explicitly tagged halal restaurants', () async {
    final requestedBodies = <String>[];
    final service = OverpassMosqueService(
      client: MockClient((request) async {
        requestedBodies.add(request.body);
        return http.Response(
          jsonEncode({
            'elements': [
              _foodElement(
                id: 1,
                tags: {
                  'amenity': 'restaurant',
                  'diet:halal': 'yes',
                  'name': 'Verified Restaurant',
                },
              ),
              _foodElement(
                id: 2,
                tags: {
                  'amenity': 'fast_food',
                  'diet:halal': 'only',
                  'name': 'Halal Fast Food',
                },
              ),
              _foodElement(
                id: 3,
                tags: {
                  'amenity': 'cafe',
                  'halal': 'yes',
                  'name': 'Verified Cafe',
                },
              ),
              _foodElement(
                id: 4,
                tags: {
                  'amenity': 'restaurant',
                  'cuisine': 'turkish;halal',
                  'name': 'Cuisine Tagged Restaurant',
                },
              ),
              _foodElement(
                id: 5,
                tags: {
                  'amenity': 'restaurant',
                  'name': 'Halal Palace',
                },
              ),
              _foodElement(
                id: 6,
                tags: {
                  'amenity': 'restaurant',
                  'name': 'Unverified Restaurant',
                },
              ),
              _foodElement(
                id: 7,
                tags: {
                  'amenity': 'restaurant',
                  'diet:halal': 'no',
                  'name': 'Not Halal',
                },
              ),
            ],
          }),
          200,
        );
      }),
    );

    final places = await service.fetchHalalRestaurants(
      latitude: 38.34,
      longitude: -0.48,
      radiusMeters: 5000,
    );

    expect(places.map((place) => place.name), [
      'Verified Restaurant',
      'Halal Fast Food',
      'Verified Cafe',
      'Cuisine Tagged Restaurant',
      'Halal Palace',
    ]);
    expect(
      places.every(
        (place) => place.category == NearbyPlaceCategory.halalRestaurant,
      ),
      isTrue,
    );
    expect(requestedBodies.single, contains('diet%3Ahalal'));
    expect(
      Uri.decodeQueryComponent(requestedBodies.single),
      contains(
        'nwr["diet:halal"](around:5000,38.340000,-0.480000)',
      ),
    );
  });

  test('accepts documented halal butcher tags and rejects generic butchers',
      () async {
    final service = OverpassMosqueService(
      client: MockClient((_) async => http.Response(
            jsonEncode({
              'elements': [
                _foodElement(
                  id: 1,
                  tags: {
                    'shop': 'butcher',
                    'diet:halal': 'yes',
                    'name': 'Halal Meat',
                  },
                ),
                _foodElement(
                  id: 2,
                  tags: {
                    'shop': 'butcher',
                    'butcher': 'halal',
                    'name': 'Halal Butcher',
                  },
                ),
                _foodElement(
                  id: 3,
                  tags: {
                    'shop': 'butcher',
                    'halal': 'yes',
                    'name': 'Tagged Butcher',
                  },
                ),
                _foodElement(
                  id: 4,
                  tags: {
                    'shop': 'butcher',
                    'name': 'Carniceria Halal',
                  },
                ),
                _foodElement(
                  id: 5,
                  tags: {
                    'shop': 'butcher',
                    'name': 'Generic Butcher',
                  },
                ),
              ],
            }),
            200,
          )),
    );

    final places = await service.fetchHalalButchers(
      latitude: 38.34,
      longitude: -0.48,
      radiusMeters: 5000,
    );

    expect(places.map((place) => place.name), [
      'Halal Meat',
      'Halal Butcher',
      'Tagged Butcher',
      'Carniceria Halal',
    ]);
    expect(
      places.every(
        (place) => place.category == NearbyPlaceCategory.halalButcher,
      ),
      isTrue,
    );
  });

  test('rejects inactive halal businesses', () {
    final service = OverpassMosqueService();

    expect(
      service.parseElement(
        _foodElement(
          id: 1,
          tags: {
            'amenity': 'restaurant',
            'diet:halal': 'yes',
            'disused': 'yes',
          },
        ),
        category: NearbyPlaceCategory.halalRestaurant,
      ),
      isNull,
    );
  });

  test('ignores incomplete elements without coordinates', () {
    final service = OverpassMosqueService();

    final place = service.parseElement({
      'type': 'node',
      'id': 1,
      'tags': {
        'amenity': 'place_of_worship',
        'religion': 'muslim',
      },
    });

    expect(place, isNull);
  });

  test('deduplicates equivalent mosque elements', () async {
    final element = {
      'type': 'node',
      'id': 1,
      'lat': 38.345001,
      'lon': -0.490001,
      'tags': {
        'amenity': 'place_of_worship',
        'religion': 'muslim',
        'name': 'Central Mosque',
      },
    };
    final service = OverpassMosqueService(
      client: MockClient((_) async => http.Response(
            jsonEncode({
              'elements': [
                element,
                {
                  ...element,
                  'id': 2,
                  'lat': 38.345002,
                  'lon': -0.490002,
                },
              ],
            }),
            200,
          )),
    );

    final places = await service.fetchMosques(
      latitude: 38.34,
      longitude: -0.48,
      radiusMeters: 5000,
    );

    expect(places, hasLength(1));
  });

  test('does not merge different mosques that share a common name', () async {
    final service = OverpassMosqueService(
      client: MockClient((_) async => http.Response(
            jsonEncode({
              'elements': [
                _mosqueElement(id: 1, name: 'Central Mosque', lat: 38.3),
                _mosqueElement(id: 2, name: 'Central Mosque', lat: 39.3),
              ],
            }),
            200,
          )),
    );

    final places = await service.fetchMosques(
      latitude: 38.34,
      longitude: -0.48,
      radiusMeters: 50000,
    );

    expect(places, hasLength(2));
  });

  test('does not merge unnamed nearby mosques without reliable identity',
      () async {
    final service = OverpassMosqueService(
      client: MockClient((_) async => http.Response(
            jsonEncode({
              'elements': [
                _mosqueElement(id: 1, lat: 38.345001, lon: -0.490001),
                _mosqueElement(id: 2, lat: 38.345002, lon: -0.490002),
              ],
            }),
            200,
          )),
    );

    final places = await service.fetchMosques(
      latitude: 38.34,
      longitude: -0.48,
      radiusMeters: 5000,
    );

    expect(places, hasLength(2));
  });

  test('accepts only Muslim places of worship or mosque buildings', () {
    final service = OverpassMosqueService();

    expect(
      service.parseElement({
        'type': 'node',
        'id': 1,
        'lat': 1,
        'lon': 1,
        'tags': {
          'amenity': 'place_of_worship',
          'religion': 'christian',
        },
      }),
      isNull,
    );
    expect(
      service.parseElement({
        'type': 'node',
        'id': 2,
        'lat': 1,
        'lon': 1,
        'tags': {'building': 'mosque'},
      }),
      isNotNull,
    );
    expect(
      service.parseElement({
        'type': 'node',
        'id': 3,
        'lat': 1,
        'lon': 1,
        'tags': {'building': 'mosque', 'historic': 'yes'},
      }),
      isNull,
    );
  });

  test('surfaces network errors and timeouts', () async {
    final networkService = OverpassMosqueService(
      client: MockClient((_) async => throw http.ClientException('network')),
    );
    await expectLater(
      networkService.fetchMosques(
          latitude: 0, longitude: 0, radiusMeters: 5000),
      throwsException,
    );

    final timeoutService = OverpassMosqueService(
      timeout: const Duration(milliseconds: 1),
      client: MockClient((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return http.Response('{}', 200);
      }),
    );
    await expectLater(
      timeoutService.fetchMosques(
          latitude: 0, longitude: 0, radiusMeters: 5000),
      throwsA(isA<TimeoutException>()),
    );
  });

  test('retries a transient Overpass request failure once', () async {
    var attempts = 0;
    final service = OverpassMosqueService(
      client: MockClient((_) async {
        attempts++;
        if (attempts == 1) {
          throw http.ClientException('transient');
        }
        return http.Response(jsonEncode({'elements': []}), 200);
      }),
    );

    final places = await service.fetchMosques(
      latitude: 0,
      longitude: 0,
      radiusMeters: 5000,
    );

    expect(places, isEmpty);
    expect(attempts, 2);
  });

  test('retries HTTP 429 but not permanent HTTP 400', () async {
    var retryableAttempts = 0;
    final retryable = OverpassMosqueService(
      client: MockClient((_) async {
        retryableAttempts++;
        if (retryableAttempts == 1) {
          return http.Response('busy', 429);
        }
        return http.Response(jsonEncode({'elements': []}), 200);
      }),
    );

    expect(
      await retryable.fetchMosques(
          latitude: 0, longitude: 0, radiusMeters: 5000),
      isEmpty,
    );
    expect(retryableAttempts, 2);

    var permanentAttempts = 0;
    final permanent = OverpassMosqueService(
      client: MockClient((_) async {
        permanentAttempts++;
        return http.Response('bad query', 400);
      }),
    );

    await expectLater(
      permanent.fetchMosques(latitude: 0, longitude: 0, radiusMeters: 5000),
      throwsA(isA<OverpassException>()),
    );
    expect(permanentAttempts, 1);
  });

  test('switches to the fallback endpoint after a transient failure', () async {
    final requestedHosts = <String>[];
    final service = OverpassMosqueService(
      client: MockClient((request) async {
        requestedHosts.add(request.url.host);
        if (requestedHosts.length == 1) {
          return http.Response('busy', 504);
        }
        return http.Response(jsonEncode({'elements': []}), 200);
      }),
    );

    expect(
      await service.fetchHalalRestaurants(
        latitude: 38.34,
        longitude: -0.48,
        radiusMeters: 50000,
      ),
      isEmpty,
    );
    expect(requestedHosts, [
      'maps.mail.ru',
      'overpass.private.coffee',
    ]);
  });

  test('queries butchers as a compact candidate set and filters locally',
      () async {
    late String postedQuery;
    final service = OverpassMosqueService(
      client: MockClient((request) async {
        postedQuery = request.bodyFields['data'] ?? '';
        return http.Response(jsonEncode({'elements': []}), 200);
      }),
    );

    await service.fetchHalalButchers(
      latitude: 38.34,
      longitude: -0.48,
      radiusMeters: 50000,
    );

    expect(
      postedQuery,
      contains(
        'nwr["shop"="butcher"](around:50000,38.340000,-0.480000)',
      ),
    );
    expect(RegExp(r'nwr\[').allMatches(postedQuery), hasLength(1));
  });

  test('posts a bounded meter radius query with nodes ways and relations',
      () async {
    late String postedQuery;
    late Map<String, String> headers;
    final service = OverpassMosqueService(
      client: MockClient((request) async {
        postedQuery = request.bodyFields['data'] ?? '';
        headers = request.headers;
        return http.Response(jsonEncode({'elements': []}), 200);
      }),
    );

    await service.fetchMosques(
      latitude: 38.3456789,
      longitude: -0.4812345,
      radiusMeters: 999999,
    );

    expect(postedQuery, contains('node(around:50000,38.345679,-0.481235)'));
    expect(postedQuery, contains('way(around:50000,38.345679,-0.481235)'));
    expect(postedQuery, contains('relation(around:50000,38.345679,-0.481235)'));
    expect(postedQuery, contains('out center tags'));
    expect(
      postedQuery,
      contains('["amenity"="place_of_worship"]["religion"="muslim"]'),
    );
    expect(headers['Accept'], 'application/json');
    expect(headers['User-Agent'], contains('QiblaTime/1.6.0'));
  });
}

Map<String, dynamic> _foodElement({
  required int id,
  required Map<String, String> tags,
}) {
  return {
    'type': 'node',
    'id': id,
    'lat': 38.345 + (id / 10000),
    'lon': -0.49,
    'tags': tags,
  };
}

Map<String, Object> _mosqueElement({
  required int id,
  String? name,
  double lat = 38.345001,
  double lon = -0.490001,
}) {
  return {
    'type': 'node',
    'id': id,
    'lat': lat,
    'lon': lon,
    'tags': {
      'amenity': 'place_of_worship',
      'religion': 'muslim',
      if (name != null) 'name': name,
    },
  };
}
