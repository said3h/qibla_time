import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:qibla_time/features/tafsir/models/tafsir_entry.dart';
import 'package:qibla_time/features/tafsir/services/tafsir_api_client.dart';

void main() {
  group('TafsirApiClient', () {
    test('builds an ayah tafsir URL without touching Quran UI', () {
      final client = TafsirApiClient(
        baseUri: Uri.parse('https://api.example.test/api/v4'),
      );

      final uri = client.buildAyahTafsirUri(
        tafsirId: '169',
        surahNumber: 2,
        ayahNumber: 255,
      );

      expect(
        uri.toString(),
        'https://api.example.test/api/v4/tafsirs/169/by_ayah/2:255'
        '?fields=verse_key%2Cresource_name%2Clanguage_name%2Cid',
      );
    });

    test('parses a successful Quran Foundation tafsir response', () {
      final client = TafsirApiClient(
        baseUri: Uri.parse('https://api.example.test/api/v4'),
      );
      final body = utf8.encode(
        jsonEncode({
          'tafsir': {
            'verses': {
              '2:255': {'id': 255},
            },
            'resource_id': 169,
            'resource_name': 'Fake Tafsir',
            'language_id': 38,
            'slug': 'fake-tafsir',
            'translated_name': {
              'name': 'Fake Tafsir',
              'language_name': 'english',
            },
            'text': '<p>Fake tafsir body for tests.</p>',
          },
        }),
      );

      final result = client.parseAyahTafsirResponse(
        body,
        tafsirId: '169',
        surahNumber: 2,
        ayahNumber: 255,
        languageCode: 'en',
      );

      expect(result.source, TafsirLoadSource.online);
      expect(result.entry, isNotNull);
      expect(result.entry!.tafsirId, '169');
      expect(result.entry!.resourceName, 'Fake Tafsir');
      expect(result.entry!.verseKey, '2:255');
      expect(result.entry!.text, '<p>Fake tafsir body for tests.</p>');
    });

    test('rejects shifted verse alignment in fake response', () {
      final client = TafsirApiClient();
      final body = utf8.encode(
        jsonEncode({
          'tafsir': {
            'verses': {
              '2:254': {'id': 254},
            },
            'resource_id': 169,
            'resource_name': 'Fake Tafsir',
            'text': '<p>Wrong ayah.</p>',
          },
        }),
      );

      final result = client.parseAyahTafsirResponse(
        body,
        tafsirId: '169',
        surahNumber: 2,
        ayahNumber: 255,
        languageCode: 'en',
      );

      expect(result.source, TafsirLoadSource.unavailable);
      expect(result.errorCode, 'invalid_verse_alignment');
      expect(result.entry, isNull);
    });

    test('maps API errors to unavailable results', () async {
      final client = TafsirApiClient(
        httpClient: MockClient((request) async {
          return http.Response(
            jsonEncode({
              'message': 'Too many requests, please try again later',
              'type': 'rate_limit_exceeded',
              'success': false,
            }),
            429,
          );
        }),
        baseUri: Uri.parse('https://api.example.test/api/v4'),
      );

      final result = await client.fetchAyahTafsir(
        tafsirId: '169',
        surahNumber: 2,
        ayahNumber: 255,
        languageCode: 'en',
      );

      expect(result.source, TafsirLoadSource.unavailable);
      expect(result.errorCode, 'api_rate_limit_exceeded');
    });

    test('sends optional Quran Foundation auth headers when configured',
        () async {
      late http.Request capturedRequest;
      final client = TafsirApiClient(
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
        authToken: 'token',
        clientId: 'client',
      );

      final result = await client.fetchAyahTafsir(
        tafsirId: '169',
        surahNumber: 1,
        ayahNumber: 1,
        languageCode: 'en',
      );

      expect(result.source, TafsirLoadSource.online);
      expect(capturedRequest.headers['x-auth-token'], 'token');
      expect(capturedRequest.headers['x-client-id'], 'client');
      expect(capturedRequest.headers['Accept'], 'application/json');
    });
  });
}
