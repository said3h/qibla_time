import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../prayer_times/presentation/providers/prayer_times_providers.dart';
import '../services/geoapify_places_service.dart';
import '../services/nearby_cache_service.dart';
import '../services/nearby_places_repository.dart';
import '../services/overpass_mosque_service.dart';

const nearbyRadiusOptionsMeters = [5000, 10000, 25000, 50000];
const nearbyDefaultRadiusMeters = 10000;

final nearbyRadiusProvider = StateProvider<int>((ref) {
  return nearbyDefaultRadiusMeters;
});

final overpassMosqueServiceProvider = Provider<OverpassMosqueService>((ref) {
  return OverpassMosqueService();
});

final geoapifyPlacesServiceProvider = Provider<GeoapifyPlacesService>((ref) {
  return GeoapifyPlacesService();
});

final nearbyCacheServiceProvider = Provider<NearbyCacheService>((ref) {
  return NearbyCacheService();
});

final nearbyPlacesRepositoryProvider = Provider<NearbyPlacesRepository>((ref) {
  return NearbyPlacesRepository(
    locationDataSource: ref.watch(prayerLocationDataSourceProvider),
    overpassService: ref.watch(overpassMosqueServiceProvider),
    geoapifyService: ref.watch(geoapifyPlacesServiceProvider),
    cacheService: ref.watch(nearbyCacheServiceProvider),
  );
});

final nearbyMosquesProvider =
    FutureProvider.family<NearbyPlacesResult, int>((ref, radiusMeters) async {
  return ref.watch(nearbyPlacesRepositoryProvider).loadMosques(
        radiusMeters: radiusMeters,
      );
});

final nearbyHalalRestaurantsProvider =
    FutureProvider.family<NearbyPlacesResult, int>((ref, radiusMeters) async {
  return ref.watch(nearbyPlacesRepositoryProvider).loadHalalRestaurants(
        radiusMeters: radiusMeters,
      );
});

final nearbyHalalButchersProvider =
    FutureProvider.family<NearbyPlacesResult, int>((ref, radiusMeters) async {
  return ref.watch(nearbyPlacesRepositoryProvider).loadHalalButchers(
        radiusMeters: radiusMeters,
      );
});
