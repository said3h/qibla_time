import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qibla_time/features/prayer_times/domain/entities/prayer_location.dart';
import 'package:qibla_time/features/prayer_times/presentation/providers/prayer_times_providers.dart';
import 'package:qibla_time/features/qibla/services/qibla_service.dart';

void main() {
  group('Qibla providers', () {
    test('returns null bearing and distance when location is unavailable', () async {
      final container = ProviderContainer(
        overrides: [
          prayerLocationProvider.overrideWith((ref) async => null),
        ],
      );
      addTearDown(container.dispose);

      await expectLater(container.read(qiblaBearingProvider.future), completion(isNull));
      await expectLater(container.read(distanceToMeccaProvider.future), completion(isNull));
    });

    test('computes a plausible qibla bearing and distance for Paris', () async {
      final container = ProviderContainer(
        overrides: [
          prayerLocationProvider.overrideWith(
            (ref) async => const PrayerLocation(
              latitude: 48.8566,
              longitude: 2.3522,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final bearing = await container.read(qiblaBearingProvider.future);
      final distanceKm = await container.read(distanceToMeccaProvider.future);

      expect(bearing, isNotNull);
      expect(bearing, inInclusiveRange(110.0, 130.0));
      expect(distanceKm, isNotNull);
      expect(distanceKm, inInclusiveRange(4300.0, 4700.0));
    });
  });
}
