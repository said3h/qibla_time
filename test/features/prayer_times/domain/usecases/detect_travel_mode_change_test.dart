import 'package:flutter_test/flutter_test.dart';
import 'package:qibla_time/features/prayer_times/domain/entities/prayer_location.dart';
import 'package:qibla_time/features/prayer_times/domain/usecases/detect_travel_mode_change.dart';

void main() {
  group('DetectTravelModeChangeUseCase', () {
    const useCase = DetectTravelModeChangeUseCase();

    test('returns no travel when mode is disabled', () {
      final result = useCase.call(
        enabled: false,
        currentLocation: const PrayerLocation(latitude: 48.8566, longitude: 2.3522),
        currentTimezone: 'CET',
        previousLocation: const PrayerLocation(latitude: 40.4168, longitude: -3.7038),
        previousTimezone: 'CET',
      );

      expect(result.travelDetected, isFalse);
      expect(result.pendingBanner, isNull);
    });

    test('detects travel when the distance threshold is exceeded', () {
      final result = useCase.call(
        enabled: true,
        currentLocation: const PrayerLocation(latitude: 48.8566, longitude: 2.3522),
        currentTimezone: 'CET',
        previousLocation: const PrayerLocation(latitude: 40.4168, longitude: -3.7038),
        previousTimezone: 'CET',
      );

      expect(result.travelDetected, isTrue);
      expect(result.distanceKmRounded, greaterThan(50));
      expect(result.pendingBanner, isNull);
    });

    test('detects travel when the timezone changes even with little movement', () {
      final result = useCase.call(
        enabled: true,
        currentLocation: const PrayerLocation(latitude: 48.8566, longitude: 2.3522),
        currentTimezone: 'CEST',
        previousLocation: const PrayerLocation(latitude: 48.8570, longitude: 2.3525),
        previousTimezone: 'CET',
      );

      expect(result.travelDetected, isTrue);
      expect(result.distanceKmRounded, isNotNull);
    });

    test('returns no travel when movement stays below threshold and timezone matches', () {
      final result = useCase.call(
        enabled: true,
        currentLocation: const PrayerLocation(latitude: 48.8566, longitude: 2.3522),
        currentTimezone: 'CET',
        previousLocation: const PrayerLocation(latitude: 48.8570, longitude: 2.3525),
        previousTimezone: 'CET',
      );

      expect(result.travelDetected, isFalse);
      expect(result.pendingBanner, isNull);
    });
  });
}
