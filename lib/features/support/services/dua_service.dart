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

  /// Carga todas las dúas en formato multilenguaje
  Future<List<DuaMultilenguaje>> loadAllMultilenguaje() async {
    if (_cache != null) return _cache!;

    try {
      // Intentar cargar el archivo nuevo multilenguaje
      final raw = await rootBundle.loadString('assets/data/duas_multilang.json');
      final decoded = jsonDecode(raw) as List<dynamic>;
      _cache = decoded
          .map((item) => DuaMultilenguaje.fromJson(item as Map<String, dynamic>))
          .toList();
      return _cache!;
    } catch (e) {
      // Fallback al archivo antiguo
      final raw = await rootBundle.loadString('assets/data/duas_hisnul.json');
      final decoded = jsonDecode(raw) as List<dynamic>;
      _cache = decoded
          .map((item) => DuaMultilenguaje.fromJson(item as Map<String, dynamic>))
          .toList();
      return _cache!;
    }
  }

  /// Obtiene la lista de duas en el idioma seleccionado con fallback
  Future<List<Dua>> loadAll({String? forcedLanguage}) async {
    final language = forcedLanguage ?? _currentLanguage;
    final multilangList = await loadAllMultilenguaje();
    return multilangList.map((d) => d.getDua(language)).toList();
  }

  /// Obtiene duas por categoría en el idioma actual
  Future<List<Dua>> getByCategory(String category, {String? forcedLanguage}) async {
    final language = forcedLanguage ?? _currentLanguage;
    final duas = await loadAll(forcedLanguage: language);
    return duas.where((dua) => dua.category == category).toList();
  }

  /// Obtiene todas las categorías disponibles
  Future<List<String>> getCategories({String? forcedLanguage}) async {
    final language = forcedLanguage ?? _currentLanguage;
    final duas = await loadAll(forcedLanguage: language);
    final categories = duas.map((dua) => dua.category).toSet().toList()
      ..sort();
    return categories;
  }

  /// Obtiene duas destacados
  Future<List<Dua>> getFeatured({String? forcedLanguage}) async {
    final language = forcedLanguage ?? _currentLanguage;
    final duas = await loadAll(forcedLanguage: language);
    return duas.where((dua) => dua.isFeatured).toList();
  }

  /// Busca duas por texto
  Future<List<Dua>> search(String query, {String? forcedLanguage}) async {
    if (query.trim().isEmpty) return [];
    
    final language = forcedLanguage ?? _currentLanguage;
    final duas = await loadAll(forcedLanguage: language);
    final queryLower = query.toLowerCase();
    
    return duas.where((d) =>
      d.title.toLowerCase().contains(queryLower) ||
      d.translation.toLowerCase().contains(queryLower) ||
      d.arabicText.contains(query)
    ).toList();
  }

  void setCurrentLanguage(String languageCode) {
    _currentLanguage = _normalizeLanguageCode(languageCode);
  }

  static String _normalizeLanguageCode(String languageCode) {
    return switch (languageCode) {
      'ar' => 'ar',
      'en' => 'en',
      _ => 'es',
    };
  }
}

// Providers que automáticamente usan el idioma actual
final allDuasProvider = FutureProvider<List<Dua>>((ref) async {
  final language = ref.watch(currentLanguageCodeProvider);
  return ref.watch(duaServiceProvider).loadAll(forcedLanguage: language);
});

final duaCategoriesProvider = FutureProvider<List<String>>((ref) async {
  final language = ref.watch(currentLanguageCodeProvider);
  return ref.watch(duaServiceProvider).getCategories(forcedLanguage: language);
});

final duaByCategoryProvider = FutureProvider.family<List<Dua>, String>((ref, category) async {
  final language = ref.watch(currentLanguageCodeProvider);
  return ref.watch(duaServiceProvider).getByCategory(category, forcedLanguage: language);
});
