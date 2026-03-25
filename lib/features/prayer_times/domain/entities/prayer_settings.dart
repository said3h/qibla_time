import 'package:adhan/adhan.dart';

class PrayerSettings {
  const PrayerSettings({
    required this.method,
    required this.madhab,
    required this.timeOffsetMinutes,
    required this.fajrAngle,
    required this.ishaAngle,
    required this.methodName,
  });

  final CalculationMethod method;
  final Madhab madhab;
  final int timeOffsetMinutes;
  final double fajrAngle;
  final double ishaAngle;
  final String methodName;
}
