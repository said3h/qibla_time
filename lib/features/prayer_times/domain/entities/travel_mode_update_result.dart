import 'travel_pending_banner.dart';

class TravelModeUpdateResult {
  const TravelModeUpdateResult({
    required this.label,
    required this.travelDetected,
    this.pendingBanner,
  });

  final String label;
  final bool travelDetected;
  final TravelPendingBanner? pendingBanner;

  bool get shouldRefreshPrayerData => travelDetected;
}
