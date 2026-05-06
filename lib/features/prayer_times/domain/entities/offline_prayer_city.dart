class OfflinePrayerCountry {
  const OfflinePrayerCountry({
    required this.code,
    required this.cityCount,
  });

  final String code;
  final int cityCount;

  String get label => '$code ($cityCount)';
}

class OfflinePrayerCity {
  const OfflinePrayerCity({
    required this.countryCode,
    required this.name,
    required this.normalizedName,
    required this.latitude,
    required this.longitude,
  });

  final String countryCode;
  final String name;
  final String normalizedName;
  final double latitude;
  final double longitude;

  String get label => '$name, $countryCode';
}
