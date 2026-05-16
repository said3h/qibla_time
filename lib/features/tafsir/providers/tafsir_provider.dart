import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/settings_service.dart';
import '../models/tafsir_entry.dart';
import '../services/tafsir_api_client.dart';
import '../services/tafsir_cache_service.dart';
import '../services/tafsir_config.dart';
import '../services/tafsir_service.dart';

final tafsirUserEnabledProvider = FutureProvider<bool>((ref) async {
  return SettingsService.instance.getTafsirEnabled();
});

final tafsirConfigProvider = Provider<TafsirConfig>((ref) {
  return TafsirConfig.fromEnvironment;
});

final tafsirApiClientProvider = Provider<TafsirApiClient?>((ref) {
  final config = ref.watch(tafsirConfigProvider);
  if (!config.canCreateApiClient) {
    return null;
  }

  if (config.isQulPreview) {
    if (!kDebugMode) return null;
    return TafsirApiClient(
      baseUri: _qulPreviewBaseUri(config),
      source: TafsirApiSource.qulPreview,
    );
  }

  final baseUri = config.baseUri;
  if (baseUri == null) return null;
  return TafsirApiClient(
    baseUri: baseUri,
    authToken: config.normalizedAuthToken,
    clientId: config.normalizedClientId,
  );
});

Uri _qulPreviewBaseUri(TafsirConfig config) {
  final configured = config.baseUri;
  if (configured != null && configured.host != 'api.quran.com') {
    return configured;
  }
  return Uri.parse('https://qul.tarteel.ai');
}

final tafsirCacheServiceProvider = Provider<TafsirCacheService>((ref) {
  return const TafsirCacheService();
});

final tafsirServiceProvider = Provider<TafsirService>((ref) {
  return TafsirService(
    apiClient: ref.watch(tafsirApiClientProvider),
    cacheService: ref.watch(tafsirCacheServiceProvider),
    defaultTafsirId:
        ref.watch(tafsirConfigProvider).normalizedDefaultResourceId,
  );
});

final tafsirEntryProvider =
    FutureProvider.family<TafsirLoadResult, TafsirRequest>((ref, request) {
  return ref.watch(tafsirServiceProvider).getTafsir(
        surahNumber: request.surahNumber,
        ayahNumber: request.ayahNumber,
        languageCode: request.languageCode,
        tafsirId: request.tafsirId,
      );
});
