import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/tafsir_entry.dart';

class TafsirApiClient {
  TafsirApiClient({
    http.Client? httpClient,
    Uri? baseUri,
    this.authToken,
    this.clientId,
    this.timeout = const Duration(seconds: 8),
  })  : _httpClient = httpClient ?? http.Client(),
        _baseUri = baseUri ?? Uri.parse('https://api.quran.com/api/v4');

  final http.Client _httpClient;
  final Uri _baseUri;
  final String? authToken;
  final String? clientId;
  final Duration timeout;

  Future<TafsirLoadResult> fetchAyahTafsir({
    required String tafsirId,
    required int surahNumber,
    required int ayahNumber,
    required String languageCode,
  }) async {
    if (!_isValidAyahReference(surahNumber, ayahNumber)) {
      return const TafsirLoadResult(
        source: TafsirLoadSource.unavailable,
        errorCode: 'invalid_ayah_reference',
      );
    }

    final uri = buildAyahTafsirUri(
      tafsirId: tafsirId,
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
    );

    try {
      final response = await _httpClient
          .get(
            uri,
            headers: _headers,
          )
          .timeout(timeout);

      if (response.statusCode != 200) {
        return TafsirLoadResult(
          source: TafsirLoadSource.unavailable,
          errorCode: _httpErrorCode(response.statusCode, response.bodyBytes),
        );
      }

      return parseAyahTafsirResponse(
        response.bodyBytes,
        tafsirId: tafsirId,
        surahNumber: surahNumber,
        ayahNumber: ayahNumber,
        languageCode: languageCode,
      );
    } catch (_) {
      return const TafsirLoadResult(
        source: TafsirLoadSource.unavailable,
        errorCode: 'tafsir_api_unavailable',
      );
    }
  }

  Uri buildAyahTafsirUri({
    required String tafsirId,
    required int surahNumber,
    required int ayahNumber,
  }) {
    final verseKey = '$surahNumber:$ayahNumber';
    return _baseUri.replace(
      pathSegments: [
        ..._baseUri.pathSegments.where((segment) => segment.isNotEmpty),
        'tafsirs',
        tafsirId,
        'by_ayah',
        verseKey,
      ],
      queryParameters: const {
        'fields': 'verse_key,resource_name,language_name,id',
      },
    );
  }

  TafsirLoadResult parseAyahTafsirResponse(
    List<int> bodyBytes, {
    required String tafsirId,
    required int surahNumber,
    required int ayahNumber,
    required String languageCode,
  }) {
    final verseKey = '$surahNumber:$ayahNumber';
    final decoded = _decodeJsonMap(bodyBytes);
    if (decoded == null) {
      return const TafsirLoadResult(
        source: TafsirLoadSource.unavailable,
        errorCode: 'invalid_tafsir_response',
      );
    }

    final tafsir = _readMap(decoded, 'tafsir');
    if (tafsir == null) {
      return TafsirLoadResult(
        source: TafsirLoadSource.unavailable,
        errorCode: _readApiErrorType(decoded) ?? 'missing_tafsir_payload',
      );
    }

    final verses = _readMap(tafsir, 'verses');
    if (verses != null && verses.isNotEmpty && !verses.containsKey(verseKey)) {
      return const TafsirLoadResult(
        source: TafsirLoadSource.unavailable,
        errorCode: 'invalid_verse_alignment',
      );
    }

    final text = tafsir['text']?.toString().trim() ?? '';
    if (text.isEmpty) {
      return const TafsirLoadResult(
        source: TafsirLoadSource.unavailable,
        errorCode: 'empty_tafsir_text',
      );
    }

    if (_containsTechnicalError(text)) {
      return const TafsirLoadResult(
        source: TafsirLoadSource.unavailable,
        errorCode: 'invalid_tafsir_text',
      );
    }

    final translatedName = _readMap(tafsir, 'translated_name');
    return TafsirLoadResult(
      source: TafsirLoadSource.online,
      entry: TafsirEntry(
        tafsirId: tafsir['resource_id']?.toString() ?? tafsirId,
        resourceName:
            tafsir['resource_name']?.toString().trim().isNotEmpty == true
                ? tafsir['resource_name'].toString().trim()
                : translatedName?['name']?.toString().trim().isNotEmpty == true
                    ? translatedName!['name'].toString().trim()
                    : tafsirId,
        languageCode: languageCode.trim().toLowerCase(),
        surahNumber: surahNumber,
        ayahNumber: ayahNumber,
        text: text,
        source: 'Quran Foundation API',
        sourceUrl: _baseUri.toString(),
      ),
    );
  }

  Map<String, String> get _headers {
    final headers = <String, String>{
      'Accept': 'application/json',
    };
    final normalizedAuthToken = authToken?.trim();
    if (normalizedAuthToken != null && normalizedAuthToken.isNotEmpty) {
      headers['x-auth-token'] = normalizedAuthToken;
    }
    final normalizedClientId = clientId?.trim();
    if (normalizedClientId != null && normalizedClientId.isNotEmpty) {
      headers['x-client-id'] = normalizedClientId;
    }
    return headers;
  }

  Map<String, dynamic>? _decodeJsonMap(List<int> bodyBytes) {
    try {
      final decoded = json.decode(utf8.decode(bodyBytes));
      if (decoded is! Map) return null;
      return Map<String, dynamic>.from(decoded);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic>? _readMap(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is! Map) return null;
    return Map<String, dynamic>.from(value);
  }

  String? _readApiErrorType(Map<String, dynamic> data) {
    final type = data['type']?.toString().trim();
    if (type != null && type.isNotEmpty) return 'api_$type';
    final message = data['message']?.toString().trim();
    if (message != null && message.isNotEmpty) return 'api_error';
    return null;
  }

  String _httpErrorCode(int statusCode, List<int> bodyBytes) {
    final decoded = _decodeJsonMap(bodyBytes);
    final apiType = decoded == null ? null : _readApiErrorType(decoded);
    return apiType ?? 'api_http_$statusCode';
  }

  bool _isValidAyahReference(int surahNumber, int ayahNumber) {
    return surahNumber >= 1 &&
        surahNumber <= 114 &&
        ayahNumber >= 1 &&
        ayahNumber <= 286;
  }

  bool _containsTechnicalError(String text) {
    final normalized = text.toLowerCase();
    const blockedMarkers = [
      'query length limit',
      'max allowed query',
      'too many requests',
      'rate limit',
      'translation failed',
      'unauthorized',
      'forbidden',
      'gateway_timeout',
      'service_unavailable',
      'stack trace',
      '<!doctype',
      '<html',
    ];

    return blockedMarkers.any(normalized.contains);
  }
}
