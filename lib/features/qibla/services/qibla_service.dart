import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:adhan/adhan.dart';
import '../../../core/constants/app_constants.dart';
import 'package:geolocator/geolocator.dart';
import '../../prayer_times/presentation/providers/prayer_times_providers.dart';

// Stream of compass heading events
final compassProvider = StreamProvider<CompassEvent>((ref) {
  // Ensure we are listening only to valid events
  return FlutterCompass.events?.where((event) => event.heading != null) ?? const Stream.empty();
});

// Provides the precise bearing to Mecca from the user's location
final qiblaBearingProvider = FutureProvider<double?>((ref) async {
  final location = await ref.watch(prayerLocationProvider.future);
  if (location == null) return null;

  final coordinates = Coordinates(location.latitude, location.longitude);
  return Qibla(coordinates).direction;
});

// Provides the distance to Mecca in kilometers
final distanceToMeccaProvider = FutureProvider<double?>((ref) async {
  final location = await ref.watch(prayerLocationProvider.future);
  if (location == null) return null;

  final distanceInMeters = Geolocator.distanceBetween(
    location.latitude,
    location.longitude,
    AppConstants.kaabaLatitude,
    AppConstants.kaabaLongitude,
  );
  
  return distanceInMeters / 1000; // Return in kilometers
});
