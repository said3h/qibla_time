import 'dart:math' as math;

class NearbyDistanceService {
  const NearbyDistanceService();

  double distanceMeters({
    required double fromLatitude,
    required double fromLongitude,
    required double toLatitude,
    required double toLongitude,
  }) {
    const earthRadiusMeters = 6371000.0;
    final dLat = _degreesToRadians(toLatitude - fromLatitude);
    final dLng = _degreesToRadians(toLongitude - fromLongitude);
    final lat1 = _degreesToRadians(fromLatitude);
    final lat2 = _degreesToRadians(toLatitude);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  double _degreesToRadians(double value) => value * math.pi / 180.0;
}
