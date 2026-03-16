import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:adhan/adhan.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';

// Provides the current coordinates of the user
final locationProvider = FutureProvider<Position?>((ref) async {
  bool serviceEnabled;
  LocationPermission permission;

  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) return null;

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) return null;
  }
  
  if (permission == LocationPermission.deniedForever) return null;

  return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
});

// Provides the chosen calculation method
final calculationMethodProvider = FutureProvider<CalculationMethod>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final index = prefs.getInt(AppConstants.keyCalculationMethod) ?? CalculationMethod.muslim_world_league.index;
  return CalculationMethod.values[index];
});

// Combines location, date and method to output the PrayerTimes object
final prayerTimesProvider = FutureProvider<PrayerTimes?>((ref) async {
  final position = await ref.watch(locationProvider.future);
  final method = await ref.watch(calculationMethodProvider.future);
  
  if (position == null) return null;

  final coordinates = Coordinates(position.latitude, position.longitude);
  final params = method.getParameters();
  params.madhab = Madhab.shafi; // Default, can be configurable later

  final date = DateComponents.from(DateTime.now());
  return PrayerTimes(coordinates, date, params);
});
