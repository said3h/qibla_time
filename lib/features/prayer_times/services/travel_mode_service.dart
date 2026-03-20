import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import 'notification_service.dart';
import 'prayer_service.dart';
import 'adhan_manager.dart';

class RecentLocation {
  const RecentLocation({
    required this.label,
    required this.latitude,
    required this.longitude,
    required this.timezone,
    required this.timestamp,
  });

  final String label;
  final double latitude;
  final double longitude;
  final String timezone;
  final DateTime timestamp;

  Map<String, dynamic> toJson() => {
        'label': label,
        'latitude': latitude,
        'longitude': longitude,
        'timezone': timezone,
        'timestamp': timestamp.toIso8601String(),
      };

  factory RecentLocation.fromJson(Map<String, dynamic> json) {
    return RecentLocation(
      label: json['label'] as String? ?? 'Ubicacion desconocida',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      timezone: json['timezone'] as String? ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class TravelModeService {
  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.keyTravelerModeEnabled) ?? true;
  }

  Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyTravelerModeEnabled, value);
  }

  Future<void> recordLocationUpdate(Position position, {dynamic ref}) async {
    final prefs = await SharedPreferences.getInstance();
    final timezone = DateTime.now().timeZoneName;
    final label = await _resolveLocationLabel(position);

    final previousLat = prefs.getDouble('last_lat');
    final previousLng = prefs.getDouble('last_lng');
    final previousTimezone = prefs.getString(AppConstants.keyTravelerLastTimezone);
    final enabled = await isEnabled();

    if (previousLat != null && previousLng != null) {
      final distance = Geolocator.distanceBetween(
        previousLat,
        previousLng,
        position.latitude,
        position.longitude,
      );
      if (enabled && (distance > 50000 || previousTimezone != timezone)) {
        final banner = 'Nueva ubicación detectada: $label · ${(distance / 1000).round()} km';
        await prefs.setString(AppConstants.keyTravelerPendingBanner, banner);
        await NotificationService.instance.showInstant(
          title: 'QiblaTime — Nueva ubicación',
          body: '$label · Horarios actualizados',
        );

        // ← NUEVO: Reprogramar Adhans con la nueva ubicación
        if (ref != null) {
          ref.invalidate(prayerTimesProvider);
          await Future.delayed(const Duration(milliseconds: 500));
          await ref.read(adhanManagerProvider).scheduleTodayAdhans();

          // Invalidar providers de UI
          ref.invalidate(travelBannerProvider);
          ref.invalidate(recentLocationsProvider);
          ref.invalidate(lastLocationLabelProvider);
        }
      }
    }

    await prefs.setString(AppConstants.keyTravelerLastLocationLabel, label);
    await prefs.setString(AppConstants.keyTravelerLastTimezone, timezone);
    await _storeRecentLocation(
      RecentLocation(
        label: label,
        latitude: position.latitude,
        longitude: position.longitude,
        timezone: timezone,
        timestamp: DateTime.now(),
      ),
    );
  }

  Future<String?> getPendingBanner() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.keyTravelerPendingBanner);
  }

  Future<void> clearPendingBanner() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keyTravelerPendingBanner);
  }

  Future<String?> getLastLocationLabel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.keyTravelerLastLocationLabel);
  }

  Future<List<RecentLocation>> getRecentLocations() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(AppConstants.keyTravelerRecentLocations) ?? [];
    return raw
        .map((item) => RecentLocation.fromJson(jsonDecode(item) as Map<String, dynamic>))
        .toList();
  }

  Future<void> _storeRecentLocation(RecentLocation location) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getRecentLocations();
    final updated = [location, ...current.where((item) => item.label != location.label)]
        .take(5)
        .map((item) => jsonEncode(item.toJson()))
        .toList();
    await prefs.setStringList(AppConstants.keyTravelerRecentLocations, updated);
  }

  Future<String> _resolveLocationLabel(Position position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final locality = place.locality?.isNotEmpty == true
            ? place.locality
            : place.subAdministrativeArea;
        final country = place.country?.isNotEmpty == true ? place.country : null;
        final parts = [if (locality != null) locality, if (country != null) country];
        if (parts.isNotEmpty) return parts.join(', ');
      }
    } catch (_) {}
    return '${position.latitude.toStringAsFixed(2)}, ${position.longitude.toStringAsFixed(2)}';
  }
}

final travelModeServiceProvider = Provider<TravelModeService>((ref) {
  return TravelModeService();
});

final travelerModeEnabledProvider = FutureProvider<bool>((ref) async {
  return ref.watch(travelModeServiceProvider).isEnabled();
});

final travelBannerProvider = FutureProvider<String?>((ref) async {
  return ref.watch(travelModeServiceProvider).getPendingBanner();
});

final recentLocationsProvider = FutureProvider<List<RecentLocation>>((ref) async {
  return ref.watch(travelModeServiceProvider).getRecentLocations();
});

final lastLocationLabelProvider = FutureProvider<String?>((ref) async {
  return ref.watch(travelModeServiceProvider).getLastLocationLabel();
});
