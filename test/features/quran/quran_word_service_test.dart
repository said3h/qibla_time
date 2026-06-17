import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:qibla_time/features/quran/services/quran_word_service.dart';

void main() {
  group('QuranWordService', () {
    test('loads an existing surah file and groups words by ayah', () async {
      final bundle = _FakeQuranWordAssetBundle({
        'assets/data/quran_words/surah_112.json': '''
{
  "surahNumber": 112,
  "words": [
    {
      "ayahNumber": 1,
      "position": 2,
      "arabic": "هُوَ",
      "transliteration": "",
      "translations": {}
    },
    {
      "surahNumber": 112,
      "ayahNumber": 1,
      "position": 1,
      "arabic": "قُلْ",
      "transliteration": "",
      "translations": {}
    },
    {
      "surahNumber": 112,
      "ayahNumber": 2,
      "position": 1,
      "arabic": "اللَّهُ",
      "transliteration": "",
      "translations": {}
    }
  ]
}
''',
      });
      final service = QuranWordService(assetBundle: bundle);

      final wordsByAyah = await service.wordsForSurah(112);

      expect(wordsByAyah.keys, containsAll([1, 2]));
      expect(wordsByAyah[1]!.map((word) => word.arabic), ['قُلْ', 'هُوَ']);
      expect(wordsByAyah[2]!.single.arabic, 'اللَّهُ');
      expect(bundle.loadedKeys, ['assets/data/quran_words/surah_112.json']);
    });

    test('falls back to the sample asset when surah file is missing', () async {
      final bundle = _FakeQuranWordAssetBundle({
        'assets/data/quran_words_sample.json': '''
{
  "words": [
    {
      "surahNumber": 1,
      "ayahNumber": 1,
      "position": 1,
      "arabic": "بِسْمِ",
      "transliteration": "Bismi",
      "translations": { "en": "In the name" }
    }
  ]
}
''',
      });
      final service = QuranWordService(assetBundle: bundle);

      final wordsByAyah = await service.wordsForSurah(1);

      expect(wordsByAyah[1]!.single.arabic, 'بِسْمِ');
      expect(bundle.loadedKeys, [
        'assets/data/quran_words/surah_001.json',
        'assets/data/quran_words_sample.json',
      ]);
    });

    test('returns empty words when surah and fallback assets are missing',
        () async {
      final service = QuranWordService(
        assetBundle: _FakeQuranWordAssetBundle(const {}),
      );

      final wordsByAyah = await service.wordsForSurah(2);

      expect(wordsByAyah, isEmpty);
    });

    test('caches each requested surah without loading unrelated surahs',
        () async {
      final bundle = _FakeQuranWordAssetBundle({
        'assets/data/quran_words/surah_112.json': '''
{
  "surahNumber": 112,
  "words": [
    {
      "surahNumber": 112,
      "ayahNumber": 1,
      "position": 1,
      "arabic": "قُلْ",
      "transliteration": "",
      "translations": {}
    }
  ]
}
''',
        'assets/data/quran_words/surah_113.json': '''
{
  "surahNumber": 113,
  "words": [
    {
      "surahNumber": 113,
      "ayahNumber": 1,
      "position": 1,
      "arabic": "قُلْ",
      "transliteration": "",
      "translations": {}
    }
  ]
}
''',
      });
      final service = QuranWordService(assetBundle: bundle);

      await service.wordsForSurah(112);
      await service.wordsForSurah(112);

      expect(bundle.loadedKeys, ['assets/data/quran_words/surah_112.json']);
    });

    test('falls back to local surah data when remote API fails', () async {
      final bundle = _FakeQuranWordAssetBundle({
        'assets/data/quran_words/surah_112.json': '''
{
  "words": [
    {
      "surahNumber": 112,
      "ayahNumber": 1,
      "position": 1,
      "arabic": "قُلْ",
      "transliteration": "qul",
      "translations": { "en": "Say" }
    }
  ]
}
''',
      });
      final cacheDirectory = await Directory.systemTemp.createTemp(
        'quran_word_fallback_test_',
      );
      addTearDown(() => cacheDirectory.delete(recursive: true));
      final remoteService = QuranWordRemoteService(
        client: MockClient((_) async => http.Response('server error', 500)),
        cacheDirectoryLoader: () async => cacheDirectory,
      );
      final service = QuranWordService(
        assetBundle: bundle,
        remoteService: remoteService,
      );

      final wordsByAyah = await service.wordsForSurah(112);

      expect(wordsByAyah[1]!.single.transliteration, 'qul');
      expect(bundle.loadedKeys, ['assets/data/quran_words/surah_112.json']);
    });
  });

  group('QuranWordRemoteService', () {
    test('deletes expired cache and fetches fresh API data', () async {
      final cacheDirectory = await Directory.systemTemp.createTemp(
        'quran_word_cache_test_',
      );
      addTearDown(() => cacheDirectory.delete(recursive: true));
      final cacheFile = File('${cacheDirectory.path}/surah_112.json');
      await cacheFile.writeAsString('''
{
  "cachedAt": "2026-01-01T00:00:00.000Z",
  "words": [
    {
      "surahNumber": 112,
      "ayahNumber": 1,
      "position": 1,
      "arabic": "قديم",
      "transliteration": "old",
      "translations": { "en": "old" }
    }
  ]
}
''');
      var requestCount = 0;
      final service = QuranWordRemoteService(
        now: () => DateTime.utc(2026, 1, 9),
        cacheDirectoryLoader: () async => cacheDirectory,
        client: MockClient((request) async {
          requestCount += 1;
          expect(request.url.queryParameters['words'], 'true');
          return http.Response(
            '''
{
  "verses": [
    {
      "verse_number": 1,
      "words": [
        {
          "position": 1,
          "char_type_name": "word",
          "text_uthmani": "\\u0642\\u064f\\u0644\\u0652",
          "translation": { "text": "Say" },
          "transliteration": { "text": "qul" }
        },
        {
          "position": 2,
          "char_type_name": "end",
          "text_uthmani": "\\u0661",
          "translation": { "text": "(1)" },
          "transliteration": { "text": null }
        }
      ]
    }
  ],
  "pagination": {
    "next_page": null
  }
}
''',
            200,
          );
        }),
      );

      final wordsByAyah = await service.wordsForSurah(112);

      expect(requestCount, 1);
      expect(wordsByAyah![1]!.single.arabic, 'قُلْ');
      expect(wordsByAyah[1]!.single.translationFor('en'), 'Say');
      final cached = await cacheFile.readAsString();
      expect(cached, contains('Say'));
      expect(cached, isNot(contains('old')));
    });
  });
}

class _FakeQuranWordAssetBundle extends AssetBundle {
  _FakeQuranWordAssetBundle(this.assets);

  final Map<String, String> assets;
  final List<String> loadedKeys = [];

  @override
  Future<ByteData> load(String key) {
    throw UnimplementedError('load is not used by this test bundle.');
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    loadedKeys.add(key);
    final value = assets[key];
    if (value == null) {
      throw FlutterError('Missing test asset: $key');
    }
    return value;
  }
}
