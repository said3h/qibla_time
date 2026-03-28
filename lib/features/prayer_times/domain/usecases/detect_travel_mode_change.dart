import 'dart:math' as math;

import '../entities/prayer_location.dart';
import '../entities/travel_mode_detection.dart';

class DetectTravelModeChangeUseCase {
  const DetectTravelModeChangeUseCase();

  TravelModeDetection call({
    required bool enabled,
    required PrayerLocation currentLocation,
    required String currentTimezone,
    required String label,
    PrayerLocation? previousLocation,
    String? previousTimezone,
    double kmThreshold = 50,
  }) {
    if (!enabled || previousLocation == null) {
      return const TravelModeDetection(travelDetected: false);
    }

    final distanceKm = _distanceKm(previousLocation, currentLocation);
    final timezoneChanged = previousTimezone != currentTimezone;
    final travelDetected = distanceKm > kmThreshold || timezoneChanged;
    if (!travelDetected) {
      return const TravelModeDetection(travelDetected: false);
    }

    return TravelModeDetection(
      travelDetected: true,
      distanceKmRounded: distanceKm.round(),
      pendingBanner:
          'Nueva ubicación detectada: $label - ${distanceKm.round()} km',
    );
  }

  double _distanceKm(PrayerLocation origin, PrayerLocation target) {
    const earthRadiusKm = 6371.0;
    final lat1 = _degreesToRadians(origin.latitude);
    final lat2 = _degreesToRadians(target.latitude);
    final dLat = _degreesToRadians(target.latitude - origin.latitude);
    final dLng = _degreesToRadians(target.longitude - origin.longitude);

    final a =
        _sinSquared(dLat / 2) +
        _sinSquared(dLng / 2) * math.cos(lat1) * math.cos(lat2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * 0.017453292519943295;
  }

  double _sinSquared(double value) {
    final sine = math.sin(value);
    return sine * sine;
  }
}
