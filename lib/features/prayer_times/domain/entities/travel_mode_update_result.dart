class TravelModeUpdateResult {
  const TravelModeUpdateResult({
    required this.label,
    required this.travelDetected,
    this.pendingBanner,
  });

  final String label;
  final bool travelDetected;
  final String? pendingBanner;

  bool get shouldRefreshPrayerData => travelDetected;
}
