import '../../../core/services/logger_service.dart';
import '../models/tafsir_entry.dart';
import 'tafsir_api_client.dart';
import 'tafsir_cache_service.dart';

class TafsirService {
  const TafsirService({
    TafsirApiClient? apiClient,
    TafsirCacheService? cacheService,
    String? defaultTafsirId,
  })  : _apiClient = apiClient,
        _cacheService = cacheService,
        _defaultTafsirId = defaultTafsirId;

  final TafsirApiClient? _apiClient;
  final TafsirCacheService? _cacheService;
  final String? _defaultTafsirId;

  Future<TafsirLoadResult> getTafsir({
    required int surahNumber,
    required int ayahNumber,
    required String languageCode,
    String? tafsirId,
  }) async {
    final normalizedLanguage = _normalizeLanguageCode(languageCode);
    final normalizedTafsirId = _normalizeOptionalId(tafsirId) ??
        _normalizeOptionalId(_defaultTafsirId);

    if (!_isValidAyahReference(surahNumber, ayahNumber)) {
      AppLogger.warning(
        'Invalid tafsir request for $surahNumber:$ayahNumber.',
      );
      return const TafsirLoadResult(
        source: TafsirLoadSource.unavailable,
        errorCode: 'invalid_ayah_reference',
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
      return TafsirLoadResult(
        source: TafsirLoadSource.cache,
        entry: cachedEntry,
      );
    }

    if (_apiClient != null) {
      if (normalizedTafsirId == null) {
        return const TafsirLoadResult(
          source: TafsirLoadSource.unavailable,
          errorCode: 'missing_tafsir_id',
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
          return const TafsirLoadResult(
            source: TafsirLoadSource.unavailable,
            errorCode: 'invalid_tafsir_text',
          );
        }

        await _cacheService?.write(apiResult.entry!);
        return apiResult;
      }

      final fallbackEntry = await _readCache(
        languageCode: normalizedLanguage,
        tafsirId: normalizedTafsirId,
        surahNumber: surahNumber,
        ayahNumber: ayahNumber,
      );
      if (fallbackEntry != null) {
        return TafsirLoadResult(
          source: TafsirLoadSource.cache,
          entry: fallbackEntry,
        );
      }

      return apiResult;
    }

    // TODO: Enable online tafsir by resource when API credentials, selected
    // resource IDs, and cache terms are confirmed safe for mobile usage.
    AppLogger.info(
      'Tafsir unavailable: ${normalizedTafsirId ?? 'default'} '
      '$normalizedLanguage $surahNumber:$ayahNumber.',
    );

    return const TafsirLoadResult(
      source: TafsirLoadSource.unavailable,
      errorCode: 'tafsir_not_configured',
    );
  }

  TafsirLoadResult validateEntry(TafsirEntry entry) {
    if (!_isValidAyahReference(entry.surahNumber, entry.ayahNumber)) {
      return const TafsirLoadResult(
        source: TafsirLoadSource.unavailable,
        errorCode: 'invalid_ayah_reference',
      );
    }

    if (entry.text.trim().isEmpty) {
      return const TafsirLoadResult(
        source: TafsirLoadSource.unavailable,
        errorCode: 'empty_tafsir_text',
      );
    }

    if (_containsTechnicalError(entry.text)) {
      return const TafsirLoadResult(
        source: TafsirLoadSource.unavailable,
        errorCode: 'invalid_tafsir_text',
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
}
