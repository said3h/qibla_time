import 'prayer_location.dart';

class TravelModeState {
  const TravelModeState({
    required this.enabled,
    this.previousLocation,
    this.previousTimezone,
  });

  final bool enabled;
  final PrayerLocation? previousLocation;
  final String? previousTimezone;
}
