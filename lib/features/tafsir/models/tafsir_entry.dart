class TafsirEntry {
  const TafsirEntry({
    required this.tafsirId,
    required this.resourceName,
    required this.languageCode,
    required this.surahNumber,
    required this.ayahNumber,
    required this.text,
    required this.source,
    this.sourceUrl,
    this.author,
    this.translator,
    this.publisher,
    this.license,
    this.cachedAt,
  });

  final String tafsirId;
  final String resourceName;
  final String languageCode;
  final int surahNumber;
  final int ayahNumber;
  final String text;
  final String source;
  final String? sourceUrl;
  final String? author;
  final String? translator;
  final String? publisher;
  final String? license;
  final DateTime? cachedAt;

  String get verseKey => '$surahNumber:$ayahNumber';

  bool get hasUsableText => text.trim().isNotEmpty;

  TafsirEntry copyWith({
    String? tafsirId,
    String? resourceName,
    String? languageCode,
    int? surahNumber,
    int? ayahNumber,
    String? text,
    String? source,
    String? sourceUrl,
    String? author,
    String? translator,
    String? publisher,
    String? license,
    DateTime? cachedAt,
  }) {
    return TafsirEntry(
      tafsirId: tafsirId ?? this.tafsirId,
      resourceName: resourceName ?? this.resourceName,
      languageCode: languageCode ?? this.languageCode,
      surahNumber: surahNumber ?? this.surahNumber,
      ayahNumber: ayahNumber ?? this.ayahNumber,
      text: text ?? this.text,
      source: source ?? this.source,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      author: author ?? this.author,
      translator: translator ?? this.translator,
      publisher: publisher ?? this.publisher,
      license: license ?? this.license,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }

  factory TafsirEntry.fromJson(Map<String, dynamic> json) {
    return TafsirEntry(
      tafsirId: json['tafsirId']?.toString() ?? '',
      resourceName: json['resourceName']?.toString() ?? '',
      languageCode: json['languageCode']?.toString() ?? '',
      surahNumber: _readInt(json['surahNumber']),
      ayahNumber: _readInt(json['ayahNumber']),
      text: json['text']?.toString() ?? '',
      source: json['source']?.toString() ?? '',
      sourceUrl: json['sourceUrl']?.toString(),
      author: json['author']?.toString(),
      translator: json['translator']?.toString(),
      publisher: json['publisher']?.toString(),
      license: json['license']?.toString(),
      cachedAt: DateTime.tryParse(json['cachedAt']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tafsirId': tafsirId,
      'resourceName': resourceName,
      'languageCode': languageCode,
      'surahNumber': surahNumber,
      'ayahNumber': ayahNumber,
      'text': text,
      'source': source,
      if (sourceUrl != null) 'sourceUrl': sourceUrl,
      if (author != null) 'author': author,
      if (translator != null) 'translator': translator,
      if (publisher != null) 'publisher': publisher,
      if (license != null) 'license': license,
      if (cachedAt != null) 'cachedAt': cachedAt!.toIso8601String(),
    };
  }

  static int _readInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

enum TafsirLoadSource {
  offline,
  api,
  online,
  cache,
  unavailable,
}

class TafsirLoadResult {
  const TafsirLoadResult({
    required this.source,
    this.entry,
    this.errorCode,
    this.debugInfo,
  });

  final TafsirLoadSource source;
  final TafsirEntry? entry;
  final String? errorCode;
  final TafsirDebugInfo? debugInfo;

  bool get hasEntry => entry != null && entry!.hasUsableText;
}

class TafsirDebugInfo {
  const TafsirDebugInfo({
    this.provider,
    this.resourceId,
    this.url,
    this.statusCode,
    this.fallbackReason = 'unknown',
    this.htmlLength,
  });

  final String? provider;
  final String? resourceId;
  final String? url;
  final int? statusCode;
  final String fallbackReason;
  final int? htmlLength;

  bool get receivedHtml => htmlLength != null && htmlLength! > 0;

  TafsirDebugInfo copyWith({
    String? provider,
    String? resourceId,
    String? url,
    int? statusCode,
    String? fallbackReason,
    int? htmlLength,
  }) {
    return TafsirDebugInfo(
      provider: provider ?? this.provider,
      resourceId: resourceId ?? this.resourceId,
      url: url ?? this.url,
      statusCode: statusCode ?? this.statusCode,
      fallbackReason: fallbackReason ?? this.fallbackReason,
      htmlLength: htmlLength ?? this.htmlLength,
    );
  }
}

class TafsirRequest {
  const TafsirRequest({
    required this.surahNumber,
    required this.ayahNumber,
    required this.languageCode,
    this.tafsirId,
  });

  final int surahNumber;
  final int ayahNumber;
  final String languageCode;
  final String? tafsirId;

  String get verseKey => '$surahNumber:$ayahNumber';

  @override
  bool operator ==(Object other) {
    return other is TafsirRequest &&
        other.surahNumber == surahNumber &&
        other.ayahNumber == ayahNumber &&
        other.languageCode == languageCode &&
        other.tafsirId == tafsirId;
  }

  @override
  int get hashCode => Object.hash(
        surahNumber,
        ayahNumber,
        languageCode,
        tafsirId,
      );
}
