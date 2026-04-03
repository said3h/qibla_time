import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/localization/locale_controller.dart';
import '../models/hadith.dart';

/// Servicio para gestionar hadices con soporte multilenguaje
/// 
/// Estructura de datos:
/// - Carga JSONs por idioma desde assets/hadiths/{idioma}/hadiths.json
/// - Soporta fallback automático a español
/// - backward compatibility con formato antiguo (hadiths_complete.json)
class HadithService {
  HadithService({String? initialLanguageCode})
      : _currentLanguage = _normalizeLanguageCode(
          initialLanguageCode ?? AppLocaleController.effectiveLanguageCode(),
        );

  Box get _box => Hive.box(StorageService.hadithBox);

  // Cache en memoria para evitar cargar múltiples veces
  List<HadithMultilenguaje>? _allHadithsCache;
  
  // Idioma actualmente seleccionado
  String _currentLanguage;

  /// Carga todos los hadices desde assets
  Future<List<HadithMultilenguaje>> loadAllMultilenguaje() async {
    // Usar cache si ya está cargado
    if (_allHadithsCache != null) {
      return _allHadithsCache!;
    }

    try {
      // Intentar cargar el archivo nuevo por idioma
      final raw = await rootBundle.loadString('assets/hadiths/hadiths_multilang.json');
      final decoded = jsonDecode(raw) as List<dynamic>;
      _allHadithsCache = decoded
          .map((item) => HadithMultilenguaje.fromJson(item as Map<String, dynamic>))
          .toList();
      return _allHadithsCache!;
    } catch (e) {
      // Fallback al archivo antiguo si hay error (formato legacy)
      try {
        final raw = await rootBundle.loadString('assets/hadiths/hadiths_complete.json');
        final decoded = jsonDecode(raw) as List<dynamic>;
        _allHadithsCache = decoded
            .map((item) => HadithMultilenguaje.fromJson(item as Map<String, dynamic>))
            .toList();
        return _allHadithsCache!;
      } catch (e2) {
        // Ultimo recurso: daily_hadiths.json
        final raw = await rootBundle.loadString('assets/hadiths/daily_hadiths.json');
        final decoded = jsonDecode(raw) as List<dynamic>;
        _allHadithsCache = decoded
            .map((item) => HadithMultilenguaje.fromJson(item as Map<String, dynamic>))
            .toList();
        return _allHadithsCache!;
      }
    }
  }

  /// Obtiene la lista de hadices en el idioma seleccionado con fallback
  Future<List<Hadith>> loadAll({String? forcedLanguage}) async {
    final language = forcedLanguage ?? _currentLanguage;
    final multilangList = await loadAllMultilenguaje();
    return multilangList.map((h) => h.getHadith(language)).toList();
  }

  /// Obtiene el hadiz del día en el idioma actual
  Future<Hadith?> getHadithOfDay({String? forcedLanguage}) async {
    final language = forcedLanguage ?? _currentLanguage;
    final hadiths = await loadAll(forcedLanguage: language);
    if (hadiths.isEmpty) return null;
    final now = DateTime.now();
    final seed = now.year * 10000 + now.month * 100 + now.day;
    return hadiths[seed % hadiths.length];
  }

  /// Obtiene un hadiz específico por su ID
  Future<Hadith?> getHadithById(int id, {String? forcedLanguage}) async {
    final language = forcedLanguage ?? _currentLanguage;
    final hadiths = await loadAll(forcedLanguage: language);
    for (final hadith in hadiths) {
      if (hadith.id == id) {
        return hadith;
      }
    }
    return null;
  }

  /// Obtiene hadices de una colección específica
  Future<List<Hadith>> getHadithsByCollection(String collection, {String? forcedLanguage}) async {
    final language = forcedLanguage ?? _currentLanguage;
    final all = await loadAll(forcedLanguage: language);
    return all.where((h) => _extractCollection(h.reference).toLowerCase() == collection.toLowerCase()).toList();
  }

  /// Busca hadices por texto
  Future<List<Hadith>> searchHadiths(String query, {String? forcedLanguage}) async {
    if (query.trim().isEmpty) {
      return [];
    }

    final language = forcedLanguage ?? _currentLanguage;
    final all = await loadAll(forcedLanguage: language);
    final queryLower = query.toLowerCase();

    return all.where((h) =>
      h.translation.toLowerCase().contains(queryLower) ||
      h.arabic.contains(query) ||
      h.category.toLowerCase().contains(queryLower) ||
      h.reference.toLowerCase().contains(queryLower)
    ).toList();
  }

  /// Obtiene todas las colecciones disponibles con su conteo
  Future<Map<String, int>> getCollections({String? forcedLanguage}) async {
    final language = forcedLanguage ?? _currentLanguage;
    final all = await loadAll(forcedLanguage: language);
    final Map<String, int> collections = {};

    for (final hadith in all) {
      final collection = _extractCollection(hadith.reference);
      collections[collection] = (collections[collection] ?? 0) + 1;
    }

    return collections;
  }

  /// Extrae el nombre de la colección de la referencia
  String _extractCollection(String reference) {
    final refLower = reference.toLowerCase();
    if (refLower.contains('bujari') || refLower.contains('bukhari')) return 'Bukhari';
    if (refLower.contains('muslim')) return 'Muslim';
    if (refLower.contains('tirmidhi')) return 'Tirmidhi';
    if (refLower.contains('abu dawud') || refLower.contains('abudawud')) return 'Abu Dawud';
    if (refLower.contains('nasai')) return 'Nasai';
    if (refLower.contains('ibn majah') || refLower.contains('ibnmajah')) return 'Ibn Majah';
    if (refLower.contains('malik') || refLower.contains('muwatta')) return 'Malik';
    if (refLower.contains('ahmad')) return 'Ahmad';
    return 'Otros';
  }

  /// Obtiene hadices por grado de autenticidad
  Future<List<Hadith>> getHadithsByGrade(String grade, {String? forcedLanguage}) async {
    final language = forcedLanguage ?? _currentLanguage;
    final all = await loadAll(forcedLanguage: language);
    return all.where((h) => h.grade.toLowerCase() == grade.toLowerCase()).toList();
  }

  /// Obtiene los grados de autenticidad disponibles
  Future<List<String>> getAvailableGrades({String? forcedLanguage}) async {
    final language = forcedLanguage ?? _currentLanguage;
    final all = await loadAll(forcedLanguage: language);
    final grades = all.map((h) => h.grade).toSet().toList();
    grades.sort();
    return grades;
  }

  /// Obtiene hadices aleatorios
  Future<List<Hadith>> getRandomHadiths({int count = 1, String? forcedLanguage}) async {
    final language = forcedLanguage ?? _currentLanguage;
    final all = await loadAll(forcedLanguage: language);
    if (all.isEmpty) return [];

    final random = Random();
    final selected = <Hadith>[];
    final usedIndices = <int>{};

    while (selected.length < count && selected.length < all.length) {
      final index = random.nextInt(all.length);
      if (!usedIndices.contains(index)) {
        usedIndices.add(index);
        selected.add(all[index]);
      }
    }

    return selected;
  }

  /// Obtiene hadices favoritos (devuelve en idioma actual)
  Future<List<Hadith>> getFavoriteHadiths({String? forcedLanguage}) async {
    final language = forcedLanguage ?? _currentLanguage;
    final favorites = await getFavorites();
    if (favorites.isEmpty) return [];

    final all = await loadAll(forcedLanguage: language);
    return all.where((h) => favorites.contains(h.id)).toList();
  }

  // ── Sistema de Favoritos (sin cambios) ─────────────────────────────────────

  Future<Set<int>> getFavorites() async {
    final stored = _box.get(AppConstants.keyHadithFavorites, defaultValue: <dynamic>[]);
    return (stored as List<dynamic>).map((item) => item as int).toSet();
  }

  Future<void> toggleFavorite(int hadithId) async {
    final favorites = await getFavorites();
    if (favorites.contains(hadithId)) {
      favorites.remove(hadithId);
    } else {
      favorites.add(hadithId);
    }
    await _box.put(AppConstants.keyHadithFavorites, favorites.toList());
  }

  Future<bool> isFavorite(int hadithId) async {
    final favorites = await getFavorites();
    return favorites.contains(hadithId);
  }

  /// Actualiza el idioma actual del servicio
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

final hadithServiceProvider = Provider<HadithService>((ref) {
  final language = ref.watch(currentLanguageCodeProvider);
  final service = HadithService(initialLanguageCode: language);
  ref.listen<String>(currentLanguageCodeProvider, (_, next) {
    service.setCurrentLanguage(next);
  });
  return service;
});

/// Provider que escucha cambios de idioma y actualiza el servicio
final hadithServiceWithLocaleProvider = Provider<HadithService>((ref) {
  return ref.watch(hadithServiceProvider);
});

final dailyHadithProvider = FutureProvider<Hadith?>((ref) async {
  final language = ref.watch(currentLanguageCodeProvider);
  return ref.watch(hadithServiceProvider).getHadithOfDay(forcedLanguage: language);
});

final allHadithsProvider = FutureProvider<List<Hadith>>((ref) async {
  final language = ref.watch(currentLanguageCodeProvider);
  return ref.watch(hadithServiceProvider).loadAll(forcedLanguage: language);
});

final hadithFavoritesProvider = FutureProvider<Set<int>>((ref) async {
  return ref.watch(hadithServiceProvider).getFavorites();
});
