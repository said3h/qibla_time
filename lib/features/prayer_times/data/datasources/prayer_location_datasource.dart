import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/location_access_result.dart';
import '../../domain/entities/prayer_location.dart';
import '../../domain/entities/prayer_location_diagnostic.dart';

class PrayerLocationDataSource {
  Future<LocationAccessResult?> getLocation({
    bool allowCachedFallbackWhenUnavailable = true,
    bool persistOnSuccess = true,
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
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 8),
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
