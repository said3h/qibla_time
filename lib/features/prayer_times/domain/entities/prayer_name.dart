enum PrayerName {
  fajr,
  dhuhr,
  asr,
  maghrib,
  isha,
}

extension PrayerNameX on PrayerName {
  String get key => name;

  String get displayName {
    switch (this) {
      case PrayerName.fajr:
        return 'Fajr';
      case PrayerName.dhuhr:
        return 'Dhuhr';
      case PrayerName.asr:
        return 'Asr';
      case PrayerName.maghrib:
        return 'Maghrib';
      case PrayerName.isha:
        return 'Isha';
    }
  }

  String get displayNameArabic {
    switch (this) {
      case PrayerName.fajr:
        return 'فجر';
      case PrayerName.dhuhr:
        return 'ظهر';
      case PrayerName.asr:
        return 'عصر';
      case PrayerName.maghrib:
        return 'مغرب';
      case PrayerName.isha:
        return 'عشاء';
    }
  }

  String get displayNameRussian {
    switch (this) {
      case PrayerName.fajr:
        return 'Фаджр';
      case PrayerName.dhuhr:
        return 'Зухр';
      case PrayerName.asr:
        return 'Аср';
      case PrayerName.maghrib:
        return 'Магриб';
      case PrayerName.isha:
        return 'Иша';
    }
  }

  String localizedDisplayName(String languageCode) {
    return switch (languageCode) {
      'ar' => displayNameArabic,
      'ru' => displayNameRussian,
      _ => displayName,
    };
  }
}
