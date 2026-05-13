import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:qibla_time/features/tafsir/models/tafsir_entry.dart';
import 'package:qibla_time/features/tafsir/services/tafsir_api_client.dart';
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
