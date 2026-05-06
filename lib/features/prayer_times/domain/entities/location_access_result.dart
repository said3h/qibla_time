import 'prayer_location.dart';

enum LocationAccessSource {
  live,
  cache,
  manual,
}

class LocationAccessResult {
  const LocationAccessResult({
    required this.location,
    required this.source,
  });

  final PrayerLocation location;
  final LocationAccessSource source;

  bool get isFromCache => source == LocationAccessSource.cache;

  bool get isManual => source == LocationAccessSource.manual;
}
