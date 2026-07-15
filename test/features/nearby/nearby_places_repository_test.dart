import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:qibla_time/features/nearby/services/nearby_cache_service.dart';
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
