import 'package:flutter_test/flutter_test.dart';
import 'package:qibla_time/features/nearby/models/nearby_place.dart';
import 'package:qibla_time/features/nearby/models/nearby_place_search.dart';
import 'package:qibla_time/features/nearby/services/nearby_cache_service.dart';
import 'package:qibla_time/features/prayer_times/domain/entities/prayer_location.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('returns valid cache and rejects expired cache', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    const search = NearbyPlaceSearch(
      category: NearbyPlaceCategory.mosque,
      origin: PrayerLocation(latitude: 38.34, longitude: -0.48),
      radiusMeters: 5000,
    );
    final service = NearbyCacheService(
      prefs: prefs,
      ttl: const Duration(hours: 1),
    );

    await service.write(search: search, places: [_place()]);
    expect(await service.read(search), isNotNull);

    final expired = NearbyCacheService(
      prefs: prefs,
      ttl: Duration.zero,
    );
    expect(await expired.read(search), isNull);
  });

  test('rejects cache when origin moved too far', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final service = NearbyCacheService(prefs: prefs);
    const initial = NearbyPlaceSearch(
      category: NearbyPlaceCategory.mosque,
      origin: PrayerLocation(latitude: 38.34, longitude: -0.48),
      radiusMeters: 5000,
    );
    const moved = NearbyPlaceSearch(
      category: NearbyPlaceCategory.mosque,
      origin: PrayerLocation(latitude: 39.34, longitude: -0.48),
      radiusMeters: 5000,
    );

    await service.write(search: initial, places: [_place()]);

    expect(await service.read(moved), isNull);
  });

  test('keeps different radiuses and cities isolated', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final service = NearbyCacheService(prefs: prefs);
    const fiveKmAlicante = NearbyPlaceSearch(
      category: NearbyPlaceCategory.mosque,
      origin: PrayerLocation(latitude: 38.34, longitude: -0.48),
      radiusMeters: 5000,
    );
    const fiftyKmAlicante = NearbyPlaceSearch(
      category: NearbyPlaceCategory.mosque,
      origin: PrayerLocation(latitude: 38.34, longitude: -0.48),
      radiusMeters: 50000,
    );
    const fiveKmMadrid = NearbyPlaceSearch(
      category: NearbyPlaceCategory.mosque,
      origin: PrayerLocation(latitude: 40.42, longitude: -3.70),
      radiusMeters: 5000,
    );

    await service.write(search: fiveKmAlicante, places: [_place()]);

    expect(await service.read(fiveKmAlicante), isNotNull);
    expect(await service.read(fiftyKmAlicante), isNull);
    expect(await service.read(fiveKmMadrid), isNull);
  });

  test('rejects corrupt or old cache payloads', () async {
    SharedPreferences.setMockInitialValues({
      'nearby:v1:mosque:5000': '{broken',
      'nearby:mosque:5000': '{}',
    });
    final prefs = await SharedPreferences.getInstance();
    final service = NearbyCacheService(prefs: prefs);
    const search = NearbyPlaceSearch(
      category: NearbyPlaceCategory.mosque,
      origin: PrayerLocation(latitude: 38.34, longitude: -0.48),
      radiusMeters: 5000,
    );

    expect(await service.read(search), isNull);
  });
}

NearbyPlace _place() {
  return const NearbyPlace(
    id: 'node/1',
    category: NearbyPlaceCategory.mosque,
    latitude: 38.35,
    longitude: -0.49,
    source: 'OpenStreetMap',
    name: 'Mosque',
  );
}
