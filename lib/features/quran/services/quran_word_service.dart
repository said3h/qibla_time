import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/locale_controller.dart';
import '../models/quran_models.dart';

final quranWordServiceProvider = Provider<QuranWordService>((ref) {
  return QuranWordService();
});

final quranWordsForSurahProvider =
    FutureProvider.family<Map<int, List<QuranWord>>, int>((ref, surahNumber) {
  return ref.read(quranWordServiceProvider).wordsForSurah(surahNumber);
});

class QuranWordService {
  QuranWordService({
    AssetBundle? assetBundle,
    this.assetPath = 'assets/data/quran_words_sample.json',
  }) : _assetBundle = assetBundle ?? rootBundle;

  final AssetBundle _assetBundle;
  final String assetPath;
  Map<int, Map<int, List<QuranWord>>>? _cache;

  Future<Map<int, List<QuranWord>>> wordsForSurah(int surahNumber) async {
    final cache = await _loadCache();
    return cache[surahNumber] ?? const {};
  }

  Future<List<QuranWord>> wordsForAyah({
    required int surahNumber,
    required int ayahNumber,
  }) async {
    final surahWords = await wordsForSurah(surahNumber);
    return surahWords[ayahNumber] ?? const [];
  }

  Future<Map<int, Map<int, List<QuranWord>>>> _loadCache() async {
    final existing = _cache;
    if (existing != null) return existing;

    final raw = await _assetBundle.loadString(assetPath);
    final decoded = jsonDecode(raw);
    final entries = decoded is Map ? decoded['words'] : null;
    if (entries is! List) {
      _cache = const {};
      return _cache!;
    }

    final cache = <int, Map<int, List<QuranWord>>>{};
    for (final entry in entries) {
      if (entry is! Map) continue;
      final word = QuranWord.fromJson(Map<String, dynamic>.from(entry));
      cache
          .putIfAbsent(word.surahNumber, () => <int, List<QuranWord>>{})
          .putIfAbsent(word.ayahNumber, () => <QuranWord>[])
          .add(word);
    }

    for (final ayahs in cache.values) {
      for (final words in ayahs.values) {
        words.sort((a, b) => a.position.compareTo(b.position));
      }
    }

    _cache = cache;
    return cache;
  }
}

String quranWordTranslationForCurrentLocale(QuranWord word) {
  return word.translationFor(AppLocaleController.effectiveLanguageCode());
}
