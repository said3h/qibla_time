import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:qibla_time/features/nearby/services/nearby_cache_service.dart';
import 'package:qibla_time/features/nearby/services/geoapify_places_service.dart';
import 'package:qibla_time/features/nearby/services/nearby_places_repository.dart';
import 'package:qibla_time/features/nearby/services/overpass_mosque_service.dart';
import 'package:qibla_time/features/prayer_times/data/datasources/prayer_location_datasource.dart';
import 'package:qibla_time/features/prayer_times/domain/entities/location_access_result.dart';
import 'package:qibla_time/features/prayer_times/domain/entities/prayer_location.dart';
import 'package:qibla_time/features/prayer_times/domain/entities/prayer_location_diagnostic.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('uses current location and sorts places by distance', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repository = NearbyPlacesRepository(
      locationDataSource: _FakeLocationDataSource(
        result: const LocationAccessResult(
          location: PrayerLocation(latitude: 38.34, longitude: -0.48),
          source: LocationAccessSource.live,
        ),
      ),
      overpassService: OverpassMosqueService(
        client: MockClient((_) async => http.Response(_twoMosquesJson, 200)),
      ),
      cacheService: NearbyCacheService(prefs: prefs),
    );

    final result = await repository.loadMosques(radiusMeters: 5000);

    expect(result.status, NearbyPlacesResultStatus.success);
    expect(result.originSource, LocationAccessSource.live);
    expect(result.places.map((place) => place.name), [
      'Near Mosque',
      'Far Mosque',
    ]);
  });

  test('supports manual city location source', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repository = NearbyPlacesRepository(
      locationDataSource: _FakeLocationDataSource(
        result: const LocationAccessResult(
          location: PrayerLocation(latitude: 38.34, longitude: -0.48),
          source: LocationAccessSource.manual,
        ),
      ),
      overpassService: OverpassMosqueService(
        client: MockClient((_) async => http.Response(_twoMosquesJson, 200)),
      ),
      cacheService: NearbyCacheService(prefs: prefs),
    );

    final result = await repository.loadMosques(radiusMeters: 5000);

    expect(result.originSource, LocationAccessSource.manual);
  });

  test('loads halal restaurants with their own category and cache', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    var requests = 0;
    final repository = NearbyPlacesRepository(
      locationDataSource: _FakeLocationDataSource(
        result: const LocationAccessResult(
          location: PrayerLocation(latitude: 38.34, longitude: -0.48),
          source: LocationAccessSource.manual,
        ),
      ),
      overpassService: OverpassMosqueService(
        client: MockClient((_) async {
          requests++;
          return http.Response(_halalRestaurantJson, 200);
        }),
      ),
      cacheService: NearbyCacheService(prefs: prefs),
    );

    final first = await repository.loadHalalRestaurants(radiusMeters: 5000);
    final cached = await repository.loadHalalRestaurants(radiusMeters: 5000);

    expect(first.places.single.name, 'Halal Restaurant');
    expect(first.places.single.category.name, 'halalRestaurant');
    expect(first.fromCache, isFalse);
    expect(cached.fromCache, isTrue);
    expect(requests, 1);
  });

  test('uses Geoapify first for halal restaurants when configured', () async {
    SharedPreferences.setMockInitialValues({});
    var geoapifyRequests = 0;
    var overpassRequests = 0;
    final repository = NearbyPlacesRepository(
      locationDataSource: _FakeLocationDataSource(
        result: const LocationAccessResult(
          location: PrayerLocation(latitude: 40.4168, longitude: -3.7038),
          source: LocationAccessSource.live,
        ),
      ),
      geoapifyService: GeoapifyPlacesService(
        apiKey: 'test-key',
        client: MockClient((_) async {
          geoapifyRequests++;
          return http.Response(_geoapifyRestaurantJson, 200);
        }),
      ),
      overpassService: OverpassMosqueService(
        client: MockClient((_) async {
          overpassRequests++;
          return http.Response(_halalRestaurantJson, 200);
        }),
      ),
      cacheService: NearbyCacheService(),
    );

    final result = await repository.loadHalalRestaurants(radiusMeters: 5000);

    expect(result.places.single.name, 'Geoapify Restaurant');
    expect(result.places.single.source, 'Geoapify / OpenStreetMap');
    expect(geoapifyRequests, 2);
    expect(overpassRequests, 0);
  });

  test('falls back to Overpass when Geoapify fails', () async {
    SharedPreferences.setMockInitialValues({});
    var overpassRequests = 0;
    final repository = NearbyPlacesRepository(
      locationDataSource: _FakeLocationDataSource(
        result: const LocationAccessResult(
          location: PrayerLocation(latitude: 40.4168, longitude: -3.7038),
          source: LocationAccessSource.live,
        ),
      ),
      geoapifyService: GeoapifyPlacesService(
        apiKey: 'test-key',
        client: MockClient((_) async => http.Response('unavailable', 503)),
      ),
      overpassService: OverpassMosqueService(
        client: MockClient((_) async {
          overpassRequests++;
          return http.Response(_halalRestaurantJson, 200);
        }),
      ),
      cacheService: NearbyCacheService(),
    );

    final result = await repository.loadHalalRestaurants(radiusMeters: 5000);

    expect(result.places.single.name, 'Halal Restaurant');
    expect(overpassRequests, 1);
  });

  test('does not cache empty nearby search results', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    var requests = 0;
    final repository = NearbyPlacesRepository(
      locationDataSource: _FakeLocationDataSource(
        result: const LocationAccessResult(
          location: PrayerLocation(latitude: 38.34, longitude: -0.48),
          source: LocationAccessSource.manual,
        ),
      ),
      overpassService: OverpassMosqueService(
        client: MockClient((_) async {
          requests++;
          return http.Response('{"elements":[]}', 200);
        }),
      ),
      cacheService: NearbyCacheService(prefs: prefs),
    );

    final first = await repository.loadHalalRestaurants(radiusMeters: 5000);
    final second = await repository.loadHalalRestaurants(radiusMeters: 5000);

    expect(first.places, isEmpty);
    expect(second.places, isEmpty);
    expect(first.fromCache, isFalse);
    expect(second.fromCache, isFalse);
    expect(requests, 2);
  });

  test('loads halal butchers and rejects untagged businesses', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = NearbyPlacesRepository(
      locationDataSource: _FakeLocationDataSource(
        result: const LocationAccessResult(
          location: PrayerLocation(latitude: 38.34, longitude: -0.48),
          source: LocationAccessSource.live,
        ),
      ),
      overpassService: OverpassMosqueService(
        client: MockClient((_) async => http.Response(_halalButcherJson, 200)),
      ),
      cacheService: NearbyCacheService(),
    );

    final result = await repository.loadHalalButchers(radiusMeters: 5000);

    expect(result.places, hasLength(1));
    expect(result.places.single.name, 'Halal Butcher');
    expect(result.places.single.category.name, 'halalButcher');
  });

  test('returns locationUnavailable state when no location can be resolved',
      () async {
    final repository = NearbyPlacesRepository(
      locationDataSource: _FakeLocationDataSource(result: null),
      overpassService: OverpassMosqueService(
        client: MockClient((_) async => http.Response(_twoMosquesJson, 200)),
      ),
      cacheService: NearbyCacheService(),
    );

    final result = await repository.loadMosques(radiusMeters: 5000);

    expect(result.status, NearbyPlacesResultStatus.locationUnavailable);
  });

  test('does not query Overpass with invalid or null-island coordinates',
      () async {
    var queried = false;
    final repository = NearbyPlacesRepository(
      locationDataSource: _FakeLocationDataSource(
        result: const LocationAccessResult(
          location: PrayerLocation(latitude: 0, longitude: 0),
          source: LocationAccessSource.manual,
        ),
      ),
      overpassService: OverpassMosqueService(
        client: MockClient((_) async {
          queried = true;
          return http.Response(_twoMosquesJson, 200);
        }),
      ),
      cacheService: NearbyCacheService(),
    );

    final result = await repository.loadMosques(radiusMeters: 5000);

    expect(result.status, NearbyPlacesResultStatus.locationUnavailable);
    expect(queried, isFalse);
  });
}

class _FakeLocationDataSource extends PrayerLocationDataSource {
  _FakeLocationDataSource({required this.result});

  final LocationAccessResult? result;

  @override
  Future<LocationAccessResult?> getLocation({
    bool allowCachedFallbackWhenUnavailable = true,
    bool persistOnSuccess = true,
  }) async {
    return result;
  }

  @override
  Future<PrayerLocationDiagnostic> getDiagnostic() async {
    return const PrayerLocationDiagnostic(
      serviceEnabled: false,
      permissionStatus: PrayerLocationPermissionStatus.denied,
      lastKnownLocation: null,
    );
  }
}

const _twoMosquesJson = '''
{
  "elements": [
    {
      "type": "node",
      "id": 1,
      "lat": 38.3600,
      "lon": -0.4800,
      "tags": {
        "amenity": "place_of_worship",
        "religion": "muslim",
        "name": "Far Mosque"
      }
    },
    {
      "type": "node",
      "id": 2,
      "lat": 38.3410,
      "lon": -0.4800,
      "tags": {
        "amenity": "place_of_worship",
        "religion": "muslim",
        "name": "Near Mosque"
      }
    }
  ]
}
''';

const _halalRestaurantJson = '''
{
  "elements": [
    {
      "type": "node",
      "id": 11,
      "lat": 38.3410,
      "lon": -0.4800,
      "tags": {
        "amenity": "restaurant",
        "diet:halal": "yes",
        "name": "Halal Restaurant"
      }
    }
  ]
}
''';

const _geoapifyRestaurantJson = '''
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "properties": {
        "place_id": "restaurant-1",
        "name": "Geoapify Restaurant",
        "formatted": "Madrid, Spain",
        "lat": 40.417,
        "lon": -3.704,
        "categories": ["catering.restaurant"],
        "conditions": ["halal"]
      },
      "geometry": {
        "type": "Point",
        "coordinates": [-3.704, 40.417]
      }
    }
  ]
}
''';

const _halalButcherJson = '''
{
  "elements": [
    {
      "type": "node",
      "id": 21,
      "lat": 38.3410,
      "lon": -0.4800,
      "tags": {
        "shop": "butcher",
        "diet:halal": "only",
        "name": "Halal Butcher"
      }
    },
    {
      "type": "node",
      "id": 22,
      "lat": 38.3420,
      "lon": -0.4800,
      "tags": {
        "shop": "butcher",
        "name": "Unverified Butcher"
      }
    }
  ]
}
''';
