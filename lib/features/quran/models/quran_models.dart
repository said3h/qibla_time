// lib/features/quran/models/quran_models.dart

class SurahSummary {
  final int    number;
  final String nameArabic;
  final String nameLatin;
  final String revelationType;  // 'Meccan' | 'Medinan'
  final int    ayahCount;

  const SurahSummary({
    required this.number,
    required this.nameArabic,
    required this.nameLatin,
    required this.revelationType,
    required this.ayahCount,
  });
}

class SurahAyah {
  final int    number;           // número global (1-6236)
  final int    numberInSurah;    // número dentro de la sura
  final String arabic;           // texto árabe
  final String transliteration;  // transliteración latina
  final String translation;      // traducción al español
  final String audioUrl;         // URL de audio (Mishary Alafasy)

  const SurahAyah({
    required this.number,
    required this.numberInSurah,
    required this.arabic,
    required this.transliteration,
    required this.translation,
    required this.audioUrl,
  });
}

class SurahDetail {
  final SurahSummary  summary;
  final List<SurahAyah> ayahs;

  const SurahDetail({
    required this.summary,
    required this.ayahs,
  });
}
