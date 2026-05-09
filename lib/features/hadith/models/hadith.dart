import '../../../core/services/logger_service.dart';

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
    final translation = HadithTranslation.extractTranslationText(json);
    return Hadith(
      id: (json['id'] as num).toInt(),
      arabic: json['arabic'] as String? ?? '',
      translation: isInvalidTranslationText(translation) ? '' : translation,
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
    final id = (json['id'] as num).toInt();
    final translationsJson = _extractTranslationsJson(json);
    final sharedArabic = json['arabic'] as String? ?? '';

    translationsJson.forEach((langCode, data) {
      if (data is! Map) return;
      final merged = Map<String, dynamic>.from(data as Map<String, dynamic>);
      final localizedArabic = (merged['arabic'] as String? ?? '').trim();
      if (localizedArabic.isEmpty && sharedArabic.trim().isNotEmpty) {
        merged['arabic'] = sharedArabic;
      } else {
        merged.putIfAbsent('arabic', () => sharedArabic);
      }
      final rawTranslationText =
          HadithTranslation.extractTranslationText(merged);
      final invalidReason = invalidTranslationReason(rawTranslationText);
      final translation = HadithTranslation.fromJson(merged);
      translations[langCode] = translation;
      if (invalidReason != null) {
        AppLogger.warning(
          'Invalid offline hadith translation discarded: '
          'collection="${translation.reference}", hadith=$id, '
          'language=$langCode, reason="$invalidReason"',
        );
      }
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
      id: id,
      translations: translations,
    );
  }

  Hadith toHadith(String languageCode, {String fallbackLanguage = 'es'}) {
    final normalizedLanguage = _normalizeLanguageCode(languageCode);
    final normalizedFallback = _normalizeLanguageCode(fallbackLanguage);
    final translation = _validTranslationFor(
      normalizedLanguage,
      fallbackLanguage: normalizedFallback,
      allowAnyLanguageFallback: false,
    );

    if (translation == null) {
      throw Exception(
          'No valid translation found for hadith $id in $languageCode');
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
    final normalizedLanguage = _normalizeLanguageCode(languageCode);
    final normalizedFallback = _normalizeLanguageCode(fallbackLanguage);
    final requestedTranslation = translations[normalizedLanguage];
    final requestedInvalidReason =
        invalidTranslationReason(requestedTranslation?.translation ?? '');

    if (requestedInvalidReason != null) {
      AppLogger.warning(
        'Discarding invalid hadith translation: '
        'collection="${requestedTranslation?.reference ?? ''}", hadith=$id, '
        'language=$normalizedLanguage, reason="$requestedInvalidReason"',
      );
    }

    final translation = _validTranslationFor(
      normalizedLanguage,
      fallbackLanguage: normalizedFallback,
      allowAnyLanguageFallback: normalizedLanguage != 'es',
    );

    if (translation == null) {
      AppLogger.warning(
        'No valid hadith translation available: hadith=$id, '
        'language=$normalizedLanguage, fallback=$normalizedFallback',
      );
      return Hadith(
        id: id,
        arabic: _bestArabicText(),
        translation: '',
        reference: _bestReference(),
        category: _bestCategory(),
        grade: _bestGrade(),
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

  bool hasLanguage(String languageCode) =>
      translations.containsKey(languageCode);

  HadithTranslation? _validTranslationFor(
    String languageCode, {
    required String fallbackLanguage,
    required bool allowAnyLanguageFallback,
  }) {
    final requested = translations[languageCode];
    if (requested != null && hasValidTranslationText(requested.translation)) {
      AppLogger.debug(
        'Using offline hadith translation: collection="${requested.reference}", '
        'hadith=$id, language=$languageCode',
      );
      return requested;
    }

    final fallback = translations[fallbackLanguage];
    if (fallback != null && hasValidTranslationText(fallback.translation)) {
      AppLogger.info(
        'Using fallback offline hadith translation: collection="${fallback.reference}", '
        'hadith=$id, requested=$languageCode, fallback=$fallbackLanguage',
      );
      return fallback;
    }

    if (!allowAnyLanguageFallback) {
      return null;
    }

    for (final entry in translations.entries) {
      if (hasValidTranslationText(entry.value.translation)) {
        AppLogger.info(
          'Using first valid offline hadith translation: '
          'collection="${entry.value.reference}", hadith=$id, '
          'requested=$languageCode, fallback=${entry.key}',
        );
        return entry.value;
      }
    }

    return null;
  }

  String _bestArabicText() {
    for (final translation in translations.values) {
      if (translation.arabic.trim().isNotEmpty) {
        return translation.arabic;
      }
    }
    return '';
  }

  String _bestReference() {
    for (final translation in translations.values) {
      if (translation.reference.trim().isNotEmpty) {
        return translation.reference;
      }
    }
    return '';
  }

  String _bestCategory() {
    for (final translation in translations.values) {
      if (translation.category.trim().isNotEmpty) {
        return translation.category;
      }
    }
    return '';
  }

  String _bestGrade() {
    for (final translation in translations.values) {
      if (translation.grade.trim().isNotEmpty) {
        return translation.grade;
      }
    }
    return '';
  }

  static Map<String, dynamic> _extractTranslationsJson(
    Map<String, dynamic> json,
  ) {
    final rawTranslations = json['translations'];
    if (rawTranslations is Map<String, dynamic>) {
      return rawTranslations;
    }

    if (rawTranslations is List) {
      final result = <String, dynamic>{};
      for (final item in rawTranslations) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);
        final language = _normalizeLanguageCode(
          (map['language'] ?? map['lang'] ?? map['locale'] ?? '').toString(),
        );
        if (language.isNotEmpty) {
          result[language] = map;
        }
      }
      return result;
    }

    final result = <String, dynamic>{};
    for (final language in const [
      'ar',
      'es',
      'en',
      'fr',
      'de',
      'it',
      'nl',
      'pt',
      'id',
      'ru',
      'tr',
      'spanish',
      'english',
      'french',
    ]) {
      final value = json[language];
      if (value is Map) {
        result[_normalizeLanguageCode(language)] = value;
      } else if (value is String && value.trim().isNotEmpty) {
        result[_normalizeLanguageCode(language)] = {
          'translation': value,
          'arabic': json['arabic'],
          'reference': json['reference'],
          'category': json['category'],
          'grade': json['grade'],
        };
      }
    }
    return result;
  }

  static String _normalizeLanguageCode(String languageCode) {
    final normalized = languageCode.trim().toLowerCase().replaceAll('_', '-');
    return switch (normalized) {
      'spanish' || 'es-es' || 'es' => 'es',
      'english' || 'en-us' || 'en-gb' || 'en' => 'en',
      'french' || 'fr-fr' || 'fr' => 'fr',
      'arabic' || 'ar' => 'ar',
      'german' || 'de-de' || 'de' => 'de',
      'italian' || 'it-it' || 'it' => 'it',
      'dutch' || 'nl-nl' || 'nl' => 'nl',
      'portuguese' || 'pt-br' || 'pt-pt' || 'pt' => 'pt',
      'indonesian' || 'id-id' || 'id' => 'id',
      'russian' || 'ru-ru' || 'ru' => 'ru',
      'turkish' || 'tr-tr' || 'tr' => 'tr',
      _ => normalized,
    };
  }
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
    final translation = extractTranslationText(json);
    return HadithTranslation(
      arabic: json['arabic'] as String? ?? '',
      translation: isInvalidTranslationText(translation) ? '' : translation,
      category: json['category'] as String? ?? '',
      reference: json['reference'] as String? ?? '',
      grade: json['grade'] as String? ?? '',
    );
  }

  static String extractTranslationText(Map<String, dynamic> json) {
    for (final key in const ['translation', 'text', 'content', 'body']) {
      final value = json[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    final translations = json['translations'];
    if (translations is Map) {
      for (final key in const [
        'es',
        'spanish',
        'en',
        'english',
        'fr',
        'french',
      ]) {
        final value = translations[key];
        if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }
        if (value is Map) {
          final nested =
              extractTranslationText(Map<String, dynamic>.from(value));
          if (nested.isNotEmpty) return nested;
        }
      }
    }

    if (translations is List) {
      for (final item in translations) {
        if (item is! Map) continue;
        final nested = extractTranslationText(Map<String, dynamic>.from(item));
        if (nested.isNotEmpty) return nested;
      }
    }

    return '';
  }
}

bool isInvalidTranslationText(String text) {
  return invalidTranslationReason(text) != null;
}

bool hasValidTranslationText(String text) {
  return text.trim().isNotEmpty && !isInvalidTranslationText(text);
}

String? invalidTranslationReason(String text) {
  final normalized = text.trim();
  if (normalized.isEmpty) return null;

  final upper = normalized.toUpperCase();
  const invalidFragments = [
    'QUERY LENGTH LIMIT',
    'MAX ALLOWED QUERY',
    'MAXIMUM ALLOWED QUERY',
    'TOO MANY REQUESTS',
    'RATE LIMIT',
    'REQUEST LIMIT',
    'REQUEST ENTITY TOO LARGE',
    '500 CHARS',
    'LIMITE DE COMPRIMENTO',
    'CONSULTA MÁXIMA',
    'CONSULTA MAXIMA',
    'CONSULTA MÁXIMA PERMITIDA',
    'CONSULTA MAXIMA PERMITIDA',
  ];

  for (final fragment in invalidFragments) {
    if (upper.contains(fragment)) {
      return fragment;
    }
  }

  if (upper.startsWith('ERROR:') || upper == 'ERROR') {
    return 'ERROR';
  }

  return null;
}
