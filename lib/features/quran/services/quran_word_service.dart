import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../../../core/localization/locale_controller.dart';
import '../models/quran_models.dart';

final quranWordRemoteServiceProvider = Provider<QuranWordRemoteService>((ref) {
  return QuranWordRemoteService();
});

final quranWordServiceProvider = Provider<QuranWordService>((ref) {
  return QuranWordService(
    remoteService: ref.read(quranWordRemoteServiceProvider),
  );
});

final quranWordsForSurahProvider =
    FutureProvider.family<Map<int, List<QuranWord>>, int>((ref, surahNumber) {
  return ref.read(quranWordServiceProvider).wordsForSurah(surahNumber);
});

class QuranWordService {
  QuranWordService({
    AssetBundle? assetBundle,
    this.remoteService,
    this.surahAssetDirectory = 'assets/data/quran_words',
    this.fallbackAssetPath = 'assets/data/quran_words_sample.json',
  }) : _assetBundle = assetBundle ?? rootBundle;

  final AssetBundle _assetBundle;
  final QuranWordRemoteService? remoteService;
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
    final remoteWords = await remoteService?.wordsForSurah(surahNumber);
    if (remoteWords != null && remoteWords.isNotEmpty) {
      return remoteWords;
    }

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

class QuranWordRemoteService {
  QuranWordRemoteService({
    http.Client? client,
    Future<Directory> Function()? cacheDirectoryLoader,
    DateTime Function()? now,
    this.apiBaseUrl = 'https://api.quran.com/api/v4',
    this.cacheTtl = const Duration(days: 7),
  })  : _client = client ?? http.Client(),
        _cacheDirectoryLoader = cacheDirectoryLoader ?? _defaultCacheDirectory,
        _now = now ?? DateTime.now;

  static const _maxPerPage = 50;

  final http.Client _client;
  final Future<Directory> Function() _cacheDirectoryLoader;
  final DateTime Function() _now;
  final String apiBaseUrl;
  final Duration cacheTtl;

  Future<Map<int, List<QuranWord>>?> wordsForSurah(int surahNumber) async {
    if (surahNumber < 1 || surahNumber > 114) return null;

    final cacheDirectory = await _cacheDirectoryLoader();
    await _deleteExpiredCache(cacheDirectory);

    final cached = await _readFreshCache(cacheDirectory, surahNumber);
    if (cached != null) return cached;

    try {
      final words = await _fetchSurahWords(surahNumber);
      if (words.isEmpty) return null;
      await _writeCache(cacheDirectory, surahNumber, words);
      return _groupByAyah(words);
    } catch (_) {
      return null;
    }
  }

  Future<List<QuranWord>> _fetchSurahWords(int surahNumber) async {
    final words = <QuranWord>[];
    var page = 1;

    while (true) {
      final uri =
          Uri.parse('$apiBaseUrl/verses/by_chapter/$surahNumber').replace(
        queryParameters: {
          'language': 'en',
          'words': 'true',
          'word_fields': 'text_uthmani,transliteration,translation',
          'fields': 'verse_key',
          'per_page': '$_maxPerPage',
          'page': '$page',
        },
      );
      final response = await _client.get(
        uri,
        headers: const {
          'Accept': 'application/json',
        },
      );
      if (response.statusCode != 200) {
        throw const FormatException('Quran word API request failed.');
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map) {
        throw const FormatException('Unexpected Quran word API response.');
      }
      final verses = decoded['verses'];
      if (verses is! List) {
        throw const FormatException(
            'Missing verses in Quran word API response.');
      }
      for (final verse in verses) {
        if (verse is! Map) continue;
        final ayahNumber = verse['verse_number'];
        if (ayahNumber is! int) continue;
        final verseWords = verse['words'];
        if (verseWords is! List) continue;

        var position = 1;
        for (final rawWord in verseWords) {
          if (rawWord is! Map) continue;
          if (rawWord['char_type_name'] != 'word') continue;

          final arabic =
              (rawWord['text_uthmani'] ?? rawWord['text'] ?? '').toString();
          final transliteration = _nestedText(rawWord['transliteration']);
          final translation = _nestedText(rawWord['translation']);
          if (arabic.trim().isEmpty || translation.trim().isEmpty) {
            continue;
          }

          words.add(
            QuranWord(
              surahNumber: surahNumber,
              ayahNumber: ayahNumber,
              position: position,
              arabic: arabic,
              transliteration: transliteration,
              translations: {'en': translation},
            ),
          );
          position += 1;
        }
      }

      final pagination = decoded['pagination'];
      final nextPage = pagination is Map ? pagination['next_page'] : null;
      if (nextPage == null) break;
      if (nextPage is! int) {
        throw const FormatException('Invalid Quran word API pagination.');
      }
      page = nextPage;
    }

    return words;
  }

  Future<Map<int, List<QuranWord>>?> _readFreshCache(
    Directory cacheDirectory,
    int surahNumber,
  ) async {
    final file = _cacheFile(cacheDirectory, surahNumber);
    if (!await file.exists()) return null;

    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map) return null;

    final cachedAtRaw = decoded['cachedAt'];
    final cachedAt =
        cachedAtRaw is String ? DateTime.tryParse(cachedAtRaw) : null;
    if (cachedAt == null || _now().difference(cachedAt) >= cacheTtl) {
      await file.delete();
      return null;
    }

    final entries = decoded['words'];
    if (entries is! List) return null;
    final words = <QuranWord>[];
    for (final entry in entries) {
      if (entry is! Map) continue;
      final word = QuranWord.fromJson(Map<String, dynamic>.from(entry));
      if (word.surahNumber == surahNumber) {
        words.add(word);
      }
    }
    return _groupByAyah(words);
  }

  Future<void> _writeCache(
    Directory cacheDirectory,
    int surahNumber,
    List<QuranWord> words,
  ) async {
    await cacheDirectory.create(recursive: true);
    final file = _cacheFile(cacheDirectory, surahNumber);
    await file.writeAsString(
      jsonEncode({
        'cachedAt': _now().toUtc().toIso8601String(),
        'words': words.map(_wordToJson).toList(),
      }),
    );
  }

  Future<void> _deleteExpiredCache(Directory cacheDirectory) async {
    if (!await cacheDirectory.exists()) return;
    await for (final entity in cacheDirectory.list()) {
      if (entity is! File || !entity.path.endsWith('.json')) continue;
      try {
        final decoded = jsonDecode(await entity.readAsString());
        final cachedAtRaw = decoded is Map ? decoded['cachedAt'] : null;
        final cachedAt =
            cachedAtRaw is String ? DateTime.tryParse(cachedAtRaw) : null;
        if (cachedAt == null || _now().difference(cachedAt) >= cacheTtl) {
          await entity.delete();
        }
      } catch (_) {
        await entity.delete();
      }
    }
  }

  File _cacheFile(Directory cacheDirectory, int surahNumber) {
    return File(
      '${cacheDirectory.path}/surah_${surahNumber.toString().padLeft(3, '0')}.json',
    );
  }

  static Future<Directory> _defaultCacheDirectory() async {
    final root = await getTemporaryDirectory();
    return Directory('${root.path}/quran_words');
  }
}

Map<int, List<QuranWord>> _groupByAyah(List<QuranWord> words) {
  final ayahWords = <int, List<QuranWord>>{};
  for (final word in words) {
    ayahWords.putIfAbsent(word.ayahNumber, () => <QuranWord>[]).add(word);
  }
  for (final words in ayahWords.values) {
    words.sort((a, b) => a.position.compareTo(b.position));
  }
  return ayahWords;
}

Map<String, dynamic> _wordToJson(QuranWord word) {
  return {
    'surahNumber': word.surahNumber,
    'ayahNumber': word.ayahNumber,
    'position': word.position,
    'arabic': word.arabic,
    'transliteration': word.transliteration,
    'translations': word.translations,
  };
}

String _nestedText(Object? value) {
  if (value is Map) {
    return (value['text'] ?? '').toString().trim();
  }
  return '';
}

String quranWordTranslationForCurrentLocale(QuranWord word) {
  return word.translationFor(AppLocaleController.effectiveLanguageCode());
}
