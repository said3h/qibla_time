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
    this.surahAssetDirectory = 'assets/data/quran_words',
    this.fallbackAssetPath = 'assets/data/quran_words_sample.json',
  }) : _assetBundle = assetBundle ?? rootBundle;

  final AssetBundle _assetBundle;
  final String surahAssetDirectory;
  final String fallbackAssetPath;
  final Map<int, Map<int, List<QuranWord>>> _surahCache = {};

  Future<Map<int, List<QuranWord>>> wordsForSurah(int surahNumber) async {
    final cached = _surahCache[surahNumber];
    if (cached != null) return cached;

    final words = await _loadSurahWords(surahNumber);
    _surahCache[surahNumber] = words;
    return words;
  }

  Future<List<QuranWord>> wordsForAyah({
    required int surahNumber,
    required int ayahNumber,
  }) async {
    final surahWords = await wordsForSurah(surahNumber);
    return surahWords[ayahNumber] ?? const [];
  }

  Future<Map<int, List<QuranWord>>> _loadSurahWords(int surahNumber) async {
    final raw = await _loadSurahAsset(surahNumber);
    if (raw == null) return const {};

    final dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      return const {};
    }
    final entries = decoded is Map ? decoded['words'] : null;
    if (entries is! List) {
      return const {};
    }

    final ayahWords = <int, List<QuranWord>>{};
    for (final entry in entries) {
      if (entry is! Map) continue;
      final wordJson = Map<String, dynamic>.from(entry);
      wordJson['surahNumber'] ??= surahNumber;
      final word = QuranWord.fromJson(wordJson);
      if (word.surahNumber != surahNumber) continue;
      ayahWords.putIfAbsent(word.ayahNumber, () => <QuranWord>[]).add(word);
    }

    for (final words in ayahWords.values) {
      words.sort((a, b) => a.position.compareTo(b.position));
    }

    return ayahWords;
  }

  Future<String?> _loadSurahAsset(int surahNumber) async {
    final path =
        '$surahAssetDirectory/surah_${surahNumber.toString().padLeft(3, '0')}.json';
    try {
      return await _assetBundle.loadString(path);
    } catch (_) {
      try {
        return await _assetBundle.loadString(fallbackAssetPath);
      } catch (_) {
        return null;
      }
    }
  }
}

String quranWordTranslationForCurrentLocale(QuranWord word) {
  return word.translationFor(AppLocaleController.effectiveLanguageCode());
}
