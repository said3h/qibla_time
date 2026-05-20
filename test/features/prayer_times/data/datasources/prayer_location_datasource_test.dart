import 'package:flutter_test/flutter_test.dart';
import 'package:qibla_time/features/prayer_times/data/datasources/manual_prayer_location_datasource.dart';
import 'package:qibla_time/features/prayer_times/data/datasources/prayer_location_datasource.dart';
import 'package:qibla_time/features/prayer_times/domain/entities/location_access_result.dart';
import 'package:qibla_time/features/prayer_times/domain/entities/manual_prayer_location.dart';
import 'package:qibla_time/features/prayer_times/domain/entities/prayer_location.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeManualPrayerLocationDataSource
    extends ManualPrayerLocationDataSource {
  _FakeManualPrayerLocationDataSource(this.location);

  final ManualPrayerLocation? location;

  @override
  Future<ManualPrayerLocation?> getManualLocation() async => location;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PrayerLocationDataSource', () {
    test('uses manual city before cached GPS coordinates', () async {
      SharedPreferences.setMockInitialValues({
        'last_lat': 48.8566,
        'last_lng': 2.3522,
      });
      final dataSource = PrayerLocationDataSource(
        manualLocationDataSource: _FakeManualPrayerLocationDataSource(
          const ManualPrayerLocation(
            country: 'Spain',
            city: 'Alicante',
            latitude: 38.3452,
            longitude: -0.481,
          ),
        ),
      );

      final result = await dataSource.getLocation();

      expect(result, isNotNull);
      expect(result!.source, LocationAccessSource.manual);
      expect(result.location.latitude, 38.3452);
      expect(result.location.longitude, -0.481);
    });

    test('returns cached location when manual city is not set', () async {
      SharedPreferences.setMockInitialValues({
        'last_lat': 48.8566,
        'last_lng': 2.3522,
      });
      final dataSource = PrayerLocationDataSource(
        manualLocationDataSource: _FakeManualPrayerLocationDataSource(null),
      );

      final result = await dataSource.getLocation();

      expect(result, isNotNull);
      expect(result!.source, LocationAccessSource.cache);
      expect(result.location.latitude, 48.8566);
      expect(result.location.longitude, 2.3522);
    });

    test('persists and reads last known location', () async {
      SharedPreferences.setMockInitialValues({});
      final dataSource = PrayerLocationDataSource(
        manualLocationDataSource: _FakeManualPrayerLocationDataSource(null),
      );

      await dataSource.persistLastKnownLocation(
        const PrayerLocation(latitude: 41.0082, longitude: 28.9784),
      );

      final location = await dataSource.getLastKnownLocation();

      expect(location, isNotNull);
      expect(location!.latitude, 41.0082);
      expect(location.longitude, 28.9784);
    });
  });
}
