import 'prayer_location.dart';

class ManualPrayerLocation {
  const ManualPrayerLocation({
    required this.country,
    required this.city,
    required this.latitude,
    required this.longitude,
  });

  final String country;
  final String city;
  final double latitude;
  final double longitude;

  PrayerLocation get location => PrayerLocation(
        latitude: latitude,
        longitude: longitude,
      );

  String get label {
    final trimmedCity = city.trim();
    final trimmedCountry = country.trim();
    if (trimmedCountry.isEmpty) {
      return trimmedCity;
    }
    return '$trimmedCity, $trimmedCountry';
  }
}
