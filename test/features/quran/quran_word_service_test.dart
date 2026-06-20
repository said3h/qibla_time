
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
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
