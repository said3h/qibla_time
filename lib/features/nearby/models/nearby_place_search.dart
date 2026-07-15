import '../../prayer_times/domain/entities/prayer_location.dart';
import 'nearby_place.dart';

class NearbyPlaceSearch {
  const NearbyPlaceSearch({
    required this.category,
    required this.origin,
    required this.radiusMeters,
  });

  final NearbyPlaceCategory category;
  final PrayerLocation origin;
  final int radiusMeters;
}
