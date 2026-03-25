import 'prayer_location.dart';

enum PrayerLocationPermissionStatus {
  granted,
  denied,
  deniedForever,
  unknown,
}

class PrayerLocationDiagnostic {
  const PrayerLocationDiagnostic({
    required this.serviceEnabled,
    required this.permissionStatus,
    required this.lastKnownLocation,
  });

  final bool serviceEnabled;
  final PrayerLocationPermissionStatus permissionStatus;
  final PrayerLocation? lastKnownLocation;

  bool get hasCachedLocation => lastKnownLocation != null;

  bool get canUseLiveLocation {
    return serviceEnabled &&
        permissionStatus != PrayerLocationPermissionStatus.denied &&
        permissionStatus != PrayerLocationPermissionStatus.deniedForever;
  }
}
