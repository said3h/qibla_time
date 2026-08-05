import 'package:flutter/foundation.dart';

import '../../../core/services/logger_service.dart';
import '../../prayer_times/data/datasources/prayer_location_datasource.dart';
import '../../prayer_times/domain/entities/location_access_result.dart';
import '../../prayer_times/domain/entities/prayer_location.dart';
import '../models/nearby_place.dart';
import '../models/nearby_place_search.dart';
import 'geoapify_places_service.dart';
import 'nearby_cache_service.dart';
import 'nearby_distance_service.dart';
import 'overpass_mosque_service.dart';

class NearbyPlacesRepository {
  NearbyPlacesRepository({
    required PrayerLocationDataSource locationDataSource,
    required OverpassMosqueService overpassService,
    GeoapifyPlacesService? geoapifyService,
    required NearbyCacheService cacheService,
    NearbyDistanceService distanceService = const NearbyDistanceService(),
  })  : _locationDataSource = locationDataSource,
        _overpassService = overpassService,
        _geoapifyService = geoapifyService,
        _cacheService = cacheService,
        _distanceService = distanceService;

  final PrayerLocationDataSource _locationDataSource;
  final OverpassMosqueService _overpassService;
  final GeoapifyPlacesService? _geoapifyService;
  final NearbyCacheService _cacheService;
  final NearbyDistanceService _distanceService;

  Future<NearbyPlacesResult> loadMosques({
    required int radiusMeters,
    bool forceRefresh = false,
  }) {
    return _loadPlaces(
      category: NearbyPlaceCategory.mosque,
      radiusMeters: radiusMeters,
      forceRefresh: forceRefresh,
    );
  }

  Future<NearbyPlacesResult> loadHalalRestaurants({
    required int radiusMeters,
    bool forceRefresh = false,
  }) {
    return _loadPlaces(
      category: NearbyPlaceCategory.halalRestaurant,
      radiusMeters: radiusMeters,
      forceRefresh: forceRefresh,
    );
  }

  Future<NearbyPlacesResult> loadHalalButchers({
    required int radiusMeters,
    bool forceRefresh = false,
  }) {
    return _loadPlaces(
      category: NearbyPlaceCategory.halalButcher,
      radiusMeters: radiusMeters,
      forceRefresh: forceRefresh,
    );
  }

  Future<NearbyPlacesResult> _loadPlaces({
    required NearbyPlaceCategory category,
    required int radiusMeters,
    required bool forceRefresh,
  }) async {
    final accessResult = await _locationDataSource.getLocation();
    if (accessResult == null) {
      _debugLog('location unavailable before nearby ${category.name} search');
      final diagnostic = await _locationDataSource.getDiagnostic();
      return NearbyPlacesResult.locationUnavailable(diagnostic);
    }
    if (!_hasUsableCoordinates(accessResult.location)) {
      _debugLog('invalid nearby ${category.name} origin ignored');
      final diagnostic = await _locationDataSource.getDiagnostic();
      return NearbyPlacesResult.locationUnavailable(diagnostic);
    }
    _debugLog(
      'nearby ${category.name} search source=${accessResult.source.name} '
      'radius=$radiusMeters',
    );

    final search = NearbyPlaceSearch(
      category: category,
      origin: accessResult.location,
      radiusMeters: radiusMeters,
    );

    final cached = forceRefresh ? null : await _cacheService.read(search);
    if (cached != null) {
      _debugLog(
        'nearby ${category.name} result source=cache radius=$radiusMeters '
        'count=${cached.places.length}',
      );
      return NearbyPlacesResult.success(
        places: _withDistanceAndSort(cached.places, search),
        originSource: accessResult.source,
        originLocation: accessResult.location,
        fromCache: true,
      );
    }

    final List<NearbyPlace> places;
    try {
      places = await _fetchNetworkPlaces(search);
    } catch (error) {
      _debugLog(
        'nearby ${category.name} network error type=${error.runtimeType} '
        'radius=$radiusMeters',
      );
      rethrow;
    }
    final sorted = _withDistanceAndSort(places, search);
    if (sorted.isNotEmpty) {
      await _cacheService.write(search: search, places: sorted);
    }
    _debugLog(
      'nearby ${category.name} result source=network radius=$radiusMeters '
      'count=${sorted.length}',
    );
    return NearbyPlacesResult.success(
      places: sorted,
      originSource: accessResult.source,
      originLocation: accessResult.location,
      fromCache: false,
    );
  }

  Future<List<NearbyPlace>> _fetchNetworkPlaces(
    NearbyPlaceSearch search,
  ) async {
    final geoapify = _geoapifyService;
    final shouldUseGeoapify = search.category != NearbyPlaceCategory.mosque &&
        geoapify != null &&
        geoapify.isConfigured;
    if (shouldUseGeoapify) {
      try {
        final places = await geoapify.fetchPlaces(
          category: search.category,
          latitude: search.origin.latitude,
          longitude: search.origin.longitude,
          radiusMeters: search.radiusMeters,
        );
        _debugLog(
          'nearby ${search.category.name} provider=geoapify '
          'count=${places.length}',
        );
        if (places.isNotEmpty) return places;
      } catch (error) {
        _debugLog(
          'nearby ${search.category.name} provider=geoapify '
          'error=${error.runtimeType}; trying overpass fallback',
        );
      }
    }

    _debugLog('nearby ${search.category.name} provider=overpass');
    return _overpassService.fetchPlaces(
      category: search.category,
      latitude: search.origin.latitude,
      longitude: search.origin.longitude,
      radiusMeters: search.radiusMeters,
    );
  }

  void _debugLog(String message) {
    if (kDebugMode) {
      AppLogger.info(message);
    }
  }

  bool _hasUsableCoordinates(PrayerLocation location) {
    final latitude = location.latitude;
    final longitude = location.longitude;
    final inRange = latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
    final nullIsland = latitude == 0 && longitude == 0;
    return inRange && !nullIsland;
  }

  List<NearbyPlace> _withDistanceAndSort(
    List<NearbyPlace> places,
    NearbyPlaceSearch search,
  ) {
    final withDistance = places.map((place) {
      return place.copyWith(
        distanceMeters: _distanceService.distanceMeters(
          fromLatitude: search.origin.latitude,
          fromLongitude: search.origin.longitude,
          toLatitude: place.latitude,
          toLongitude: place.longitude,
        ),
      );
    }).toList();
    withDistance.sort((a, b) {
      final verification = _verificationRank(a).compareTo(_verificationRank(b));
      if (verification != 0) return verification;
      return (a.distanceMeters ?? double.infinity)
          .compareTo(b.distanceMeters ?? double.infinity);
    });
    return withDistance;
  }

  int _verificationRank(NearbyPlace place) {
    return switch (place.halalVerification) {
      HalalVerificationStatus.verified => 0,
      HalalVerificationStatus.possible => 1,
      null => 0,
    };
  }
}

enum NearbyPlacesResultStatus {
  success,
  locationUnavailable,
}

class NearbyPlacesResult {
  const NearbyPlacesResult._({
    required this.status,
    this.places = const <NearbyPlace>[],
    this.originSource,
    this.originLocation,
    this.fromCache = false,
    this.locationDiagnostic,
  });

  factory NearbyPlacesResult.success({
    required List<NearbyPlace> places,
    required LocationAccessSource originSource,
    required PrayerLocation originLocation,
    required bool fromCache,
  }) {
    return NearbyPlacesResult._(
      status: NearbyPlacesResultStatus.success,
      places: places,
      originSource: originSource,
      originLocation: originLocation,
      fromCache: fromCache,
    );
  }

  factory NearbyPlacesResult.locationUnavailable(Object diagnostic) {
    return NearbyPlacesResult._(
      status: NearbyPlacesResultStatus.locationUnavailable,
      locationDiagnostic: diagnostic,
    );
  }

  final NearbyPlacesResultStatus status;
  final List<NearbyPlace> places;
  final LocationAccessSource? originSource;
  final PrayerLocation? originLocation;
  final bool fromCache;
  final Object? locationDiagnostic;
}
