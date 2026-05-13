import 'package:flutter_test/flutter_test.dart';
import 'package:qibla_time/features/tafsir/models/tafsir_entry.dart';
import 'package:qibla_time/features/tafsir/services/tafsir_service.dart';

void main() {
  group('TafsirService', () {
    const service = TafsirService();

    test('returns unavailable while no tafsir source is configured', () async {
      final result = await service.getTafsir(
        surahNumber: 2,
        ayahNumber: 255,
        languageCode: 'es',
        tafsirId: 'spanish-abridged',
      );

      expect(result.source, TafsirLoadSource.unavailable);
      expect(result.errorCode, 'tafsir_not_configured');
      expect(result.entry, isNull);
    });

    test('rejects invalid ayah references', () async {
      final result = await service.getTafsir(
        surahNumber: 115,
        ayahNumber: 1,
        languageCode: 'es',
      );

      expect(result.source, TafsirLoadSource.unavailable);
      expect(result.errorCode, 'invalid_ayah_reference');
    });

    test('validates a clean tafsir entry', () {
      final result = service.validateEntry(
        const TafsirEntry(
          tafsirId: 'test',
          resourceName: 'Test resource',
          languageCode: 'es',
          surahNumber: 1,
          ayahNumber: 1,
          text: 'Texto de prueba.',
          source: 'test',
        ),
      );

      expect(result.source, TafsirLoadSource.offline);
      expect(result.entry, isNotNull);
      expect(result.entry!.verseKey, '1:1');
    });

    test('rejects technical error text as tafsir content', () {
      final result = service.validateEntry(
        const TafsirEntry(
          tafsirId: 'test',
          resourceName: 'Test resource',
          languageCode: 'es',
          surahNumber: 1,
          ayahNumber: 1,
          text: 'Too many requests, please try again later',
          source: 'test',
        ),
      );

      expect(result.source, TafsirLoadSource.unavailable);
      expect(result.errorCode, 'invalid_tafsir_text');
    });
  });
}
