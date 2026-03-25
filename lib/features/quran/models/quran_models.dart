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

enum SurahLoadSource {
  online,
  offline,
  placeholder,
}

class SurahLoadResult {
  const SurahLoadResult({
    required this.detail,
    required this.source,
  });

  final SurahDetail detail;
  final SurahLoadSource source;

  bool get usedFallback => source != SurahLoadSource.online;
}

class QuranReadingPoint {
  const QuranReadingPoint({
    required this.surahNumber,
    required this.surahNameLatin,
    required this.surahNameArabic,
    required this.ayahNumber,
    required this.savedAt,
  });

  final int surahNumber;
  final String surahNameLatin;
  final String surahNameArabic;
  final int ayahNumber;
  final DateTime savedAt;

  factory QuranReadingPoint.fromJson(Map<String, dynamic> json) {
    return QuranReadingPoint(
      surahNumber: json['surahNumber'] as int,
      surahNameLatin: json['surahNameLatin'] as String,
      surahNameArabic: json['surahNameArabic'] as String,
      ayahNumber: json['ayahNumber'] as int,
      savedAt: DateTime.tryParse(json['savedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'surahNumber': surahNumber,
      'surahNameLatin': surahNameLatin,
      'surahNameArabic': surahNameArabic,
      'ayahNumber': ayahNumber,
      'savedAt': savedAt.toIso8601String(),
    };
  }

  String get shortLabel => '$surahNameLatin · aya $ayahNumber';
}
