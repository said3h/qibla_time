import 'package:geocoding/geocoding.dart';

import '../../../../core/localization/locale_controller.dart';
import '../../domain/entities/prayer_location.dart';

class TravelLocationLabelDataSource {
  Future<String> resolveLabel(PrayerLocation location) async {
    try {
      final localeIdentifier = _localeIdentifierFor(
        AppLocaleController.effectiveLanguageCode(),
      );
      final placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
        localeIdentifier: localeIdentifier,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final locality = place.locality?.isNotEmpty == true
            ? place.locality
            : place.subAdministrativeArea;
        final country = place.country?.isNotEmpty == true ? place.country : null;
        final parts = [if (locality != null) locality, if (country != null) country];
        if (parts.isNotEmpty) {
          return parts.join(', ');
        }
      }
    } catch (_) {}

    return '${location.latitude.toStringAsFixed(2)}, ${location.longitude.toStringAsFixed(2)}';
  }

  String? _localeIdentifierFor(String languageCode) {
    return switch (languageCode) {
      'ar' => 'ar',
      'en' => 'en',
      'fr' => 'fr',
      _ => 'es',
    };
  }
}
