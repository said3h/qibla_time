import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:adhan/adhan.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';

class CalculationMetadata {
  final CalculationMethod method;
  final Madhab madhab;
  final double fajrAngle;
  final double ishaAngle;
  final String methodName;

  CalculationMetadata({
    required this.method,
    required this.madhab,
    required this.fajrAngle,
    required this.ishaAngle,
    required this.methodName,
  });
}

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

    final prefs = await SharedPreferences.getInstance();
    
    // Try to get fresh position
    try {
      Position freshPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 5),
      );
      
      // Save for offline fallback
      await prefs.setDouble('last_lat', freshPosition.latitude);
      await prefs.setDouble('last_lng', freshPosition.longitude);
      
      return freshPosition;
    } catch (e) {
      // Fallback to cached coordinates
      final lat = prefs.getDouble('last_lat');
      final lng = prefs.getDouble('last_lng');
      
      if (lat != null && lng != null) {
        debugPrint('Using cached location for offline prayer times');
        return Position(
          latitude: lat,
          longitude: lng,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );
      }
      return null;
    }
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

// Provides the chosen Madhab
final madhabProvider = FutureProvider<Madhab>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final isHanafi = prefs.getBool('madhab_hanafi') ?? false;
  return isHanafi ? Madhab.hanafi : Madhab.shafi;
});

// Provides the regional time offset in minutes
final timeOffsetProvider = FutureProvider<int>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getInt('time_offset') ?? 0;
});

// Combines location, date and method to output the PrayerTimes object
final prayerTimesProvider = FutureProvider<PrayerTimes?>((ref) async {
  final position = await ref.watch(locationProvider.future);
  final metadata = await ref.watch(calculationMetadataProvider.future);
  final offset = await ref.watch(timeOffsetProvider.future);
  
  if (position == null || metadata == null) return null;

  final coordinates = Coordinates(position.latitude, position.longitude);
  final params = metadata.method.getParameters();
  params.madhab = metadata.madhab;

  final date = DateComponents.from(DateTime.now());
  final baseTimes = PrayerTimes(coordinates, date, params);
  
  if (offset == 0) return baseTimes;

  // Apply regional offset if defined
  // Since PrayerTimes itself is immutable and doesn't expose an easy 'addMinutes' globally,
  // we could wrap it or re-instantiate if adhan library allows offsets in params.
  // The adhan library's CalculationParameters actually has an 'adjustments' Map!
  params.adjustments.fajr = offset;
  params.adjustments.dhuhr = offset;
  params.adjustments.asr = offset;
  params.adjustments.maghrib = offset;
  params.adjustments.isha = offset;
  
  return PrayerTimes(coordinates, date, params);
});

final calculationMetadataProvider = FutureProvider<CalculationMetadata?>((ref) async {
  final method = await ref.watch(calculationMethodProvider.future);
  final madhab = await ref.watch(madhabProvider.future);
  
  final params = method.getParameters();
  
  String name = "Custom";
  switch(method) {
    case CalculationMethod.muslim_world_league: name = "Muslim World League"; break;
    case CalculationMethod.egyptian: name = "Egyptian General Authority"; break;
    case CalculationMethod.karachi: name = "University of Islamic Sciences, Karachi"; break;
    case CalculationMethod.umm_al_qura: name = "Umm al-Qura University, Makkah"; break;
    case CalculationMethod.dubai: name = "Dubai / UAE"; break;
    case CalculationMethod.moon_sighting_committee: name = "Moonsighting Committee"; break;
    case CalculationMethod.north_america: name = "ISNA (North America)"; break;
    case CalculationMethod.tehran: name = "Institute of Geophysics, Tehran"; break;
    case CalculationMethod.turkey: name = "Turkey (Diyanet)"; break;
    case CalculationMethod.singapore: name = "MUIS (Singapore)"; break;
    case CalculationMethod.kuwait: name = "Kuwait"; break;
    case CalculationMethod.qatar: name = "Qatar"; break;
    default: name = method.toString().split('.').last.replaceAll('_', ' ').toUpperCase();
  }

  return CalculationMetadata(
    method: method,
    madhab: madhab,
    fajrAngle: params.fajrAngle ?? 0,
    ishaAngle: params.ishaAngle,
    methodName: name,
  );
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
