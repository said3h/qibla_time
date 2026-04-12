import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/location_access_result.dart';
import '../../domain/entities/prayer_location.dart';
import '../../domain/entities/prayer_location_diagnostic.dart';

class PrayerLocationDataSource {
  Future<void>? _backgroundRefreshTask;

  Future<LocationAccessResult?> getLocation({
    bool allowCachedFallbackWhenUnavailable = true,
    bool persistOnSuccess = true,
  }) async {
    final cachedResult = allowCachedFallbackWhenUnavailable
        ? await _getLastKnownLocationResult()
        : null;

    if (cachedResult != null) {
      _backgroundRefreshTask ??=
          _refreshLocationInBackground(
            cachedLocation: cachedResult.location,
            persistOnSuccess: persistOnSuccess,
          ).whenComplete(() => _backgroundRefreshTask = null);
      return cachedResult;
    }

    return _getLiveLocation(
      allowCachedFallbackWhenUnavailable: allowCachedFallbackWhenUnavailable,
      persistOnSuccess: persistOnSuccess,
    );
  }

  Future<LocationAccessResult?> _getLiveLocation({
    required bool allowCachedFallbackWhenUnavailable,
    required bool persistOnSuccess,
  }) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return allowCachedFallbackWhenUnavailable
          ? _getLastKnownLocationResult()
          : null;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return allowCachedFallbackWhenUnavailable
            ? _getLastKnownLocationResult()
            : null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return allowCachedFallbackWhenUnavailable
          ? _getLastKnownLocationResult()
          : null;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 5),
      );
      final location = PrayerLocation(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      if (persistOnSuccess) {
        await persistLastKnownLocation(location);
      }
      return LocationAccessResult(
        location: location,
        source: LocationAccessSource.live,
      );
    } catch (_) {
      final lastKnownPosition = await Geolocator.getLastKnownPosition();
      if (lastKnownPosition != null) {
        final location = PrayerLocation(
          latitude: lastKnownPosition.latitude,
          longitude: lastKnownPosition.longitude,
        );
        if (persistOnSuccess) {
          await persistLastKnownLocation(location);
        }
        return LocationAccessResult(
          location: location,
          source: LocationAccessSource.cache,
        );
      }

      return _getLastKnownLocationResult();
    }
  }

  Future<void> _refreshLocationInBackground({
    required PrayerLocation cachedLocation,
    required bool persistOnSuccess,
  }) async {
    try {
      final liveResult = await _getLiveLocation(
        allowCachedFallbackWhenUnavailable: false,
        persistOnSuccess: false,
      );
      if (liveResult == null || liveResult.isFromCache) {
        return;
      }

      final distanceKm = _distanceKm(cachedLocation, liveResult.location);
      if (distanceKm <= 10) {
        return;
      }

      if (persistOnSuccess) {
        await persistLastKnownLocation(liveResult.location);
      }
    } catch (_) {
      // Mantener la carga inicial rápida aunque falle el refresco en segundo plano.
    }
  }

  Future<PrayerLocation?> getCurrentLocation() async {
    return (await getLocation())?.location;
  }

  Future<PrayerLocationDiagnostic> getDiagnostic() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    final permission = await Geolocator.checkPermission();
    final lastKnownLocation = await getLastKnownLocation();

    return PrayerLocationDiagnostic(
      serviceEnabled: serviceEnabled,
      permissionStatus: _mapPermission(permission),
      lastKnownLocation: lastKnownLocation,
    );
  }

  Future<void> persistLastKnownLocation(PrayerLocation location) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('last_lat', location.latitude);
    await prefs.setDouble('last_lng', location.longitude);
  }

  Future<PrayerLocation?> getLastKnownLocation() async {
    return (await _getLastKnownLocationResult())?.location;
  }

  Future<LocationAccessResult?> _getLastKnownLocationResult() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble('last_lat');
    final lng = prefs.getDouble('last_lng');
    if (lat == null || lng == null) {
      return null;
    }
    return LocationAccessResult(
      location: PrayerLocation(latitude: lat, longitude: lng),
      source: LocationAccessSource.cache,
    );
  }

  double _distanceKm(PrayerLocation a, PrayerLocation b) {
    final latDistance = (a.latitude - b.latitude).abs();
    final lonDistance = (a.longitude - b.longitude).abs();
    return (latDistance * 111.0) + (lonDistance * 111.0);
  }

  PrayerLocationPermissionStatus _mapPermission(
    LocationPermission permission,
  ) {
    switch (permission) {
      case LocationPermission.denied:
        return PrayerLocationPermissionStatus.denied;
      case LocationPermission.deniedForever:
        return PrayerLocationPermissionStatus.deniedForever;
      case LocationPermission.always:
      case LocationPermission.whileInUse:
        return PrayerLocationPermissionStatus.granted;
      case LocationPermission.unableToDetermine:
        return PrayerLocationPermissionStatus.unknown;
    }
  }
}
