import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/services/logger_service.dart';
import '../../domain/entities/manual_prayer_location.dart';
import '../../domain/entities/offline_prayer_city.dart';

class ManualPrayerLocationDataSource {
  static const _countryKey = 'manual_prayer_country';
  static const _cityKey = 'manual_prayer_city';
  static const _latitudeKey = 'manual_prayer_latitude';
  static const _longitudeKey = 'manual_prayer_longitude';

  Future<ManualPrayerLocation?> getManualLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final country = prefs.getString(_countryKey);
    final city = prefs.getString(_cityKey);
    final latitude = prefs.getDouble(_latitudeKey);
    final longitude = prefs.getDouble(_longitudeKey);

    if (city == null ||
        city.trim().isEmpty ||
        latitude == null ||
        longitude == null) {
      return null;
    }

    return ManualPrayerLocation(
      country: country ?? '',
      city: city,
      latitude: latitude,
      longitude: longitude,
    );
  }

  Future<ManualPrayerLocation> resolveAndSave({
    required String country,
    required String city,
  }) async {
    final trimmedCountry = country.trim();
    final trimmedCity = city.trim();
    final query = [
      trimmedCity,
      if (trimmedCountry.isNotEmpty) trimmedCountry,
    ].join(', ');

    final results = await locationFromAddress(query);
    if (results.isEmpty) {
      throw StateError('No coordinates found for manual city: $query');
    }

    final first = results.first;
    final manualLocation = ManualPrayerLocation(
      country: trimmedCountry,
      city: trimmedCity,
      latitude: first.latitude,
      longitude: first.longitude,
    );
    await saveManualLocation(manualLocation);
    return manualLocation;
  }

  Future<void> saveOfflineCity(OfflinePrayerCity city) {
    return saveManualLocation(
      ManualPrayerLocation(
        country: city.countryCode,
        city: city.name,
        latitude: city.latitude,
        longitude: city.longitude,
      ),
    );
  }

  Future<void> saveManualLocation(ManualPrayerLocation location) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_countryKey, location.country);
    await prefs.setString(_cityKey, location.city);
    await prefs.setDouble(_latitudeKey, location.latitude);
    await prefs.setDouble(_longitudeKey, location.longitude);
    AppLogger.info(
      'Manual prayer location saved: ${location.label} '
      '(${location.latitude}, ${location.longitude})',
    );
  }

  Future<void> clearManualLocation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_countryKey);
    await prefs.remove(_cityKey);
    await prefs.remove(_latitudeKey);
    await prefs.remove(_longitudeKey);
  }
}
