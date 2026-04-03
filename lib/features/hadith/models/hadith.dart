class Hadith {
  final int id;
  final String arabic;
  final String translation;
  final String reference;
  final String category;
  final String grade;

  const Hadith({
    required this.id,
    required this.arabic,
    required this.translation,
    required this.reference,
    required this.category,
    required this.grade,
  });

  factory Hadith.fromJson(Map<String, dynamic> json) {
    return Hadith(
      id: (json['id'] as num).toInt(),
      arabic: json['arabic'] as String? ?? '',
      translation:
          json['translation'] as String? ?? json['text'] as String? ?? '',
      reference: json['reference'] as String? ?? '',
      category: json['category'] as String? ?? '',
      grade: json['grade'] as String? ?? '',
    );
  }

  /// Creates a new Hadith with a different translation
  Hadith copyWithTranslation(String newTranslation) {
    return Hadith(
      id: id,
      arabic: arabic,
      translation: newTranslation,
      reference: reference,
      category: category,
      grade: grade,
    );
  }
}

class HadithMultilenguaje {
  final int id;
  final Map<String, HadithTranslation> translations;

  const HadithMultilenguaje({
    required this.id,
    required this.translations,
  });

  factory HadithMultilenguaje.fromJson(Map<String, dynamic> json) {
    final translations = <String, HadithTranslation>{};
    final translationsJson = json['translations'] as Map<String, dynamic>? ?? {};
    final sharedArabic = json['arabic'] as String? ?? '';

    translationsJson.forEach((langCode, data) {
      final merged = Map<String, dynamic>.from(data as Map<String, dynamic>);
      merged.putIfAbsent('arabic', () => sharedArabic);
      translations[langCode] = HadithTranslation.fromJson(merged);
    });

    // Fallback legacy support: if old format exists
    if (translations.isEmpty && json['arabic'] != null) {
      translations['es'] = HadithTranslation(
        arabic: json['arabic'] as String,
        translation: json['translation'] as String? ?? '',
        category: json['category'] as String? ?? '',
        reference: json['reference'] as String? ?? '',
        grade: json['grade'] as String? ?? '',
      );
    }

    return HadithMultilenguaje(
      id: (json['id'] as num).toInt(),
      translations: translations,
    );
  }

  Hadith toHadith(String languageCode, {String fallbackLanguage = 'es'}) {
    final translation = translations[languageCode] ?? translations[fallbackLanguage];
    
    if (translation == null) {
      throw Exception('No se encontró traducción para el hadiz $id en $languageCode ni en fallback $fallbackLanguage');
    }

    return Hadith(
      id: id,
      arabic: translation.arabic,
      translation: translation.translation,
      reference: translation.reference,
      category: translation.category,
      grade: translation.grade,
    );
  }

  /// Gets the hadith with fallback strategy
  Hadith getHadith(String languageCode, {String fallbackLanguage = 'es'}) {
    final translation = translations[languageCode] ?? translations[fallbackLanguage];
    
    if (translation == null) {
      // Return first available translation or throw
      final firstEntry = translations.values.firstOrNull;
      if (firstEntry == null) {
        throw Exception('Hadiz $id sin traducciones disponibles');
      }
      return Hadith(
        id: id,
        arabic: firstEntry.arabic,
        translation: firstEntry.translation,
        reference: firstEntry.reference,
        category: firstEntry.category,
        grade: firstEntry.grade,
      );
    }

    return Hadith(
      id: id,
      arabic: translation.arabic,
      translation: translation.translation,
      reference: translation.reference,
      category: translation.category,
      grade: translation.grade,
    );
  }

  bool hasLanguage(String languageCode) => translations.containsKey(languageCode);
}

class HadithTranslation {
  final String arabic;
  final String translation;
  final String category;
  final String reference;
  final String grade;

  const HadithTranslation({
    required this.arabic,
    required this.translation,
    required this.category,
    required this.reference,
    required this.grade,
  });

  factory HadithTranslation.fromJson(Map<String, dynamic> json) {
    return HadithTranslation(
      arabic: json['arabic'] as String? ?? '',
      translation:
          json['translation'] as String? ?? json['text'] as String? ?? '',
      category: json['category'] as String? ?? '',
      reference: json['reference'] as String? ?? '',
      grade: json['grade'] as String? ?? '',
    );
  }
}
