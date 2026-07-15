import 'package:flutter_test/flutter_test.dart';
import 'package:qibla_time/features/nearby/services/nearby_distance_service.dart';

void main() {
  test('calculates realistic distance in meters', () {
    const service = NearbyDistanceService();

    final distance = service.distanceMeters(
      fromLatitude: 38.3452,
      fromLongitude: -0.4810,
      toLatitude: 38.3552,
      toLongitude: -0.4810,
    );

    expect(distance, greaterThan(1000));
    expect(distance, lessThan(1200));
  });

  test('handles same coordinate, equator and negative coordinates', () {
    const service = NearbyDistanceService();

    expect(
      service.distanceMeters(
        fromLatitude: 0,
        fromLongitude: 0,
        toLatitude: 0,
        toLongitude: 0,
      ),
      closeTo(0, 0.001),
    );
    expect(
      service.distanceMeters(
        fromLatitude: 0,
        fromLongitude: 0,
        toLatitude: 0,
        toLongitude: 1,
      ),
      closeTo(111195, 500),
    );
    expect(
      service.distanceMeters(
        fromLatitude: -33.8688,
        fromLongitude: 151.2093,
        toLatitude: -37.8136,
        toLongitude: 144.9631,
      ),
      closeTo(713000, 5000),
    );
  });

  test('handles crossing the 180th meridian', () {
    const service = NearbyDistanceService();

    final distance = service.distanceMeters(
      fromLatitude: 0,
      fromLongitude: 179.9,
      toLatitude: 0,
      toLongitude: -179.9,
    );

    expect(distance, closeTo(22239, 500));
  });
}
