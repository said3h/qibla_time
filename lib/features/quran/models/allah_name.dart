class AllahName {
  const AllahName({
    required this.id,
    required this.arabic,
    required this.transliteration,
    required this.name,
    required this.description,
    required this.languageCode,
  });

  final int id;
  final String arabic;
  final String transliteration;
  final String name;
  final String description;
  final String languageCode;

  bool get hasDescription => description.trim().isNotEmpty;
}

class AllahNameMultilang {
  const AllahNameMultilang({
    required this.id,
    required this.arabic,
    required this.transliteration,
    required this.translations,
  });

  final int id;
  final String arabic;
  final String transliteration;
  final Map<String, AllahNameTranslation> translations;

  factory AllahNameMultilang.fromJson(Map<String, dynamic> json) {
    final translationsJson =
        json['translations'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final translations = <String, AllahNameTranslation>{};

    translationsJson.forEach((languageCode, value) {
      translations[languageCode] = AllahNameTranslation.fromJson(
        value as Map<String, dynamic>,
      );
    });

    return AllahNameMultilang(
      id: (json['id'] as num).toInt(),
      arabic: json['arabic'] as String? ?? '',
      transliteration: json['transliteration'] as String? ?? '',
      translations: translations,
    );
  }

  AllahName getName(
    String languageCode, {
    String fallbackLanguage = 'es',
  }) {
    final translation = translations[languageCode] ??
        translations[fallbackLanguage] ??
        translations.values.firstOrNull;

    if (translation == null) {
      throw Exception('Allah name $id has no translations available');
    }

    return AllahName(
      id: id,
      arabic: arabic,
      transliteration: transliteration,
      name: translation.name,
      description: translation.description,
      languageCode: languageCode,
    );
  }
}

class AllahNameTranslation {
  const AllahNameTranslation({
    required this.name,
    required this.description,
  });

  final String name;
  final String description;

  factory AllahNameTranslation.fromJson(Map<String, dynamic> json) {
    return AllahNameTranslation(
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }
}
