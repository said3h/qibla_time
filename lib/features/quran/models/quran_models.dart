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
    required this.number,
    required this.numberInSurah,
    required this.arabic,
    required this.translation,
  });

  final int number;
  final int numberInSurah;
  final String arabic;
  final String translation;

  String get audioUrl => 'https://cdn.islamic.network/quran/audio/128/ar.alafasy/$number.mp3';
}

class SurahDetail {
  const SurahDetail({
    required this.summary,
    required this.ayahs,
  });

  final SurahSummary summary;
  final List<SurahAyah> ayahs;
}
