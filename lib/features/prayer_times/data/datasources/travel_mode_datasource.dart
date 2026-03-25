import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/prayer_location.dart';
import '../../domain/entities/recent_location.dart';
import '../../domain/entities/travel_mode_state.dart';

class TravelModeDataSource {
  Future<TravelModeState> getState() async {
    final prefs = await SharedPreferences.getInstance();
    final previousLat = prefs.getDouble('last_lat');
    final previousLng = prefs.getDouble('last_lng');

    return TravelModeState(
      enabled: prefs.getBool(AppConstants.keyTravelerModeEnabled) ?? true,
      previousLocation: previousLat != null && previousLng != null
          ? PrayerLocation(latitude: previousLat, longitude: previousLng)
          : null,
      previousTimezone: prefs.getString(AppConstants.keyTravelerLastTimezone),
    );
  }

  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.keyTravelerModeEnabled) ?? true;
  }

  Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyTravelerModeEnabled, value);
  }

  Future<String?> getPendingBanner() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.keyTravelerPendingBanner);
  }

  Future<void> setPendingBanner(String banner) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyTravelerPendingBanner, banner);
  }

  Future<void> clearPendingBanner() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keyTravelerPendingBanner);
  }

  Future<String?> getLastLocationLabel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.keyTravelerLastLocationLabel);
  }

  Future<void> saveCurrentContext({
    required String label,
    required String timezone,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyTravelerLastLocationLabel, label);
    await prefs.setString(AppConstants.keyTravelerLastTimezone, timezone);
  }

  Future<List<RecentLocation>> getRecentLocations() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(AppConstants.keyTravelerRecentLocations) ?? [];
    return raw
        .map((item) => RecentLocation.fromJson(jsonDecode(item) as Map<String, dynamic>))
        .toList();
  }

  Future<void> storeRecentLocation(RecentLocation location) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getRecentLocations();
    final updated = [location, ...current.where((item) => item.label != location.label)]
        .take(5)
        .map((item) => jsonEncode(item.toJson()))
        .toList();
    await prefs.setStringList(AppConstants.keyTravelerRecentLocations, updated);
  }
}
