import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../models/quran_models.dart';

class QuranReadingService {
  Future<QuranReadingPoint?> getLastReading() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(AppConstants.keyQuranLastReading);
    if (raw == null || raw.isEmpty) return null;
    try {
      return QuranReadingPoint.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> saveLastReading(SurahSummary summary, int ayahNumber) async {
    final prefs = await SharedPreferences.getInstance();
    final point = QuranReadingPoint(
      surahNumber: summary.number,
      surahNameLatin: summary.nameLatin,
      surahNameArabic: summary.nameArabic,
      ayahNumber: ayahNumber,
      savedAt: DateTime.now(),
    );
    await prefs.setString(
      AppConstants.keyQuranLastReading,
      jsonEncode(point.toJson()),
    );
  }

  Future<List<QuranReadingPoint>> getBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(AppConstants.keyQuranBookmarks);
    if (raw == null || raw.isEmpty) return const [];

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final items = decoded
          .map((item) => QuranReadingPoint.fromJson(item as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
      return items;
    } catch (_) {
      return const [];
    }
  }

  Future<bool> toggleBookmark(SurahSummary summary, int ayahNumber) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getBookmarks();
    final existingIndex = current.indexWhere(
      (item) =>
          item.surahNumber == summary.number && item.ayahNumber == ayahNumber,
    );

    if (existingIndex != -1) {
      current.removeAt(existingIndex);
      await prefs.setString(
        AppConstants.keyQuranBookmarks,
        jsonEncode(current.map((item) => item.toJson()).toList()),
      );
      return false;
    }

    final updated = [
      QuranReadingPoint(
        surahNumber: summary.number,
        surahNameLatin: summary.nameLatin,
        surahNameArabic: summary.nameArabic,
        ayahNumber: ayahNumber,
        savedAt: DateTime.now(),
      ),
      ...current,
    ];

    await prefs.setString(
      AppConstants.keyQuranBookmarks,
      jsonEncode(updated.take(8).map((item) => item.toJson()).toList()),
    );
    return true;
  }
}

final quranReadingServiceProvider = Provider<QuranReadingService>((ref) {
  return QuranReadingService();
});

final lastReadingProvider = FutureProvider<QuranReadingPoint?>((ref) async {
  return ref.watch(quranReadingServiceProvider).getLastReading();
});

final quranBookmarksProvider =
    FutureProvider<List<QuranReadingPoint>>((ref) async {
  return ref.watch(quranReadingServiceProvider).getBookmarks();
});
