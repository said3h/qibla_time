import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:adhan/adhan.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';

// Provides the current coordinates of the user
final locationProvider = FutureProvider<Position?>((ref) async {
  try {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    // Try to get last known position for speed
    Position? lastKnown = await Geolocator.getLastKnownPosition();
    if (lastKnown != null) {
      // If last known is recent enough (e.g., < 1 hour), we could use it, 
      // but for prayer times accurate location is better.
      // Let's still try to get a fresh one with a timeout.
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium, // Medium is usually enough for prayer times
      timeLimit: const Duration(seconds: 10),
    ).catchError((e) => lastKnown); // Fallback to last known if fresh fails
  } catch (e) {
    return null;
  }
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

// Provides a countdown until the next prayer, updating every second
final nextPrayerCountdownProvider = StreamProvider<Duration?>((ref) async* {
  // Yield immediately
  yield _calculateRemainingTime(ref);

  // Then yield every second
  yield* Stream.periodic(const Duration(seconds: 1), (_) {
    return _calculateRemainingTime(ref);
  });
});

Duration? _calculateRemainingTime(Ref ref) {
  final prayerTimes = ref.read(prayerTimesProvider).value;
  if (prayerTimes == null) return null;

  final nextPrayer = prayerTimes.nextPrayer();
  final nextTime = prayerTimes.timeForPrayer(nextPrayer);

  if (nextTime == null) return null;

  final diff = nextTime.difference(DateTime.now());
  return diff.isNegative ? Duration.zero : diff;
}
