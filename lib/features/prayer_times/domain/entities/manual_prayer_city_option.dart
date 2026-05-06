class ManualPrayerCityOption {
  const ManualPrayerCityOption({
    required this.country,
    required this.city,
    required this.latitude,
    required this.longitude,
  });

  final String country;
  final String city;
  final double latitude;
  final double longitude;

  String get label => '$city, $country';
}
