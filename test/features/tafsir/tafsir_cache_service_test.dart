import 'package:flutter_test/flutter_test.dart';
import 'package:qibla_time/features/tafsir/models/tafsir_entry.dart';
import 'package:qibla_time/features/tafsir/services/tafsir_cache_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TafsirCacheService', () {
    const service = TafsirCacheService();

    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('builds stable tafsir cache keys', () {
      final key = TafsirCacheService.cacheKey(
        languageCode: 'ES_es',
        tafsirId: '169',
        surahNumber: 2,
        ayahNumber: 255,
      );

      expect(key, 'tafsir:es:169:2:255');
    });

    test('writes and reads valid tafsir entries', () async {
      await service.write(
        const TafsirEntry(
          tafsirId: '169',
          resourceName: 'Fake Tafsir',
          languageCode: 'es',
          surahNumber: 2,
          ayahNumber: 255,
          text: '<p>Cached tafsir.</p>',
          source: 'Quran Foundation API',
        ),
      );

      final cached = await service.read(
        languageCode: 'es',
        tafsirId: '169',
        surahNumber: 2,
        ayahNumber: 255,
      );

      expect(cached, isNotNull);
      expect(cached!.verseKey, '2:255');
      expect(cached.text, '<p>Cached tafsir.</p>');
      expect(cached.cachedAt, isNotNull);
    });

    test('does not write empty tafsir entries', () async {
      await service.write(
        const TafsirEntry(
          tafsirId: '169',
          resourceName: 'Fake Tafsir',
          languageCode: 'es',
          surahNumber: 2,
          ayahNumber: 255,
          text: '',
          source: 'Quran Foundation API',
        ),
      );

      final cached = await service.read(
        languageCode: 'es',
        tafsirId: '169',
        surahNumber: 2,
        ayahNumber: 255,
      );

      expect(cached, isNull);
    });
  });
}
