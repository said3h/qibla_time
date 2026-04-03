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
  final String canonicalCategory;

  const DuaMultilenguaje({
    required this.id,
    required this.translations,
    required this.canonicalCategory,
  });

  factory DuaMultilenguaje.fromJson(Map<String, dynamic> json) {
    final translations = <String, DuaTranslation>{};
    final translationsJson = json['translations'] as Map<String, dynamic>? ?? {};
    final sharedArabicText = json['arabicText'] as String? ?? '';
    final sharedTransliteration = json['transliteration'] as String? ?? '';
    final sharedReference = json['reference'] as String?;
    final sharedSource = json['source'] as String?;
    final sharedCount = (json['count'] as num?)?.toInt();
    final sharedTags = (json['tags'] as List<dynamic>?)?.cast<String>();
    final sharedTimes = (json['times'] as List<dynamic>?)?.cast<String>();

    translationsJson.forEach((langCode, data) {
      final merged = Map<String, dynamic>.from(data as Map<String, dynamic>);
      merged.putIfAbsent('arabicText', () => sharedArabicText);
      merged.putIfAbsent('transliteration', () => sharedTransliteration);
      if (sharedReference != null) {
        merged.putIfAbsent('reference', () => sharedReference);
      }
      if (sharedSource != null) {
        merged.putIfAbsent('source', () => sharedSource);
      }
      if (sharedCount != null) {
        merged.putIfAbsent('count', () => sharedCount);
      }
      if (sharedTags != null) {
        merged.putIfAbsent('tags', () => sharedTags);
      }
      if (sharedTimes != null) {
        merged.putIfAbsent('times', () => sharedTimes);
      }
      translations[langCode] = DuaTranslation.fromJson(merged);
    });

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
      canonicalCategory: _resolveCanonicalCategory(translations),
    );
  }

  Dua toDua(String languageCode, {String fallbackLanguage = 'es'}) {
    final translation = translations[languageCode] ?? translations[fallbackLanguage];

    if (translation == null) {
      throw Exception(
        'No translation found for dua $id in $languageCode or fallback $fallbackLanguage',
      );
    }

    return Dua(
      id: id,
      title: translation.title,
      arabicText: translation.arabicText,
      transliteration: translation.transliteration,
      translation: translation.translation,
      category: canonicalCategory,
      reference: translation.reference,
      isFeatured: translation.isFeatured,
      source: translation.source,
      count: translation.count,
      tags: translation.tags,
      times: translation.times,
    );
  }

  Dua getDua(String languageCode, {String fallbackLanguage = 'es'}) {
    final translation = translations[languageCode] ?? translations[fallbackLanguage];

    if (translation == null) {
      final firstEntry = translations.values.firstOrNull;
      if (firstEntry == null) {
        throw Exception('Dua $id has no translations available');
      }

      return Dua(
        id: id,
        title: firstEntry.title,
        arabicText: firstEntry.arabicText,
        transliteration: firstEntry.transliteration,
        translation: firstEntry.translation,
        category: canonicalCategory,
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
      category: canonicalCategory,
      reference: translation.reference,
      isFeatured: translation.isFeatured,
      source: translation.source,
      count: translation.count,
      tags: translation.tags,
      times: translation.times,
    );
  }

  bool hasLanguage(String languageCode) => translations.containsKey(languageCode);

  static String _resolveCanonicalCategory(
    Map<String, DuaTranslation> translations,
  ) {
    final preferredCategory = translations['es']?.category ??
        translations['en']?.category ??
        translations.values.firstOrNull?.category ??
        '';
    final normalized = preferredCategory.trim().toLowerCase();

    return switch (normalized) {
      'morning' => 'morning',
      'night' => 'night',
      'sleep' => 'sleep',
      'wudu' => 'wudu',
      'ablution' => 'wudu',
      'after_prayer' => 'after_prayer',
      'after prayer' => 'after_prayer',
      'zikr' => 'zikr',
      'dhikr' => 'zikr',
      'travel' => 'travel',
      'food' => 'food',
      'sickness' => 'sickness',
      'illness' => 'sickness',
      'protection' => 'protection',
      'repentance' => 'repentance',
      'mosque' => 'mosque',
      'rain' => 'rain',
      'stress' => 'stress',
      'hardship' => 'stress',
      'gratitude' => 'gratitude',
      'parents' => 'parents',
      'family' => 'parents',
      'hajj' => 'hajj',
      'hajj & umrah' => 'hajj',
      _ => normalized,
    };
  }
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
