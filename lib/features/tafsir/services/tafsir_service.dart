import 'package:flutter/foundation.dart';

import '../../../core/services/logger_service.dart';
import '../models/tafsir_entry.dart';
import 'tafsir_api_client.dart';
import 'tafsir_cache_service.dart';

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
    final normalizedTafsirId = _normalizeOptionalId(tafsirId) ??
        _normalizeOptionalId(_defaultTafsirId);
    _debugLog(
      'request language=$normalizedLanguage tafsirId=$normalizedTafsirId '
      'ayah=$surahNumber:$ayahNumber apiClient=${_apiClient != null}',
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

    // TODO: Check verified offline tafsir assets once a legally usable dataset
    // is approved for bundling.
    final cachedEntry = await _readCache(
      languageCode: normalizedLanguage,
      tafsirId: normalizedTafsirId,
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
    );
    if (cachedEntry != null) {
      _debugLog(
        'cache hit tafsirId=$normalizedTafsirId ayah=$surahNumber:$ayahNumber',
      );
      return TafsirLoadResult(
        source: TafsirLoadSource.cache,
        entry: cachedEntry,
      );
    }

    if (_apiClient != null) {
      if (normalizedTafsirId == null) {
        _debugLog(
          'fallback reason=missing_tafsir_id ayah=$surahNumber:$ayahNumber',
        );
        return TafsirLoadResult(
          source: TafsirLoadSource.unavailable,
          errorCode: 'missing_tafsir_id',
          debugInfo: _debugInfo(fallbackReason: 'missing_provider'),
        );
      }

      final apiResult = await _apiClient.fetchAyahTafsir(
        tafsirId: normalizedTafsirId,
        surahNumber: surahNumber,
        ayahNumber: ayahNumber,
        languageCode: normalizedLanguage,
      );
      if (apiResult.hasEntry && apiResult.source == TafsirLoadSource.api) {
        final validation = validateEntry(apiResult.entry!);
        if (validation.source != TafsirLoadSource.offline) {
          _debugLog(
            'fallback reason=invalid_api_entry tafsirId=$normalizedTafsirId '
            'ayah=$surahNumber:$ayahNumber '
            'validation=${validation.errorCode}',
          );
          AppLogger.warning(
            'Rejected unsafe tafsir response for $normalizedLanguage '
            '$surahNumber:$ayahNumber using resource $normalizedTafsirId.',
          );
          return TafsirLoadResult(
            source: TafsirLoadSource.unavailable,
            errorCode: 'invalid_tafsir_text',
            debugInfo: (apiResult.debugInfo ??
                    _debugInfo(resourceId: normalizedTafsirId))
                .copyWith(fallbackReason: 'validation_rejected'),
          );
        }

        await _cacheService?.write(apiResult.entry!);
        _debugLog(
          'success source=api tafsirId=$normalizedTafsirId '
          'ayah=$surahNumber:$ayahNumber '
          'textLength=${apiResult.entry!.text.length}',
        );
        return apiResult;
      }

      _debugLog(
        'fallback reason=${apiResult.errorCode ?? 'no_entry'} '
        'tafsirId=$normalizedTafsirId ayah=$surahNumber:$ayahNumber',
      );
      AppLogger.info(
        'Tafsir API returned ${apiResult.errorCode ?? 'no_entry'} for '
        '$normalizedLanguage $surahNumber:$ayahNumber using resource '
        '$normalizedTafsirId.',
      );

      final fallbackEntry = await _readCache(
        languageCode: normalizedLanguage,
        tafsirId: normalizedTafsirId,
        surahNumber: surahNumber,
        ayahNumber: ayahNumber,
      );
      if (fallbackEntry != null) {
        _debugLog(
          'cache fallback tafsirId=$normalizedTafsirId '
          'ayah=$surahNumber:$ayahNumber',
        );
        return TafsirLoadResult(
          source: TafsirLoadSource.cache,
          entry: fallbackEntry,
        );
      }

      return apiResult;
    }

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

    return TafsirLoadResult(
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
    if (!kDebugMode) return;
    debugPrint('[QuranTafsirApi] $message');
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
