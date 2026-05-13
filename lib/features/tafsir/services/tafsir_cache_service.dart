import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/tafsir_entry.dart';

class TafsirCacheService {
  const TafsirCacheService();

  Future<TafsirEntry?> read({
    required String languageCode,
    required String tafsirId,
    required int surahNumber,
    required int ayahNumber,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(
      cacheKey(
        languageCode: languageCode,
        tafsirId: tafsirId,
        surahNumber: surahNumber,
        ayahNumber: ayahNumber,
      ),
    );
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final entry = TafsirEntry.fromJson(Map<String, dynamic>.from(decoded));
      if (!entry.hasUsableText) return null;
      return entry.copyWith(cachedAt: entry.cachedAt ?? DateTime.now());
    } catch (_) {
      return null;
    }
  }

  Future<void> write(TafsirEntry entry) async {
    if (!entry.hasUsableText) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      cacheKey(
        languageCode: entry.languageCode,
        tafsirId: entry.tafsirId,
        surahNumber: entry.surahNumber,
        ayahNumber: entry.ayahNumber,
      ),
      jsonEncode(
        entry
            .copyWith(
              cachedAt: entry.cachedAt ?? DateTime.now(),
            )
            .toJson(),
      ),
    );
  }

  static String cacheKey({
    required String languageCode,
    required String tafsirId,
    required int surahNumber,
    required int ayahNumber,
  }) {
    final normalizedLanguage =
        languageCode.trim().toLowerCase().replaceAll('-', '_').split('_').first;
    final normalizedTafsirId = tafsirId.trim();
    return 'tafsir:$normalizedLanguage:$normalizedTafsirId:$surahNumber:$ayahNumber';
  }
}
