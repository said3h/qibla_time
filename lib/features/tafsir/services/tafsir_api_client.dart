import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/tafsir_entry.dart';

enum TafsirApiSource {
  quranFoundation,
  qulPreview,
}

class TafsirApiClient {
  TafsirApiClient({
    http.Client? httpClient,
    Uri? baseUri,
    this.source = TafsirApiSource.quranFoundation,
    this.authToken,
    this.clientId,
    this.timeout = const Duration(seconds: 8),
  })  : _httpClient = httpClient ?? http.Client(),
        _baseUri = baseUri ?? Uri.parse('https://api.quran.com/api/v4');

  final http.Client _httpClient;
  final Uri _baseUri;
  final TafsirApiSource source;
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
        debugInfo: TafsirDebugInfo(fallbackReason: 'validation_rejected'),
      );
    }

    final uri = buildAyahTafsirUri(
      tafsirId: tafsirId,
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
    );
    _debugLog(
      'QuranTafsirRequest',
      'url=$uri source=$source tafsirId=$tafsirId '
          'ayah=$surahNumber:$ayahNumber language=$languageCode',
    );

    try {
      final response = await _httpClient
          .get(
            uri,
            headers: _headers,
          )
          .timeout(timeout);
      _debugLog(
        'QuranTafsirResponse',
        'url=$uri statusCode=${response.statusCode} '
            'bytes=${response.bodyBytes.length} '
            'contentType=${response.headers['content-type'] ?? 'unknown'}',
      );

      if (response.statusCode != 200) {
        _debugLog(
          'QuranTafsirApi',
          'fallback reason=http_${response.statusCode} url=$uri',
        );
        return TafsirLoadResult(
          source: TafsirLoadSource.unavailable,
          errorCode: _httpErrorCode(response.statusCode, response.bodyBytes),
          debugInfo: _debugInfo(
            tafsirId: tafsirId,
            url: uri.toString(),
            statusCode: response.statusCode,
            fallbackReason: 'http_error',
            htmlLength: _htmlLength(response),
          ),
        );
      }

      return switch (source) {
        TafsirApiSource.quranFoundation => parseAyahTafsirResponse(
            response.bodyBytes,
            tafsirId: tafsirId,
            surahNumber: surahNumber,
            ayahNumber: ayahNumber,
            languageCode: languageCode,
          ),
        TafsirApiSource.qulPreview => parseQulPreviewResponse(
            response.bodyBytes,
            tafsirId: tafsirId,
            surahNumber: surahNumber,
            ayahNumber: ayahNumber,
            languageCode: languageCode,
            sourceUrl: uri.toString(),
          ),
      };
    } catch (error) {
      _debugLog(
        'QuranTafsirApi',
        'fallback reason=request_exception url=$uri error=$error',
      );
      return TafsirLoadResult(
        source: TafsirLoadSource.unavailable,
        errorCode: 'tafsir_api_unavailable',
        debugInfo: _debugInfo(
          tafsirId: tafsirId,
          url: uri.toString(),
          fallbackReason: 'unknown',
        ),
      );
    }
  }

  Uri buildAyahTafsirUri({
    required String tafsirId,
    required int surahNumber,
    required int ayahNumber,
  }) {
    if (source == TafsirApiSource.qulPreview) {
      return _baseUri.replace(
        pathSegments: [
          ..._baseUri.pathSegments.where((segment) => segment.isNotEmpty),
          'resources',
          'tafsir',
          tafsirId,
        ],
        queryParameters: {
          'ayah': '$surahNumber:$ayahNumber',
        },
      );
    }

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
      _debugLog(
        'QuranTafsirParse',
        'fallback reason=invalid_json tafsirId=$tafsirId '
            'ayah=$surahNumber:$ayahNumber bytes=${bodyBytes.length}',
      );
      return const TafsirLoadResult(
        source: TafsirLoadSource.unavailable,
        errorCode: 'invalid_tafsir_response',
        debugInfo: TafsirDebugInfo(fallbackReason: 'parse_empty'),
      );
    }

    final tafsir = _readMap(decoded, 'tafsir');
    if (tafsir == null) {
      _debugLog(
        'QuranTafsirParse',
        'fallback reason=missing_tafsir_payload tafsirId=$tafsirId '
            'ayah=$surahNumber:$ayahNumber keys=${decoded.keys.join(',')}',
      );
      return TafsirLoadResult(
        source: TafsirLoadSource.unavailable,
        errorCode: _readApiErrorType(decoded) ?? 'missing_tafsir_payload',
        debugInfo: _debugInfo(
          tafsirId: tafsirId,
          fallbackReason: 'parse_empty',
        ),
      );
    }

    final verses = _readMap(tafsir, 'verses');
    if (verses != null && verses.isNotEmpty && !verses.containsKey(verseKey)) {
      _debugLog(
        'QuranTafsirParse',
        'fallback reason=invalid_verse_alignment expected=$verseKey '
            'found=${verses.keys.join(',')}',
      );
      return const TafsirLoadResult(
        source: TafsirLoadSource.unavailable,
        errorCode: 'invalid_verse_alignment',
        debugInfo: TafsirDebugInfo(fallbackReason: 'validation_rejected'),
      );
    }

    final text = tafsir['text']?.toString().trim() ?? '';
    if (text.isEmpty) {
      _debugLog(
        'QuranTafsirParse',
        'fallback reason=empty_tafsir_text tafsirId=$tafsirId '
            'ayah=$surahNumber:$ayahNumber',
      );
      return const TafsirLoadResult(
        source: TafsirLoadSource.unavailable,
        errorCode: 'empty_tafsir_text',
        debugInfo: TafsirDebugInfo(fallbackReason: 'parse_empty'),
      );
    }

    if (_containsTechnicalError(text)) {
      _debugLog(
        'QuranTafsirParse',
        'fallback reason=invalid_tafsir_text tafsirId=$tafsirId '
            'ayah=$surahNumber:$ayahNumber',
      );
      return const TafsirLoadResult(
        source: TafsirLoadSource.unavailable,
        errorCode: 'invalid_tafsir_text',
        debugInfo: TafsirDebugInfo(fallbackReason: 'validation_rejected'),
      );
    }

    final translatedName = _readMap(tafsir, 'translated_name');
    return TafsirLoadResult(
      source: TafsirLoadSource.api,
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

  TafsirLoadResult parseQulPreviewResponse(
    List<int> bodyBytes, {
    required String tafsirId,
    required int surahNumber,
    required int ayahNumber,
    required String languageCode,
    required String sourceUrl,
  }) {
    final html = _decodeUtf8(bodyBytes);
    if (html == null) {
      _debugLog(
        'QuranTafsirParse',
        'fallback reason=invalid_utf8_qul tafsirId=$tafsirId '
            'ayah=$surahNumber:$ayahNumber bytes=${bodyBytes.length}',
      );
      return TafsirLoadResult(
        source: TafsirLoadSource.unavailable,
        errorCode: 'invalid_tafsir_response',
        debugInfo: _debugInfo(
          tafsirId: tafsirId,
          url: sourceUrl,
          fallbackReason: 'parse_empty',
        ),
      );
    }
    _debugLog(
      'QuranTafsirParse',
      'qul htmlLength=${html.length} tafsirId=$tafsirId '
          'ayah=$surahNumber:$ayahNumber',
    );

    final title = _firstMatch(
      html,
      RegExp(r'<h1[^>]*>([\s\S]*?)</h1>', caseSensitive: false),
    );
    final previewHeading = _firstMatch(
      html,
      RegExp(r'<h2[^>]*>([\s\S]*?)</h2>', caseSensitive: false),
    );
    if (previewHeading != null &&
        !previewHeading.toLowerCase().contains('ayah $ayahNumber')) {
      _debugLog(
        'QuranTafsirParse',
        'fallback reason=qul_heading_mismatch ayah=$surahNumber:$ayahNumber '
            'heading=${_cleanHtmlText(previewHeading)}',
      );
      return TafsirLoadResult(
        source: TafsirLoadSource.unavailable,
        errorCode: 'invalid_verse_alignment',
        debugInfo: _debugInfo(
          tafsirId: tafsirId,
          url: sourceUrl,
          fallbackReason: 'validation_rejected',
          htmlLength: html.length,
        ),
      );
    }

    final textHtml = _firstMatch(
      html,
      RegExp(
        r'<div[^>]*class="[^"]*\btafsir\b[^"]*"[^>]*>([\s\S]*?)</div>',
        caseSensitive: false,
      ),
    );
    final text = _cleanHtmlText(textHtml);
    _debugLog(
      'QuranTafsirParse',
      'qul headingFound=${previewHeading != null} '
          'tafsirDivFound=${textHtml != null} textLength=${text.length} '
          'ayah=$surahNumber:$ayahNumber',
    );
    if (text.isEmpty) {
      _debugLog(
        'QuranTafsirParse',
        'fallback reason=empty_qul_tafsir_text tafsirId=$tafsirId '
            'ayah=$surahNumber:$ayahNumber',
      );
      return TafsirLoadResult(
        source: TafsirLoadSource.unavailable,
        errorCode: 'empty_tafsir_text',
        debugInfo: _debugInfo(
          tafsirId: tafsirId,
          url: sourceUrl,
          fallbackReason: 'parse_empty',
          htmlLength: html.length,
        ),
      );
    }

    if (_containsTechnicalError(text)) {
      _debugLog(
        'QuranTafsirParse',
        'fallback reason=invalid_qul_tafsir_text tafsirId=$tafsirId '
            'ayah=$surahNumber:$ayahNumber',
      );
      return TafsirLoadResult(
        source: TafsirLoadSource.unavailable,
        errorCode: 'invalid_tafsir_text',
        debugInfo: _debugInfo(
          tafsirId: tafsirId,
          url: sourceUrl,
          fallbackReason: 'validation_rejected',
          htmlLength: html.length,
        ),
      );
    }

    final resourceName = _cleanHtmlText(title);
    return TafsirLoadResult(
      source: TafsirLoadSource.api,
      entry: TafsirEntry(
        tafsirId: tafsirId,
        resourceName: resourceName.isNotEmpty
            ? resourceName
            : 'Spanish Abridged Explanation of the Quran',
        languageCode: languageCode.trim().toLowerCase(),
        surahNumber: surahNumber,
        ayahNumber: ayahNumber,
        text: text,
        source: 'QUL preview',
        sourceUrl: sourceUrl,
        publisher: 'Tafsir Center of Quranic Studies',
        license: 'TODO: Verify redistribution and caching terms before release',
      ),
    );
  }

  Map<String, String> get _headers {
    if (source == TafsirApiSource.qulPreview) {
      return const {
        'Accept': 'text/html,application/xhtml+xml',
        'User-Agent': 'QiblaTimeDebug/1.0',
      };
    }

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
      final decodedText = _decodeUtf8(bodyBytes);
      if (decodedText == null) return null;
      final decoded = json.decode(decodedText);
      if (decoded is! Map) return null;
      return Map<String, dynamic>.from(decoded);
    } catch (_) {
      return null;
    }
  }

  String? _decodeUtf8(List<int> bodyBytes) {
    try {
      return utf8.decode(bodyBytes);
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

  String? _firstMatch(String text, RegExp pattern) {
    return pattern.firstMatch(text)?.group(1);
  }

  String _cleanHtmlText(String? html) {
    if (html == null) return '';
    return html
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</p\s*>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  TafsirDebugInfo _debugInfo({
    required String tafsirId,
    String? url,
    int? statusCode,
    String fallbackReason = 'unknown',
    int? htmlLength,
  }) {
    return TafsirDebugInfo(
      provider: source == TafsirApiSource.qulPreview
          ? 'qul_preview'
          : 'quran_foundation',
      resourceId: tafsirId,
      url: url,
      statusCode: statusCode,
      fallbackReason: fallbackReason,
      htmlLength: htmlLength,
    );
  }

  int? _htmlLength(http.Response response) {
    final contentType = response.headers['content-type']?.toLowerCase() ?? '';
    if (!contentType.contains('html')) return null;
    return _decodeUtf8(response.bodyBytes)?.length;
  }

  void _debugLog(String tag, String message) {
    if (!kDebugMode) return;
    debugPrint('[$tag] $message');
  }
}
