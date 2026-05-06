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
    required this.countryName,
    required this.name,
    required this.normalizedName,
    required this.latitude,
    required this.longitude,
  });

  final String countryCode;
  final String countryName;
  final String name;
  final String normalizedName;
  final double latitude;
  final double longitude;

  String get label => '$name, $countryName';
}

class OfflinePrayerCitySuggestion {
  const OfflinePrayerCitySuggestion({
    required this.countryCode,
    required this.countryName,
    required this.name,
    required this.normalizedName,
    required this.entryIndex,
  });

  final String countryCode;
  final String countryName;
  final String name;
  final String normalizedName;
  final int entryIndex;

  String get label => '$name, $countryName';
}
