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
  });

  final TafsirLoadSource source;
  final TafsirEntry? entry;
  final String? errorCode;

  bool get hasEntry => entry != null && entry!.hasUsableText;
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
