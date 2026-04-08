import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/locale_controller.dart';
import '../models/allah_name.dart';

class AllahNamesService {
  List<AllahNameMultilang>? _cache;

  Future<List<AllahName>> loadAll(String languageCode) async {
    final names = await _loadMultilang();
    final normalizedLanguage = _normalizeLanguageCode(languageCode);
    final fallbackLanguage = _fallbackContentLanguage(normalizedLanguage);
    return names
        .map(
          (name) => name.getName(
            normalizedLanguage,
            fallbackLanguage: fallbackLanguage,
          ),
        )
        .toList();
  }

  Future<List<AllahNameMultilang>> _loadMultilang() async {
    if (_cache != null) return _cache!;

    final raw = await rootBundle.loadString(
      'assets/data/allah_names_multilang.json',
    );
    final decoded = jsonDecode(raw) as List<dynamic>;
    _cache = decoded
        .map(
          (item) => AllahNameMultilang.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
    return _cache!;
  }

  static String _normalizeLanguageCode(String languageCode) {
    return switch (languageCode) {
      'ar' => 'ar',
      'en' => 'en',
      'fr' => 'fr',
      'de' || 'de_DE' || 'de-DE' => 'de',
      'nl' || 'nl_NL' || 'nl-NL' => 'nl',
      _ => 'es',
    };
  }

  static String _fallbackContentLanguage(String languageCode) {
    return switch (_normalizeLanguageCode(languageCode)) {
      'de' => 'en',
      'fr' => 'en',
      'nl' => 'en',
      _ => 'es',
    };
  }
}

final allahNamesServiceProvider = Provider<AllahNamesService>((ref) {
  return AllahNamesService();
});

final allahNamesProvider = FutureProvider<List<AllahName>>((ref) async {
  final languageCode = ref.watch(currentLanguageCodeProvider);
  return ref.watch(allahNamesServiceProvider).loadAll(languageCode);
});
