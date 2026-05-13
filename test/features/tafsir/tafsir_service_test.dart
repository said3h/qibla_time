import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:qibla_time/features/tafsir/models/tafsir_entry.dart';
import 'package:qibla_time/features/tafsir/services/tafsir_api_client.dart';
import 'package:qibla_time/features/tafsir/services/tafsir_cache_service.dart';
import 'package:qibla_time/features/tafsir/services/tafsir_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TafsirService', () {
    const service = TafsirService();

    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

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

    test('uses the optional API client when tafsir id is configured', () async {
      final apiClient = TafsirApiClient(
        httpClient: MockClient((request) async {
          return http.Response(
            jsonEncode({
              'tafsir': {
                'verses': {
                  '2:255': {'id': 255},
                },
                'resource_id': 169,
                'resource_name': 'Fake Tafsir',
                'text': '<p>Fake tafsir body.</p>',
              },
            }),
            200,
          );
        }),
        baseUri: Uri.parse('https://api.example.test/api/v4'),
      );
      final apiBackedService = TafsirService(apiClient: apiClient);

      final result = await apiBackedService.getTafsir(
        surahNumber: 2,
        ayahNumber: 255,
        languageCode: 'EN-us',
        tafsirId: '169',
      );

      expect(result.source, TafsirLoadSource.api);
      expect(result.entry, isNotNull);
      expect(result.entry!.languageCode, 'en');
      expect(result.entry!.verseKey, '2:255');
    });

    test('returns cache before calling API', () async {
      var didCallApi = false;
      const cacheService = TafsirCacheService();
      await cacheService.write(
        const TafsirEntry(
          tafsirId: '169',
          resourceName: 'Cached Tafsir',
          languageCode: 'en',
          surahNumber: 2,
          ayahNumber: 255,
          text: '<p>Cached tafsir body.</p>',
          source: 'Quran Foundation API',
        ),
      );
      final apiClient = TafsirApiClient(
        httpClient: MockClient((request) async {
          didCallApi = true;
          return http.Response('{}', 200);
        }),
      );
      final apiBackedService = TafsirService(
        apiClient: apiClient,
        cacheService: cacheService,
      );

      final result = await apiBackedService.getTafsir(
        surahNumber: 2,
        ayahNumber: 255,
        languageCode: 'en',
        tafsirId: '169',
      );

      expect(result.source, TafsirLoadSource.cache);
      expect(result.entry!.resourceName, 'Cached Tafsir');
      expect(didCallApi, isFalse);
    });

    test('writes valid API responses to cache', () async {
      const cacheService = TafsirCacheService();
      final apiClient = TafsirApiClient(
        httpClient: MockClient((request) async {
          return http.Response(
            jsonEncode({
              'tafsir': {
                'verses': {
                  '2:255': {'id': 255},
                },
                'resource_id': 169,
                'resource_name': 'Fake Tafsir',
                'text': '<p>Fresh tafsir body.</p>',
              },
            }),
            200,
          );
        }),
      );
      final apiBackedService = TafsirService(
        apiClient: apiClient,
        cacheService: cacheService,
      );

      final result = await apiBackedService.getTafsir(
        surahNumber: 2,
        ayahNumber: 255,
        languageCode: 'en',
        tafsirId: '169',
      );
      final cached = await cacheService.read(
        languageCode: 'en',
        tafsirId: '169',
        surahNumber: 2,
        ayahNumber: 255,
      );

      expect(result.source, TafsirLoadSource.api);
      expect(cached, isNotNull);
      expect(cached!.text, '<p>Fresh tafsir body.</p>');
    });

    test('does not cache invalid API responses', () async {
      const cacheService = TafsirCacheService();
      final apiClient = TafsirApiClient(
        httpClient: MockClient((request) async {
          return http.Response(
            jsonEncode({
              'tafsir': {
                'verses': {
                  '2:255': {'id': 255},
                },
                'resource_id': 169,
                'resource_name': 'Fake Tafsir',
                'text': 'Too many requests, please try again later',
              },
            }),
            200,
          );
        }),
      );
      final apiBackedService = TafsirService(
        apiClient: apiClient,
        cacheService: cacheService,
      );

      final result = await apiBackedService.getTafsir(
        surahNumber: 2,
        ayahNumber: 255,
        languageCode: 'en',
        tafsirId: '169',
      );
      final cached = await cacheService.read(
        languageCode: 'en',
        tafsirId: '169',
        surahNumber: 2,
        ayahNumber: 255,
      );

      expect(result.source, TafsirLoadSource.unavailable);
      expect(result.errorCode, 'invalid_tafsir_text');
      expect(cached, isNull);
    });

    test('uses default tafsir id when request does not include one', () async {
      late http.Request capturedRequest;
      final apiClient = TafsirApiClient(
        httpClient: MockClient((request) async {
          capturedRequest = request;
          return http.Response(
            jsonEncode({
              'tafsir': {
                'verses': {
                  '1:1': {'id': 1},
                },
                'resource_id': 169,
                'resource_name': 'Fake Tafsir',
                'text': '<p>Fake tafsir body.</p>',
              },
            }),
            200,
          );
        }),
        baseUri: Uri.parse('https://api.example.test/api/v4'),
      );
      final apiBackedService = TafsirService(
        apiClient: apiClient,
        defaultTafsirId: '169',
      );

      final result = await apiBackedService.getTafsir(
        surahNumber: 1,
        ayahNumber: 1,
        languageCode: 'en',
      );

      expect(result.source, TafsirLoadSource.api);
      expect(capturedRequest.url.path, '/api/v4/tafsirs/169/by_ayah/1:1');
    });

    test('does not call API when tafsir id is missing', () async {
      var didCallApi = false;
      final apiClient = TafsirApiClient(
        httpClient: MockClient((request) async {
          didCallApi = true;
          return http.Response('{}', 200);
        }),
      );
      final apiBackedService = TafsirService(apiClient: apiClient);

      final result = await apiBackedService.getTafsir(
        surahNumber: 2,
        ayahNumber: 255,
        languageCode: 'es',
      );

      expect(result.source, TafsirLoadSource.unavailable);
      expect(result.errorCode, 'missing_tafsir_id');
      expect(didCallApi, isFalse);
    });

    test('does not call API when tafsir id is not a resource id', () async {
      var didCallApi = false;
      final apiClient = TafsirApiClient(
        httpClient: MockClient((request) async {
          didCallApi = true;
          return http.Response('{}', 200);
        }),
      );
      final apiBackedService = TafsirService(apiClient: apiClient);

      final result = await apiBackedService.getTafsir(
        surahNumber: 2,
        ayahNumber: 255,
        languageCode: 'es',
        tafsirId: 'spanish-abridged',
      );

      expect(result.source, TafsirLoadSource.unavailable);
      expect(result.errorCode, 'missing_tafsir_id');
      expect(didCallApi, isFalse);
    });

    test('keeps API technical errors out of tafsir content', () async {
      final apiClient = TafsirApiClient(
        httpClient: MockClient((request) async {
          return http.Response(
            jsonEncode({
              'tafsir': {
                'verses': {
                  '1:1': {'id': 1},
                },
                'resource_id': 169,
                'resource_name': 'Fake Tafsir',
                'text': 'Too many requests, please try again later',
              },
            }),
            200,
          );
        }),
      );
      final apiBackedService = TafsirService(apiClient: apiClient);

      final result = await apiBackedService.getTafsir(
        surahNumber: 1,
        ayahNumber: 1,
        languageCode: 'en',
        tafsirId: '169',
      );

      expect(result.source, TafsirLoadSource.unavailable);
      expect(result.errorCode, 'invalid_tafsir_text');
      expect(result.entry, isNull);
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
