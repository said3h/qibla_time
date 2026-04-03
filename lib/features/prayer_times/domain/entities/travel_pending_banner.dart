class TravelPendingBanner {
  const TravelPendingBanner({
    required this.label,
    required this.distanceKm,
  });

  final String label;
  final int distanceKm;

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'distanceKm': distanceKm,
    };
  }

  factory TravelPendingBanner.fromJson(Map<String, dynamic> json) {
    return TravelPendingBanner(
      label: json['label'] as String? ?? '',
      distanceKm: (json['distanceKm'] as num?)?.toInt() ?? 0,
    );
  }
}
