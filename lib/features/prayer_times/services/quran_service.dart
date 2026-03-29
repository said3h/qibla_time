import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

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
  // Using Al-Quran Cloud API
  static Future<QuranVerse> getDailyVerse(String languageCode) async {
    // We pick a pseudo-random verse based on the day of the year
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    // There are 6236 verses in the Quran
    final verseNumber = (dayOfYear * 7) % 6236 + 1;

    // Fetch Arabic original
    try {
      final arabicResponse = await http.get(Uri.parse('https://api.alquran.cloud/v1/ayah/$verseNumber/editions/quran-uthmani,es.garcia,en.transliteration'));

      if (arabicResponse.statusCode == 200) {
        final data = json.decode(arabicResponse.body)['data'];

        // data[0] is Arabic (quran-uthmani)
        // data[1] is Spanish (es.garcia) - translation with proper accents
        // data[2] is Transliteration (en.transliteration)

        return QuranVerse(
          arabicText: data[0]['text'],
          translationText: data[1]['text'],
          transliterationText: data[2]['text'],
          reference: '${data[0]['surah']['englishName']} [${data[0]['surah']['number']}:${data[0]['numberInSurah']}]',
          audioUrl: 'https://cdn.islamic.network/quran/audio/128/ar.alafasy/$verseNumber.mp3',
        );
      } else {
        throw Exception('Failed to load daily verse');
      }
    } catch (e) {
      // Offline Fallback: Ayat al-Kursi
      return QuranVerse(
        arabicText: 'Ù±Ù„Ù„Ù‘ÙŽÙ‡Ù Ù„ÙŽØ§Ù“ Ø¥ÙÙ„ÙŽÙ°Ù‡ÙŽ Ø¥ÙÙ„Ù‘ÙŽØ§ Ù‡ÙÙˆÙŽ Ù±Ù„Ù’Ø­ÙŽÙ‰Ù‘Ù Ù±Ù„Ù’Ù‚ÙŽÙŠÙ‘ÙÙˆÙ…Ù Ûš Ù„ÙŽØ§ ØªÙŽØ£Ù’Ø®ÙØ°ÙÙ‡ÙÛ¥ Ø³ÙÙ†ÙŽØ©ÙŒ ÙˆÙŽÙ„ÙŽØ§ Ù†ÙŽÙˆÙ’Ù…ÙŒ',
        translationText: 'Allah! No hay mÃ¡s dios que Ã‰l, el Viviente, el Subsistente por SÃ­ mismo. Ni la somnolencia ni el sueÃ±o se apoderan de Ã‰l.',
        transliterationText: 'Allahu la ilaha illa huwal hayyul qayyum...',
        reference: 'Al-Baqara [2:255]',
        audioUrl: '',
      );
    }
  }
}

final dailyVerseProvider = FutureProvider<QuranVerse>((ref) async {
  return QuranVerseService.getDailyVerse('es');
});
