import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_compass/flutter_compass.dart';
import '../../prayer_times/services/prayer_service.dart';
import 'package:adhan/adhan.dart';
import '../../../core/constants/app_constants.dart';
import 'package:geolocator/geolocator.dart';

// Stream of compass heading events
final compassProvider = StreamProvider<CompassEvent>((ref) {
  return FlutterCompass.events!;
});

// Provides the precise bearing to Mecca from the user's location
final qiblaBearingProvider = FutureProvider<double?>((ref) async {
  final position = await ref.watch(locationProvider.future);
  if (position == null) return null;

  final coordinates = Coordinates(position.latitude, position.longitude);
  return Qibla(coordinates).direction;
});

// Provides the distance to Mecca in kilometers
final distanceToMeccaProvider = FutureProvider<double?>((ref) async {
  final position = await ref.watch(locationProvider.future);
  if (position == null) return null;

  final distanceInMeters = Geolocator.distanceBetween(
    position.latitude,
    position.longitude,
    AppConstants.kaabaLatitude,
    AppConstants.kaabaLongitude,
  );
  
  return distanceInMeters / 1000; // Return in kilometers
});
