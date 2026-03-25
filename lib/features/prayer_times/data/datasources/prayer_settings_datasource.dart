import 'package:adhan/adhan.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/prayer_settings.dart';

class PrayerSettingsDataSource {
  Future<PrayerSettings> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final methodIndex =
        prefs.getInt(AppConstants.keyCalculationMethod) ??
        CalculationMethod.muslim_world_league.index;
    final method = CalculationMethod.values[methodIndex];
    final madhab = (prefs.getBool('madhab_hanafi') ?? false)
        ? Madhab.hanafi
        : Madhab.shafi;
    final offset = prefs.getInt('time_offset') ?? 0;
    final params = method.getParameters();

    return PrayerSettings(
      method: method,
      madhab: madhab,
      timeOffsetMinutes: offset,
      fajrAngle: params.fajrAngle,
      ishaAngle: params.ishaAngle ?? 0,
      methodName: _resolveMethodName(method),
    );
  }

  String _resolveMethodName(CalculationMethod method) {
    switch (method) {
      case CalculationMethod.muslim_world_league:
        return 'Muslim World League';
      case CalculationMethod.egyptian:
        return 'Egyptian General Authority';
      case CalculationMethod.karachi:
        return 'University of Islamic Sciences, Karachi';
      case CalculationMethod.umm_al_qura:
        return 'Umm al-Qura University, Makkah';
      case CalculationMethod.dubai:
        return 'Dubai / UAE';
      case CalculationMethod.moon_sighting_committee:
        return 'Moonsighting Committee';
      case CalculationMethod.north_america:
        return 'ISNA (North America)';
      case CalculationMethod.tehran:
        return 'Institute of Geophysics, Tehran';
      case CalculationMethod.turkey:
        return 'Turkey (Diyanet)';
      case CalculationMethod.singapore:
        return 'MUIS (Singapore)';
      case CalculationMethod.kuwait:
        return 'Kuwait';
      case CalculationMethod.qatar:
        return 'Qatar';
      default:
        return method.name.replaceAll('_', ' ').toUpperCase();
    }
  }
}
