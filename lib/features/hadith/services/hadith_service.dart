import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/storage_service.dart';
import '../models/hadith.dart';

class HadithService {
  Box get _box => Hive.box(StorageService.hadithBox);

  Future<List<Hadith>> loadAll() async {
    final raw = await rootBundle.loadString('assets/hadiths/daily_hadiths.json');
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => Hadith.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Hadith?> getHadithOfDay() async {
    final hadiths = await loadAll();
    if (hadiths.isEmpty) return null;
    final now = DateTime.now();
    final seed = now.year * 10000 + now.month * 100 + now.day;
    return hadiths[seed % hadiths.length];
  }

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
