import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/localization/locale_controller.dart';
import '../../../l10n/l10n.dart';

class QuranVerse {
  final String arabicText;
  final String translationText;
  final String transliterationText;
  final String reference;
  final String audioUrl;

  QuranVerse({
    required this.arabicText,
    required this.translationText,
    required this.transliterationText,
    required this.reference,
    required this.audioUrl,
  });
}

class QuranVerseService {
  static Future<QuranVerse> getDailyVerse(String languageCode) async {
    final normalizedLanguage = _normalizedLanguageCode(languageCode);
    final translationEdition = _translationEditionFor(normalizedLanguage);
    final referenceNameField =
        normalizedLanguage == 'ar' ? 'name' : 'englishName';
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    final verseNumber = (dayOfYear * 7) % 6236 + 1;

    try {
      final response = await http.get(
        Uri.parse(
          'https://api.alquran.cloud/v1/ayah/$verseNumber/editions/quran-uthmani,$translationEdition,en.transliteration',
        ),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to load daily verse');
      }

      final data = json.decode(response.body)['data'];

      return QuranVerse(
        arabicText: data[0]['text'],
        translationText: data[1]['text'],
        transliterationText: data[2]['text'],
        reference:
            '${data[0]['surah'][referenceNameField]} [${data[0]['surah']['number']}:${data[0]['numberInSurah']}]',
        audioUrl:
            'https://cdn.islamic.network/quran/audio/128/ar.alafasy/$verseNumber.mp3',
      );
    } catch (_) {
      final l10n = appLocalizationsForLocaleCode(normalizedLanguage);
      return QuranVerse(
        arabicText:
            'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُۥ سِنَةٌ وَلَا نَوْمٌ',
        translationText: l10n.quranDailyVerseFallbackTranslation,
        transliterationText: l10n.quranDailyVerseFallbackTransliteration,
        reference: l10n.quranDailyVerseFallbackReference,
        audioUrl: '',
      );
    }
  }

  static String _normalizedLanguageCode(String languageCode) {
    return switch (languageCode) {
      'ar' => 'ar',
      'en' => 'en',
      _ => 'es',
    };
  }

  static String _translationEditionFor(String languageCode) {
    return switch (languageCode) {
      'ar' => 'ar.muyassar',
      'en' => 'en.sahih',
      _ => 'es.garcia',
    };
  }
}

final dailyVerseProvider = FutureProvider<QuranVerse>((ref) async {
  final language = ref.watch(currentLanguageCodeProvider);
  return QuranVerseService.getDailyVerse(language);
});
