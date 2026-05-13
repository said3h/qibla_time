import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/tafsir_entry.dart';
import '../services/tafsir_service.dart';

final tafsirServiceProvider = Provider<TafsirService>((ref) {
  return const TafsirService();
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
