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
  _debugLogConfig(config, 'provider_build');
  if (!config.canCreateApiClient) {
    _debugLogConfig(config, 'client_disabled');
    return null;
  }

  if (config.isQulPreview) {
    if (!config.internalBuild) {
      _debugLogConfig(config, 'qul_preview_internal_flag_missing');
      return null;
    }
    final baseUri = _qulPreviewBaseUri(config);
    _debugLogConfig(config, 'client_created_qul_preview baseUri=$baseUri');
    return TafsirApiClient(
      baseUri: baseUri,
      source: TafsirApiSource.qulPreview,
    );
  }

  final baseUri = config.baseUri;
  if (baseUri == null) {
    _debugLogConfig(config, 'client_disabled_invalid_base_uri');
    return null;
  }
  _debugLogConfig(config, 'client_created_quran_foundation baseUri=$baseUri');
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

void _debugLogConfig(TafsirConfig config, String event) {
  if (!kDebugMode) return;
  debugPrint(
    '[QuranTafsirApi] $event enabled=${config.enabled} '
    'provider=${config.normalizedProvider} isQul=${config.isQulPreview} '
    'internalBuild=${config.internalBuild} '
    'baseUri=${config.baseUri} defaultResourceId='
    '${config.normalizedDefaultResourceId} '
    'canCreateClient=${config.canCreateApiClient}',
  );
}

final tafsirCacheServiceProvider = Provider<TafsirCacheService>((ref) {
  return const TafsirCacheService();
});

final tafsirServiceProvider = Provider<TafsirService>((ref) {
  final config = ref.watch(tafsirConfigProvider);
  return TafsirService(
    apiClient: ref.watch(tafsirApiClientProvider),
    cacheService: ref.watch(tafsirCacheServiceProvider),
    defaultTafsirId: config.normalizedDefaultResourceId,
    apiEnabled: config.enabled,
    providerName: config.normalizedProvider,
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
