import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../core/services/logger_service.dart';
import '../../../core/services/storage_service.dart';
import '../models/hadith.dart';

class HadithService {
  static const _primaryHadithAsset = 'assets/data/hadiths_multilang_v2.json';
  static const _minimumExpectedHadithCount = 1900;

  HadithService({String? initialLanguageCode})
      : _currentLanguage = _normalizeLanguageCode(
          initialLanguageCode ?? AppLocaleController.effectiveLanguageCode(),
        );

  Box get _box => Hive.box(StorageService.hadithBox);

  List<HadithMultilenguaje>? _allHadithsCache;
  String _currentLanguage;

  Future<List<HadithMultilenguaje>> loadAllMultilenguaje() async {
    if (_allHadithsCache != null) {
      return _allHadithsCache!;
    }

    final primaryDataset = await _tryLoadAsset(
      _primaryHadithAsset,
      minimumEntries: _minimumExpectedHadithCount,
    );
    if (primaryDataset == null) {
      throw Exception('No se pudo cargar el dataset principal de hadices');
    }

    _allHadithsCache = primaryDataset;
    return _allHadithsCache!;
  }

  Future<List<Hadith>> loadAll({String? forcedLanguage}) async {
    final language = forcedLanguage ?? _currentLanguage;
    final fallbackLanguage = _fallbackContentLanguage(language);
    final multilangList = await loadAllMultilenguaje();
    return multilangList
        .map(
          (hadith) => hadith.getHadith(
            language,
            fallbackLanguage: fallbackLanguage,
          ),
        )
        .toList();
  }

  Future<Hadith?> getHadithOfDay({String? forcedLanguage}) async {
    final language = forcedLanguage ?? _currentLanguage;
    final hadiths = await loadAll(forcedLanguage: language);
    if (hadiths.isEmpty) return null;
    final now = DateTime.now();
    final seed = now.year * 10000 + now.month * 100 + now.day;
    return hadiths[seed % hadiths.length];
  }

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

  Future<List<Hadith>> getHadithsByCollection(
    String collection, {
    String? forcedLanguage,
  }) async {
    final language = forcedLanguage ?? _currentLanguage;
    final all = await loadAll(forcedLanguage: language);
    return all
        .where(
          (hadith) =>
              _extractCollection(hadith.reference).toLowerCase() ==
              collection.toLowerCase(),
        )
        .toList();
  }

  Future<List<Hadith>> searchHadiths(
    String query, {
    String? forcedLanguage,
  }) async {
    if (query.trim().isEmpty) {
      return [];
    }

    final language = forcedLanguage ?? _currentLanguage;
    final all = await loadAll(forcedLanguage: language);
    final queryLower = query.toLowerCase();

    return all
        .where(
          (hadith) =>
              hadith.translation.toLowerCase().contains(queryLower) ||
              hadith.arabic.contains(query) ||
              hadith.category.toLowerCase().contains(queryLower) ||
              hadith.reference.toLowerCase().contains(queryLower),
        )
        .toList();
  }

  Future<Map<String, int>> getCollections({String? forcedLanguage}) async {
    final language = forcedLanguage ?? _currentLanguage;
    final all = await loadAll(forcedLanguage: language);
    final collections = <String, int>{};

    for (final hadith in all) {
      final collection = _extractCollection(hadith.reference);
      collections[collection] = (collections[collection] ?? 0) + 1;
    }

    return collections;
  }

  Future<Map<String, int>> getCategories({String? forcedLanguage}) async {
    final language = forcedLanguage ?? _currentLanguage;
    final all = await loadAll(forcedLanguage: language);
    final categories = <String, int>{};
    for (final hadith in all) {
      final normalizedCategory = hadith.category.trim().toLowerCase();
      if (normalizedCategory.isEmpty) continue;
      categories[normalizedCategory] =
          (categories[normalizedCategory] ?? 0) + 1;
    }
    return categories;
  }

  String _extractCollection(String reference) {
    final refLower = reference.toLowerCase();
    if (refLower.contains('bujari') ||
        refLower.contains('bukhari') ||
        refLower.contains('bukhar') ||
        refLower.contains('boukhari') ||
        refLower.contains('buḫ') ||
        refLower.contains('бухар') ||
        refLower.contains('البخار') ||
        refLower.contains('بخاري') ||
        refLower.contains('متفق عليه')) {
      return 'Sahih al-Bukhari';
    }
    if (refLower.contains('muslim') ||
        refLower.contains('mouslim') ||
        refLower.contains('муслим') ||
        refLower.contains('مسلم')) {
      return 'Sahih Muslim';
    }
    if (refLower.contains('riyad') ||
        refLower.contains('salihin') ||
        refLower.contains('рияд') ||
        refLower.contains('салих') ||
        refLower.contains('رياض') ||
        refLower.contains('صالحين')) {
      return 'Riyad as-Salihin';
    }
    if (refLower.contains('nawawi') ||
        refLower.contains('40 hadith') ||
        refLower.contains('ناواوي') ||
        refLower.contains('الأربعين') ||
        refLower.contains('نووي') ||
        refLower.contains('навави')) {
      return '40 Hadith Nawawi';
    }
    if (refLower.contains('tirmidhi') ||
        refLower.contains('termed') ||
        refLower.contains('termedh') ||
        refLower.contains('тирмиз') ||
        refLower.contains('термед') ||
        refLower.contains('ترمذ')) {
      return 'Jami\' at-Tirmidhi';
    }
    if (refLower.contains('abu dawud') ||
        refLower.contains('abu daoud') ||
        refLower.contains('abu dawood') ||
        refLower.contains('abu-dawud') ||
        refLower.contains('abudawud') ||
        refLower.contains('abudaoud') ||
        refLower.contains('abou dawoud') ||
        refLower.contains('абу дауд') ||
        refLower.contains('дауд') ||
        refLower.contains('أبو داود') ||
        refLower.contains('داود')) {
      return 'Sunan Abu Dawud';
    }
    if (refLower.contains('nasai') ||
        refLower.contains("nasa'i") ||
        refLower.contains('nasaai') ||
        refLower.contains('nsaa') ||
        refLower.contains('nasaa') ||
        refLower.contains('насаи') ||
        refLower.contains('نسائي')) {
      return "Sunan an-Nasa'i";
    }
    if (refLower.contains('ibn majah') ||
        refLower.contains('ibnmajah') ||
        refLower.contains('ibn mayah') ||
        refLower.contains('ибн мадж') ||
        refLower.contains('ابن ماجه')) {
      return 'Sunan Ibn Majah';
    }
    if (refLower.contains('malik') ||
        refLower.contains('maalik') ||
        refLower.contains('muwatta') ||
        refLower.contains('малик') ||
        refLower.contains('муватт') ||
        refLower.contains('موطأ') ||
        refLower.contains('مالك')) {
      return 'Muwatta Malik';
    }
    return 'Otros';
  }

  Future<List<Hadith>> getHadithsByGrade(
    String grade, {
    String? forcedLanguage,
  }) async {
    final language = forcedLanguage ?? _currentLanguage;
    final all = await loadAll(forcedLanguage: language);
    return all
        .where((hadith) => hadith.grade.toLowerCase() == grade.toLowerCase())
        .toList();
  }

  Future<List<String>> getAvailableGrades({String? forcedLanguage}) async {
    final language = forcedLanguage ?? _currentLanguage;
    final all = await loadAll(forcedLanguage: language);
    final grades = all.map((hadith) => hadith.grade).toSet().toList();
    grades.sort();
    return grades;
  }

  Future<List<Hadith>> getRandomHadiths({
    int count = 1,
    String? forcedLanguage,
  }) async {
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

  Future<List<Hadith>> getFavoriteHadiths({String? forcedLanguage}) async {
    final language = forcedLanguage ?? _currentLanguage;
    final favorites = await getFavorites();
    if (favorites.isEmpty) return [];

    final all = await loadAll(forcedLanguage: language);
    return all.where((hadith) => favorites.contains(hadith.id)).toList();
  }

  Future<Set<int>> getFavorites() async {
    final stored = _box.get(
      AppConstants.keyHadithFavorites,
      defaultValue: <dynamic>[],
    );
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

  void setCurrentLanguage(String languageCode) {
    _currentLanguage = _normalizeLanguageCode(languageCode);
  }

  static String _normalizeLanguageCode(String languageCode) {
    return switch (languageCode) {
      'ar' => 'ar',
      'en' => 'en',
      'fr' => 'fr',
      'de' || 'de_DE' || 'de-DE' => 'de',
      'it' || 'it_IT' || 'it-IT' => 'it',
      'nl' || 'nl_NL' || 'nl-NL' => 'nl',
      'pt' || 'pt_PT' || 'pt-BR' || 'pt_BR' || 'pt-PT' => 'pt',
      'id' || 'id_ID' || 'id-ID' => 'id',
      'ru' || 'ru_RU' || 'ru-RU' => 'ru',
      'tr' || 'tr_TR' || 'tr-TR' => 'tr',
      _ => 'es',
    };
  }

  static String _fallbackContentLanguage(String languageCode) {
    return switch (_normalizeLanguageCode(languageCode)) {
      'de' => 'en',
      'fr' => 'en',
      'it' => 'en',
      'nl' => 'en',
      'pt' => 'en',
      'id' => 'en',
      'ru' => 'en',
      'tr' => 'en',
      _ => 'es',
    };
  }

  Future<List<HadithMultilenguaje>?> _tryLoadAsset(
    String assetPath, {
    int minimumEntries = 1,
  }) async {
    try {
      final raw = await rootBundle.loadString(assetPath);
      final decoded = jsonDecode(raw) as List<dynamic>;
      final hadiths = decoded
          .map(
            (item) =>
                HadithMultilenguaje.fromJson(item as Map<String, dynamic>),
          )
          .toList();

      if (hadiths.length < minimumEntries) {
        AppLogger.warning(
          'Hadith dataset has ${hadiths.length} entries; expected at least $minimumEntries: $assetPath',
        );
        return null;
      }

      return hadiths;
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to load hadith dataset: $assetPath',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
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

final hadithServiceWithLocaleProvider = Provider<HadithService>((ref) {
  return ref.watch(hadithServiceProvider);
});

final dailyHadithProvider = FutureProvider<Hadith?>((ref) async {
  final language = ref.watch(currentLanguageCodeProvider);
  return ref
      .watch(hadithServiceProvider)
      .getHadithOfDay(forcedLanguage: language);
});

final allHadithsProvider = FutureProvider<List<Hadith>>((ref) async {
  final language = ref.watch(currentLanguageCodeProvider);
  return ref.watch(hadithServiceProvider).loadAll(forcedLanguage: language);
});

final hadithFavoritesProvider = FutureProvider<Set<int>>((ref) async {
  return ref.watch(hadithServiceProvider).getFavorites();
});
