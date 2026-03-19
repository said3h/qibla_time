class SurahSummary {
  const SurahSummary({
    required this.number,
    required this.nameArabic,
    required this.nameLatin,
    required this.revelationType,
    required this.ayahCount,
  });

  final int number;
  final String nameArabic;
  final String nameLatin;
  final String revelationType;
  final int ayahCount;
}

class SurahAyah {
  const SurahAyah({
    required this.numberInSurah,
    required this.arabic,
    required this.translation,
  });

  final int numberInSurah;
  final String arabic;
  final String translation;
}

class SurahDetail {
  const SurahDetail({
    required this.summary,
    required this.ayahs,
  });

  final SurahSummary summary;
  final List<SurahAyah> ayahs;
}
