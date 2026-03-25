import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/location_access_result.dart';
import '../../domain/entities/prayer_location.dart';

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
      return _getLastKnownLocationResult();
    }
  }

  Future<PrayerLocation?> getCurrentLocation() async {
    return (await getLocation())?.location;
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
}
