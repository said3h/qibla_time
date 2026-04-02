class Dua {
  final String id;
  final String title;
  final String arabicText;
  final String transliteration;
  final String translation;
  final String category;
  final String? reference;
  final bool isFeatured;
  final String? source;
  final int? count;
  final List<String>? tags;
  final List<String>? times;

  const Dua({
    required this.id,
    required this.title,
    required this.arabicText,
    required this.transliteration,
    required this.translation,
    required this.category,
    this.reference,
    this.isFeatured = false,
    this.source,
    this.count,
    this.tags,
    this.times,
  });

  factory Dua.fromJson(Map<String, dynamic> json) {
    return Dua(
      id: json['id'] as String,
      title: json['title'] as String,
      arabicText: json['arabicText'] as String,
      transliteration: json['transliteration'] as String? ?? '',
      translation: json['translation'] as String? ?? '',
      category: json['category'] as String,
      reference: json['reference'] as String?,
      isFeatured: json['isFeatured'] as bool? ?? false,
      source: json['source'] as String?,
      count: json['count'] as int?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>(),
      times: (json['times'] as List<dynamic>?)?.cast<String>(),
    );
  }

  /// Creates a new Dua with a different translation
  Dua copyWithTranslation(String newTranslation) {
    return Dua(
      id: id,
      title: title,
      arabicText: arabicText,
      transliteration: transliteration,
      translation: newTranslation,
      category: category,
      reference: reference,
      isFeatured: isFeatured,
      source: source,
      count: count,
      tags: tags,
      times: times,
    );
  }
}

class DuaMultilenguaje {
  final String id;
  final Map<String, DuaTranslation> translations;

  const DuaMultilenguaje({
    required this.id,
    required this.translations,
  });

  factory DuaMultilenguaje.fromJson(Map<String, dynamic> json) {
    final translations = <String, DuaTranslation>{};
    final translationsJson = json['translations'] as Map<String, dynamic>? ?? {};
    
    translationsJson.forEach((langCode, data) {
      translations[langCode] = DuaTranslation.fromJson(data as Map<String, dynamic>);
    });

    // Fallback legacy support: if old format exists
    if (translations.isEmpty && json['arabicText'] != null) {
      translations['es'] = DuaTranslation(
        title: json['title'] as String? ?? '',
        arabicText: json['arabicText'] as String? ?? '',
        transliteration: json['transliteration'] as String? ?? '',
        translation: json['translation'] as String? ?? '',
        category: json['category'] as String? ?? '',
        reference: json['reference'] as String?,
        source: json['source'] as String?,
        count: json['count'] as int?,
        tags: (json['tags'] as List<dynamic>?)?.cast<String>(),
        times: (json['times'] as List<dynamic>?)?.cast<String>(),
        isFeatured: json['isFeatured'] as bool? ?? false,
      );
    }

    return DuaMultilenguaje(
      id: json['id'] as String,
      translations: translations,
    );
  }

  Dua toDua(String languageCode, {String fallbackLanguage = 'es'}) {
    final translation = translations[languageCode] ?? translations[fallbackLanguage];
    
    if (translation == null) {
      throw Exception('No se encontró traducción para el dua $id en $languageCode ni en fallback $fallbackLanguage');
    }

    return Dua(
      id: id,
      title: translation.title,
      arabicText: translation.arabicText,
      transliteration: translation.transliteration,
      translation: translation.translation,
      category: translation.category,
      reference: translation.reference,
      isFeatured: translation.isFeatured,
      source: translation.source,
      count: translation.count,
      tags: translation.tags,
      times: translation.times,
    );
  }

  /// Gets the dua with fallback strategy
  Dua getDua(String languageCode, {String fallbackLanguage = 'es'}) {
    final translation = translations[languageCode] ?? translations[fallbackLanguage];
    
    if (translation == null) {
      // Return first available translation or throw
      final firstEntry = translations.values.firstOrNull;
      if (firstEntry == null) {
        throw Exception('Dua $id sin traducciones disponibles');
      }
      return Dua(
        id: id,
        title: firstEntry.title,
        arabicText: firstEntry.arabicText,
        transliteration: firstEntry.transliteration,
        translation: firstEntry.translation,
        category: firstEntry.category,
        reference: firstEntry.reference,
        isFeatured: firstEntry.isFeatured,
        source: firstEntry.source,
        count: firstEntry.count,
        tags: firstEntry.tags,
        times: firstEntry.times,
      );
    }

    return Dua(
      id: id,
      title: translation.title,
      arabicText: translation.arabicText,
      transliteration: translation.transliteration,
      translation: translation.translation,
      category: translation.category,
      reference: translation.reference,
      isFeatured: translation.isFeatured,
      source: translation.source,
      count: translation.count,
      tags: translation.tags,
      times: translation.times,
    );
  }

  bool hasLanguage(String languageCode) => translations.containsKey(languageCode);
}

class DuaTranslation {
  final String title;
  final String arabicText;
  final String transliteration;
  final String translation;
  final String category;
  final String? reference;
  final String? source;
  final int? count;
  final List<String>? tags;
  final List<String>? times;
  final bool isFeatured;

  const DuaTranslation({
    required this.title,
    required this.arabicText,
    required this.transliteration,
    required this.translation,
    required this.category,
    this.reference,
    this.source,
    this.count,
    this.tags,
    this.times,
    this.isFeatured = false,
  });

  factory DuaTranslation.fromJson(Map<String, dynamic> json) {
    return DuaTranslation(
      title: json['title'] as String? ?? '',
      arabicText: json['arabicText'] as String? ?? '',
      transliteration: json['transliteration'] as String? ?? '',
      translation: json['translation'] as String? ?? '',
      category: json['category'] as String? ?? '',
      reference: json['reference'] as String?,
      source: json['source'] as String?,
      count: json['count'] as int?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>(),
      times: (json['times'] as List<dynamic>?)?.cast<String>(),
      isFeatured: json['isFeatured'] as bool? ?? false,
    );
  }
}