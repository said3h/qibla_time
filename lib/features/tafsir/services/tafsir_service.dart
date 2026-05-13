import '../../../core/services/logger_service.dart';
import '../models/tafsir_entry.dart';

class TafsirService {
  const TafsirService();

  Future<TafsirLoadResult> getTafsir({
    required int surahNumber,
    required int ayahNumber,
    required String languageCode,
    String? tafsirId,
  }) async {
    final normalizedLanguage = _normalizeLanguageCode(languageCode);
    final normalizedTafsirId = _normalizeOptionalId(tafsirId);

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
    // TODO: Check local tafsir cache if API caching is legally allowed.
    // TODO: Fetch online tafsir by resource when API credentials and terms are
    // confirmed safe for mobile usage.
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
    return normalized;
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
