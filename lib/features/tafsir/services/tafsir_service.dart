import 'package:flutter/foundation.dart';

import '../../../core/services/logger_service.dart';
import '../models/tafsir_entry.dart';
import 'tafsir_api_client.dart';
import 'tafsir_cache_service.dart';
import 'tafsir_config.dart';

class TafsirService {
  const TafsirService({
    TafsirApiClient? apiClient,
    TafsirCacheService? cacheService,
    String? defaultTafsirId,
    bool apiEnabled = false,
    String? providerName,
  })  : _apiClient = apiClient,
        _cacheService = cacheService,
        _defaultTafsirId = defaultTafsirId,
        _apiEnabled = apiEnabled,
        _providerName = providerName;

  final TafsirApiClient? _apiClient;
  final TafsirCacheService? _cacheService;
  final String? _defaultTafsirId;
  final bool _apiEnabled;
  final String? _providerName;

  Future<TafsirLoadResult> getTafsir({
    required int surahNumber,
    required int ayahNumber,
    required String languageCode,
    String? tafsirId,
  }) async {
    final normalizedLanguage = _normalizeLanguageCode(languageCode);
    final attempts = _resolveResourceAttempts(
      normalizedLanguage,
      requestedTafsirId: tafsirId,
    );
    final primaryAttempt = attempts.first;
    final normalizedTafsirId = primaryAttempt.resource.resourceId;
    _debugLanguage(
      requestedLanguageCode: languageCode,
      normalizedLanguageCode: normalizedLanguage,
      resourceId: normalizedTafsirId,
      resourceSource: primaryAttempt.resource.source,
    );
    _debugLog(
      'request language=$normalizedLanguage tafsirId=$normalizedTafsirId '
      'ayah=$surahNumber:$ayahNumber apiClient=${_apiClient != null} '
      'attempts=${attempts.map((attempt) => '${attempt.languageCode}:'
          '${attempt.resource.resourceId ?? 'none'}').join(',')}',
    );

    if (!_isValidAyahReference(surahNumber, ayahNumber)) {
      _debugLog(
        'fallback reason=invalid_ayah_reference ayah=$surahNumber:$ayahNumber',
      );
      AppLogger.warning(
        'Invalid tafsir request for $surahNumber:$ayahNumber.',
      );
      return TafsirLoadResult(
        source: TafsirLoadSource.unavailable,
        errorCode: 'invalid_ayah_reference',
        debugInfo: _debugInfo(
          resourceId: normalizedTafsirId,
          fallbackReason: 'validation_rejected',
        ),
      );
    }

    TafsirLoadResult? lastUnavailableResult;
    for (final attempt in attempts) {
      final attemptLanguage = attempt.languageCode;
      final attemptTafsirId = attempt.resource.resourceId;
      _debugLanguage(
        requestedLanguageCode: languageCode,
        normalizedLanguageCode: attemptLanguage,
        resourceId: attemptTafsirId,
        resourceSource: attempt.resource.source,
      );

      // TODO: Check verified offline tafsir assets once a legally usable
      // dataset is approved for bundling.
      final cachedEntry = await _readCache(
        languageCode: attemptLanguage,
        tafsirId: attemptTafsirId,
        surahNumber: surahNumber,
        ayahNumber: ayahNumber,
      );
      if (cachedEntry != null) {
        _debugLog(
          'cache hit language=$attemptLanguage tafsirId=$attemptTafsirId '
          'ayah=$surahNumber:$ayahNumber',
        );
        return TafsirLoadResult(
          source: TafsirLoadSource.cache,
          entry: cachedEntry,
        );
      }

      if (_apiClient == null) {
        lastUnavailableResult = TafsirLoadResult(
          source: TafsirLoadSource.unavailable,
          errorCode: 'tafsir_not_configured',
          debugInfo: _debugInfo(
            resourceId: attemptTafsirId,
            fallbackReason: _apiEnabled ? 'client_not_created' : 'api_disabled',
          ),
        );
        break;
      }

      if (attemptTafsirId == null) {
        _debugLog(
          'fallback reason=missing_tafsir_id language=$attemptLanguage '
          'ayah=$surahNumber:$ayahNumber',
        );
        lastUnavailableResult = TafsirLoadResult(
          source: TafsirLoadSource.unavailable,
          errorCode: 'missing_tafsir_id',
          debugInfo: _debugInfo(fallbackReason: 'missing_provider'),
        );
        continue;
      }

      final apiResult = await _apiClient.fetchAyahTafsir(
        tafsirId: attemptTafsirId,
        surahNumber: surahNumber,
        ayahNumber: ayahNumber,
        languageCode: attemptLanguage,
      );
      if (apiResult.hasEntry && apiResult.source == TafsirLoadSource.api) {
        final validation = validateEntry(apiResult.entry!);
        if (validation.source != TafsirLoadSource.offline) {
          _debugLog(
            'fallback reason=invalid_api_entry language=$attemptLanguage '
            'tafsirId=$attemptTafsirId '
            'ayah=$surahNumber:$ayahNumber '
            'validation=${validation.errorCode}',
          );
          AppLogger.warning(
            'Rejected unsafe tafsir response for $attemptLanguage '
            '$surahNumber:$ayahNumber using resource $attemptTafsirId.',
          );
          lastUnavailableResult = TafsirLoadResult(
            source: TafsirLoadSource.unavailable,
            errorCode: 'invalid_tafsir_text',
            debugInfo:
                (apiResult.debugInfo ?? _debugInfo(resourceId: attemptTafsirId))
                    .copyWith(fallbackReason: 'validation_rejected'),
          );
          continue;
        }

        await _cacheService?.write(apiResult.entry!);
        if (attemptLanguage != normalizedLanguage) {
          _debugLog(
            'fallback success requestedLanguage=$normalizedLanguage '
            'selectedLanguage=$attemptLanguage tafsirId=$attemptTafsirId '
            'ayah=$surahNumber:$ayahNumber',
          );
        }
        _debugLog(
          'success source=api language=$attemptLanguage '
          'tafsirId=$attemptTafsirId '
          'ayah=$surahNumber:$ayahNumber '
          'textLength=${apiResult.entry!.text.length}',
        );
        return apiResult;
      }

      _debugLog(
        'fallback reason=${apiResult.errorCode ?? 'no_entry'} '
        'language=$attemptLanguage tafsirId=$attemptTafsirId '
        'ayah=$surahNumber:$ayahNumber',
      );
      AppLogger.info(
        'Tafsir API returned ${apiResult.errorCode ?? 'no_entry'} for '
        '$attemptLanguage $surahNumber:$ayahNumber using resource '
        '$attemptTafsirId.',
      );

      final fallbackEntry = await _readCache(
        languageCode: attemptLanguage,
        tafsirId: attemptTafsirId,
        surahNumber: surahNumber,
        ayahNumber: ayahNumber,
      );
      if (fallbackEntry != null) {
        _debugLog(
          'cache fallback language=$attemptLanguage '
          'tafsirId=$attemptTafsirId '
          'ayah=$surahNumber:$ayahNumber',
        );
        return TafsirLoadResult(
          source: TafsirLoadSource.cache,
          entry: fallbackEntry,
        );
      }

      lastUnavailableResult = apiResult;
    }

    if (lastUnavailableResult != null) return lastUnavailableResult;

    // TODO: Enable online tafsir by resource when API credentials, selected
    // resource IDs, and cache terms are confirmed safe for mobile usage.
    _debugLog(
      'fallback reason=tafsir_not_configured '
      'tafsirId=${normalizedTafsirId ?? 'default'} '
      'ayah=$surahNumber:$ayahNumber',
    );
    AppLogger.info(
      'Tafsir unavailable: ${normalizedTafsirId ?? 'default'} '
      '$normalizedLanguage $surahNumber:$ayahNumber.',
    );

    return lastUnavailableResult ??
        TafsirLoadResult(
          source: TafsirLoadSource.unavailable,
          errorCode: 'tafsir_not_configured',
          debugInfo: _debugInfo(
            resourceId: normalizedTafsirId,
            fallbackReason: _apiEnabled ? 'client_not_created' : 'api_disabled',
          ),
        );
  }

  TafsirLoadResult validateEntry(TafsirEntry entry) {
    if (!_isValidAyahReference(entry.surahNumber, entry.ayahNumber)) {
      return const TafsirLoadResult(
        source: TafsirLoadSource.unavailable,
        errorCode: 'invalid_ayah_reference',
        debugInfo: TafsirDebugInfo(fallbackReason: 'validation_rejected'),
      );
    }

    if (entry.text.trim().isEmpty) {
      return const TafsirLoadResult(
        source: TafsirLoadSource.unavailable,
        errorCode: 'empty_tafsir_text',
        debugInfo: TafsirDebugInfo(fallbackReason: 'parse_empty'),
      );
    }

    if (_containsTechnicalError(entry.text)) {
      return const TafsirLoadResult(
        source: TafsirLoadSource.unavailable,
        errorCode: 'invalid_tafsir_text',
        debugInfo: TafsirDebugInfo(fallbackReason: 'validation_rejected'),
      );
    }

    return TafsirLoadResult(
      source: TafsirLoadSource.offline,
      entry: entry,
    );
  }

  Future<TafsirEntry?> _readCache({
    required String languageCode,
    required String? tafsirId,
    required int surahNumber,
    required int ayahNumber,
  }) async {
    if (_cacheService == null || tafsirId == null) return null;
    final entry = await _cacheService.read(
      languageCode: languageCode,
      tafsirId: tafsirId,
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
    );
    if (entry == null) return null;
    final validation = validateEntry(entry);
    if (validation.source != TafsirLoadSource.offline) return null;
    return entry;
  }

  bool _isValidAyahReference(int surahNumber, int ayahNumber) {
    return surahNumber >= 1 &&
        surahNumber <= 114 &&
        ayahNumber >= 1 &&
        ayahNumber <= 286;
  }

  String _normalizeLanguageCode(String languageCode) {
    final normalized = languageCode.trim().toLowerCase();
    if (normalized.isEmpty) return 'es';
    return normalized.replaceAll('-', '_').split('_').first;
  }

  String? _normalizeOptionalId(String? tafsirId) {
    final normalized = tafsirId?.trim();
    if (normalized == null || normalized.isEmpty) return null;
    final parsed = int.tryParse(normalized);
    if (parsed == null || parsed <= 0) return null;
    return parsed.toString();
  }

  _ResolvedTafsirResource _resolveResource(
    String languageCode, {
    String? requestedTafsirId,
  }) {
    final explicitTafsirId = _normalizeOptionalId(requestedTafsirId);
    if (explicitTafsirId != null) {
      return _ResolvedTafsirResource(
        resourceId: explicitTafsirId,
        source: 'request',
      );
    }

    if (_providerName == 'qul_preview') {
      final languageResource = qulTafsirResourceForLanguage(languageCode);
      return _ResolvedTafsirResource(
        resourceId: languageResource?.resourceId,
        source:
            languageResource == null ? 'missing_language_map' : 'locale_map',
      );
    }

    final defaultId = _normalizeOptionalId(_defaultTafsirId);
    return _ResolvedTafsirResource(
      resourceId: defaultId,
      source: defaultId == null ? 'missing_default' : 'default_define',
    );
  }

  List<_TafsirResourceAttempt> _resolveResourceAttempts(
    String languageCode, {
    String? requestedTafsirId,
  }) {
    final explicitTafsirId = _normalizeOptionalId(requestedTafsirId);
    if (explicitTafsirId != null) {
      return [
        _TafsirResourceAttempt(
          languageCode: languageCode,
          resource: _ResolvedTafsirResource(
            resourceId: explicitTafsirId,
            source: 'request',
          ),
        ),
      ];
    }

    if (_providerName != 'qul_preview') {
      return [
        _TafsirResourceAttempt(
          languageCode: languageCode,
          resource: _resolveResource(languageCode),
        ),
      ];
    }

    return _fallbackLanguageCodes(languageCode).map((fallbackLanguage) {
      return _TafsirResourceAttempt(
        languageCode: fallbackLanguage,
        resource: _resolveResource(fallbackLanguage),
      );
    }).toList(growable: false);
  }

  List<String> _fallbackLanguageCodes(String languageCode) {
    final languages = <String>[
      languageCode,
      'es',
      'en',
    ];
    return languages.toSet().toList(growable: false);
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

  void _debugLog(String message) {
    final logMessage = '[QuranTafsirApi] $message';
    if (kDebugMode) {
      debugPrint(logMessage);
      return;
    }
    if (_apiEnabled || _providerName == 'qul_preview') {
      AppLogger.info(logMessage);
    }
  }

  void _debugLanguage({
    required String requestedLanguageCode,
    required String normalizedLanguageCode,
    required String? resourceId,
    required String resourceSource,
  }) {
    final message = '[QuranTafsirLanguage] requestedLocale='
        '$requestedLanguageCode tafsirLanguage=$normalizedLanguageCode '
        'resourceId=${resourceId ?? 'none'} resourceSource=$resourceSource '
        'provider=${_providerName ?? 'default'}';
    if (kDebugMode) {
      debugPrint(message);
      return;
    }
    if (_apiEnabled || _providerName == 'qul_preview') {
      AppLogger.info(message);
    }
  }

  TafsirDebugInfo _debugInfo({
    String? resourceId,
    String fallbackReason = 'unknown',
  }) {
    return TafsirDebugInfo(
      provider: _providerName,
      resourceId: resourceId,
      fallbackReason: fallbackReason,
    );
  }
}

class _ResolvedTafsirResource {
  const _ResolvedTafsirResource({
    required this.resourceId,
    required this.source,
  });

  final String? resourceId;
  final String source;
}

class _TafsirResourceAttempt {
  const _TafsirResourceAttempt({
    required this.languageCode,
    required this.resource,
  });

  final String languageCode;
  final _ResolvedTafsirResource resource;
}
