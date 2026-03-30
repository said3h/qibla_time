import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/storage_service.dart';
import '../models/hadith.dart';

/// Servicio para gestionar los hadices en español
/// Fuente: HadeethEnc.com - 1,954 hadices autenticados
class HadithService {
  Box get _box => Hive.box(StorageService.hadithBox);

  // Cache en memoria para evitar cargar múltiples veces
  List<Hadith>? _allHadithsCache;

  /// Carga todos los hadices desde assets/hadiths/hadiths_complete.json
  Future<List<Hadith>> loadAll() async {
    // Usar cache si ya está cargado
    if (_allHadithsCache != null) {
      return _allHadithsCache!;
    }

    try {
      final raw = await rootBundle.loadString('assets/hadiths/hadiths_complete.json');
      final decoded = jsonDecode(raw) as List<dynamic>;
      _allHadithsCache = decoded
          .map((item) => Hadith.fromJson(item as Map<String, dynamic>))
          .toList();
      return _allHadithsCache!;
    } catch (e) {
      // Fallback al archivo antiguo si hay error
      final raw = await rootBundle.loadString('assets/hadiths/daily_hadiths.json');
      final decoded = jsonDecode(raw) as List<dynamic>;
      _allHadithsCache = decoded
          .map((item) => Hadith.fromJson(item as Map<String, dynamic>))
          .toList();
      return _allHadithsCache!;
    }
  }

  /// Obtiene el hadiz del día basado en la fecha actual
  /// Usa un seed consistente para que todos los usuarios vean el mismo hadiz en el mismo día
  Future<Hadith?> getHadithOfDay() async {
    final hadiths = await loadAll();
    if (hadiths.isEmpty) return null;
    final now = DateTime.now();
    final seed = now.year * 10000 + now.month * 100 + now.day;
    return hadiths[seed % hadiths.length];
  }

  /// Obtiene un hadiz específico por su ID
  Future<Hadith?> getHadithById(int id) async {
    final hadiths = await loadAll();
    for (final hadith in hadiths) {
      if (hadith.id == id) {
        return hadith;
      }
    }
    return null;
  }

  /// Obtiene hadices de una colección específica
  Future<List<Hadith>> getHadithsByCollection(String collection) async {
    final all = await loadAll();
    return all.where((h) => _extractCollection(h.reference).toLowerCase() == collection.toLowerCase()).toList();
  }

  /// Busca hadices por texto en español o árabe
  Future<List<Hadith>> searchHadiths(String query) async {
    if (query.trim().isEmpty) {
      return [];
    }

    final all = await loadAll();
    final queryLower = query.toLowerCase();

    return all.where((h) =>
      h.translation.toLowerCase().contains(queryLower) ||
      h.arabic.contains(query) ||
      h.category.toLowerCase().contains(queryLower) ||
      h.reference.toLowerCase().contains(queryLower)
    ).toList();
  }

  /// Obtiene todas las colecciones disponibles con su conteo
  Future<Map<String, int>> getCollections() async {
    final all = await loadAll();
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
  Future<List<Hadith>> getHadithsByGrade(String grade) async {
    final all = await loadAll();
    return all.where((h) => h.grade.toLowerCase() == grade.toLowerCase()).toList();
  }

  /// Obtiene los grados de autenticidad disponibles
  Future<List<String>> getAvailableGrades() async {
    final all = await loadAll();
    final grades = all.map((h) => h.grade).toSet().toList();
    grades.sort();
    return grades;
  }

  /// Obtiene hadices aleatorios (útil para widgets, notificaciones, etc.)
  Future<List<Hadith>> getRandomHadiths({int count = 1}) async {
    final all = await loadAll();
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

  // ── Sistema de Favoritos ─────────────────────────────────────

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

  Future<List<Hadith>> getFavoriteHadiths() async {
    final favorites = await getFavorites();
    if (favorites.isEmpty) return [];

    final all = await loadAll();
    return all.where((h) => favorites.contains(h.id)).toList();
  }
}

final hadithServiceProvider = Provider<HadithService>((ref) {
  return HadithService();
});

final dailyHadithProvider = FutureProvider<Hadith?>((ref) async {
  return ref.watch(hadithServiceProvider).getHadithOfDay();
});

final allHadithsProvider = FutureProvider<List<Hadith>>((ref) async {
  return ref.watch(hadithServiceProvider).loadAll();
});

final hadithFavoritesProvider = FutureProvider<Set<int>>((ref) async {
  return ref.watch(hadithServiceProvider).getFavorites();
});
