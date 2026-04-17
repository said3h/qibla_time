import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/locale_controller.dart';
import '../models/dua_model.dart';

final duaServiceProvider = Provider<DuaService>((ref) {
  final language = ref.watch(currentLanguageCodeProvider);
  final service = DuaService(initialLanguageCode: language);
  ref.listen<String>(currentLanguageCodeProvider, (_, next) {
    service.setCurrentLanguage(next);
  });
  return service;
});

class DuaService {
  DuaService({String? initialLanguageCode})
      : _currentLanguage = _normalizeLanguageCode(
          initialLanguageCode ?? AppLocaleController.effectiveLanguageCode(),
        );

  List<DuaMultilenguaje>? _cache;
  String _currentLanguage;

  Future<List<DuaMultilenguaje>> loadAllMultilenguaje() async {
    if (_cache != null) return _cache!;

    final raw = await rootBundle.loadString('assets/data/duas_multilang.json');
    final decoded = jsonDecode(raw) as List<dynamic>;
    _cache = decoded
        .map((item) => DuaMultilenguaje.fromJson(item as Map<String, dynamic>))
        .toList();
    return _cache!;
  }

  Future<List<Dua>> loadAll({String? forcedLanguage}) async {
    final language = _normalizeLanguageCode(
      forcedLanguage ?? _currentLanguage,
    );
    final multilangList = await loadAllMultilenguaje();
    return multilangList
        .map(
          (dua) => _resolveDuaForLanguage(dua, language),
        )
        .toList();
  }

  Future<List<Dua>> getByCategory(
    String category, {
    String? forcedLanguage,
  }) async {
    final language = forcedLanguage ?? _currentLanguage;
    final duas = await loadAll(forcedLanguage: language);
    return duas.where((dua) => dua.category == category).toList();
  }

  Future<List<String>> getCategories({String? forcedLanguage}) async {
    final language = forcedLanguage ?? _currentLanguage;
    final duas = await loadAll(forcedLanguage: language);
    final categories = duas.map((dua) => dua.category).toSet().toList()
      ..sort();
    return categories;
  }

  Future<List<Dua>> getFeatured({String? forcedLanguage}) async {
    final language = forcedLanguage ?? _currentLanguage;
    final duas = await loadAll(forcedLanguage: language);
    return duas.where((dua) => dua.isFeatured).toList();
  }

  Future<List<Dua>> search(String query, {String? forcedLanguage}) async {
    if (query.trim().isEmpty) return [];

    final language = forcedLanguage ?? _currentLanguage;
    final duas = await loadAll(forcedLanguage: language);
    final queryLower = query.toLowerCase();

    return duas.where((dua) {
      final tagString = dua.tags?.join(' ') ?? '';
      final reference = dua.reference ?? '';
      final source = dua.source ?? '';

      return dua.title.toLowerCase().contains(queryLower) ||
          dua.translation.toLowerCase().contains(queryLower) ||
          dua.transliteration.toLowerCase().contains(queryLower) ||
          reference.toLowerCase().contains(queryLower) ||
          source.toLowerCase().contains(queryLower) ||
          tagString.toLowerCase().contains(queryLower) ||
          dua.arabicText.contains(query);
    }).toList();
  }

  void setCurrentLanguage(String languageCode) {
    _currentLanguage = _normalizeLanguageCode(languageCode);
  }

  static String _normalizeLanguageCode(String languageCode) {
    final normalized = languageCode
        .trim()
        .toLowerCase()
        .replaceAll('-', '_')
        .split('_')
        .first;

    return switch (normalized) {
      'ar' => 'ar',
      'en' => 'en',
      'fr' => 'fr',
      'de' => 'de',
      'it' => 'it',
      'nl' => 'nl',
      'pt' => 'pt',
      'id' => 'id',
      'ru' => 'ru',
      'tr' => 'tr',
      _ => 'es',
    };
  }

  Dua _resolveDuaForLanguage(DuaMultilenguaje dua, String languageCode) {
    for (final candidate in _resolutionOrder(languageCode)) {
      final translation = dua.translations[candidate];
      if (!_hasUsableLocalizedContent(translation)) {
        continue;
      }
      return dua.getDua(candidate, fallbackLanguage: candidate);
    }

    return dua.getDua('es', fallbackLanguage: 'es');
  }

  static List<String> _resolutionOrder(String languageCode) {
    return switch (_normalizeLanguageCode(languageCode)) {
      'de' => const ['de', 'en', 'es'],
      'fr' => const ['fr', 'en', 'es'],
      'it' => const ['it', 'en', 'es'],
      'nl' => const ['nl', 'en', 'es'],
      'pt' => const ['pt', 'en', 'es'],
      'id' => const ['id', 'en', 'es'],
      'ru' => const ['ru', 'en', 'es'],
      'tr' => const ['tr', 'en', 'es'],
      'en' => const ['en', 'es'],
      'ar' => const ['ar', 'es'],
      _ => const ['es', 'en'],
    };
  }

  static bool _hasUsableLocalizedContent(DuaTranslation? translation) {
    if (translation == null) {
      return false;
    }

    if (translation.translation.trim().isNotEmpty) {
      return true;
    }

    return translation.title.trim().isNotEmpty ||
        translation.category.trim().isNotEmpty;
  }
}

final allDuasProvider = FutureProvider<List<Dua>>((ref) async {
  final language = ref.watch(currentLanguageCodeProvider);
  return ref.watch(duaServiceProvider).loadAll(forcedLanguage: language);
});

final duaCategoriesProvider = FutureProvider<List<String>>((ref) async {
  final language = ref.watch(currentLanguageCodeProvider);
  return ref.watch(duaServiceProvider).getCategories(forcedLanguage: language);
});

final duaByCategoryProvider = FutureProvider.family<List<Dua>, String>((
  ref,
  category,
) async {
  final language = ref.watch(currentLanguageCodeProvider);
  return ref.watch(duaServiceProvider).getByCategory(
    category,
    forcedLanguage: language,
  );
});
