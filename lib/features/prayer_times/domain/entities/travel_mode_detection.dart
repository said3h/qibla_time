class TravelModeDetection {
  const TravelModeDetection({
    required this.travelDetected,
    this.distanceKmRounded,
    this.pendingBanner,
  });

  final bool travelDetected;
  final int? distanceKmRounded;
  final String? pendingBanner;
}
