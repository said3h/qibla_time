import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/tafsir_entry.dart';
import '../services/tafsir_api_client.dart';
import '../services/tafsir_config.dart';
import '../services/tafsir_service.dart';

final tafsirConfigProvider = Provider<TafsirConfig>((ref) {
  return TafsirConfig.fromEnvironment;
});

final tafsirApiClientProvider = Provider<TafsirApiClient?>((ref) {
  final config = ref.watch(tafsirConfigProvider);
  final baseUri = config.baseUri;
  if (!config.canCreateApiClient || baseUri == null) {
    return null;
  }

  return TafsirApiClient(
    baseUri: baseUri,
    authToken: config.normalizedAuthToken,
    clientId: config.normalizedClientId,
  );
});

final tafsirServiceProvider = Provider<TafsirService>((ref) {
  return TafsirService(
    apiClient: ref.watch(tafsirApiClientProvider),
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
