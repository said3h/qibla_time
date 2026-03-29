// lib/features/quran/services/quran_service.dart
//
// Estrategia offline-first:
//   1. Intenta la API (api.alquran.cloud)
//   2. Si falla (sin internet, timeout, error) â†’ usa JSON local
//   3. El JSON local estÃ¡ en assets/data/quran_offline.json
//
// El usuario nunca ve un error â€” siempre ve contenido.

import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/quran_models.dart';

// â”€â”€ Providers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

final quranServiceProvider = Provider<QuranService>((ref) {
  return QuranService();
});

final quranSurahsProvider = Provider<List<SurahSummary>>((ref) {
  return QuranService.allSurahs;
});

final surahDetailProvider = FutureProvider.family<SurahDetail, SurahSummary>(
  (ref, summary) async {
    final service = ref.read(quranServiceProvider);
    return (await service.getSurahDetail(summary)).detail;
  },
);

final surahLoadResultProvider =
    FutureProvider.family<SurahLoadResult, SurahSummary>(
  (ref, summary) async {
    final service = ref.read(quranServiceProvider);
    return service.getSurahDetail(summary);
  },
);

// â”€â”€ Servicio â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class QuranService {
  static const _baseUrl = 'https://api.alquran.cloud/v1';
  static const _timeoutSeconds = 8;

  // Cache en memoria para no releer el JSON en cada peticiÃ³n
  static Map<int, SurahDetail>? _offlineCache;

  // â”€â”€ Obtener detalle de una sura â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<SurahLoadResult> getSurahDetail(SurahSummary summary) async {
    try {
      return SurahLoadResult(
        detail: await _fetchFromApi(summary),
        source: SurahLoadSource.online,
      );
    } catch (_) {
      // API fallÃ³ â†’ fallback al JSON local
      return _fetchFromLocal(summary.number);
    }
  }

  // â”€â”€ API online â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<SurahDetail> _fetchFromApi(SurahSummary summary) async {
    // PeticiÃ³n paralela: Ã¡rabe + espaÃ±ol (GarcÃ­a con tildes) + transliteraciÃ³n
    final responses = await Future.wait([
      http.get(
        Uri.parse('$_baseUrl/surah/${summary.number}/ar.alafasy'),
      ).timeout(const Duration(seconds: _timeoutSeconds)),
      http.get(
        Uri.parse('$_baseUrl/surah/${summary.number}/es.garcia'),
      ).timeout(const Duration(seconds: _timeoutSeconds)),
      http.get(
        Uri.parse('$_baseUrl/surah/${summary.number}/en.transliteration'),
      ).timeout(const Duration(seconds: _timeoutSeconds)),
    ]);

    for (final r in responses) {
      if (r.statusCode != 200) throw Exception('API error ${r.statusCode}');
    }

    final arabicData  = json.decode(responses[0].body)['data'];
    final spanishData = json.decode(responses[1].body)['data'];
    final translitData= json.decode(responses[2].body)['data'];

    final arabicAyahs   = arabicData['ayahs']   as List;
    final spanishAyahs  = spanishData['ayahs']  as List;
    final translitAyahs = translitData['ayahs'] as List;

    final ayahs = List.generate(arabicAyahs.length, (i) {
      return SurahAyah(
        number:          arabicAyahs[i]['number'],
        numberInSurah:   arabicAyahs[i]['numberInSurah'],
        arabic:          arabicAyahs[i]['text'],
        transliteration: i < translitAyahs.length
            ? translitAyahs[i]['text'] ?? ''
            : '',
        translation:     i < spanishAyahs.length
            ? spanishAyahs[i]['text'] ?? ''
            : '',
        audioUrl: 'https://cdn.islamic.network/quran/audio/128/ar.alafasy/'
            '${arabicAyahs[i]['number']}.mp3',
      );
    });

    return SurahDetail(summary: summary, ayahs: ayahs);
  }

  // â”€â”€ JSON local (fallback) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<SurahLoadResult> _fetchFromLocal(int surahNumber) async {
    // Cargar y cachear el JSON completo la primera vez
    if (_offlineCache == null) {
      await _loadOfflineCache();
    }

    final detail = _offlineCache?[surahNumber];
    if (detail != null) {
      return SurahLoadResult(
        detail: detail,
        source: SurahLoadSource.offline,
      );
    }

    // Si la sura no estÃ¡ en el JSON local devolvemos un placeholder
    return SurahLoadResult(
      source: SurahLoadSource.placeholder,
      detail: SurahDetail(
        summary: allSurahs.firstWhere(
          (s) => s.number == surahNumber,
          orElse: () => allSurahs.first,
        ),
        ayahs: [
          SurahAyah(
            number: 0,
            numberInSurah: 0,
            arabic: 'Ø¨ÙØ³Ù’Ù…Ù Ø§Ù„Ù„ÙŽÙ‘Ù‡Ù Ø§Ù„Ø±ÙŽÙ‘Ø­Ù’Ù…ÙŽÙ†Ù Ø§Ù„Ø±ÙŽÙ‘Ø­ÙÙŠÙ…Ù',
            transliteration: 'Bismi llahi r-rahmani r-rahim',
            translation: 'Contenido no disponible sin conexiÃ³n a internet.',
            audioUrl: '',
          ),
        ],
      ),
    );
  }

  Future<void> _loadOfflineCache() async {
    try {
      final jsonString = await rootBundle
          .loadString('assets/data/quran_offline.json');
      final data = json.decode(jsonString) as Map<String, dynamic>;

      _offlineCache = {};
      for (final entry in data['surahs'].entries) {
        final number = int.parse(entry.key);
        final surahData = entry.value as Map<String, dynamic>;

        final summary = allSurahs.firstWhere(
          (s) => s.number == number,
          orElse: () => allSurahs.first,
        );

        final ayahsList = surahData['ayahs'] as List;
        final ayahs = ayahsList.map((a) => SurahAyah(
          number:          a['number'],
          numberInSurah:   a['numberInSurah'],
          arabic:          a['arabic'] ?? '',
          transliteration: a['transliteration'] ?? '',
          translation:     a['translation'] ?? '',
          audioUrl:        a['audioUrl'] ?? '',
        )).toList();

        _offlineCache![number] = SurahDetail(summary: summary, ayahs: ayahs);
      }
    } catch (e) {
      _offlineCache = {}; // evita reintentar en bucle si el asset falta
    }
  }

  // â”€â”€ Lista completa de 114 suras â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  static List<SurahSummary> get allSurahs => [
    SurahSummary(number: 1,   nameArabic: 'Ø§Ù„ÙØ§ØªØ­Ø©',       nameLatin: 'Al-Fatiha',       revelationType: 'Meccan',  ayahCount: 7),
    SurahSummary(number: 2,   nameArabic: 'Ø§Ù„Ø¨Ù‚Ø±Ø©',         nameLatin: 'Al-Baqarah',      revelationType: 'Medinan', ayahCount: 286),
    SurahSummary(number: 3,   nameArabic: 'Ø¢Ù„ Ø¹Ù…Ø±Ø§Ù†',       nameLatin: 'Ali \'Imran',     revelationType: 'Medinan', ayahCount: 200),
    SurahSummary(number: 4,   nameArabic: 'Ø§Ù„Ù†Ø³Ø§Ø¡',         nameLatin: 'An-Nisa',         revelationType: 'Medinan', ayahCount: 176),
    SurahSummary(number: 5,   nameArabic: 'Ø§Ù„Ù…Ø§Ø¦Ø¯Ø©',        nameLatin: 'Al-Ma\'idah',     revelationType: 'Medinan', ayahCount: 120),
    SurahSummary(number: 6,   nameArabic: 'Ø§Ù„Ø£Ù†Ø¹Ø§Ù…',        nameLatin: 'Al-An\'am',       revelationType: 'Meccan',  ayahCount: 165),
    SurahSummary(number: 7,   nameArabic: 'Ø§Ù„Ø£Ø¹Ø±Ø§Ù',        nameLatin: 'Al-A\'raf',       revelationType: 'Meccan',  ayahCount: 206),
    SurahSummary(number: 8,   nameArabic: 'Ø§Ù„Ø£Ù†ÙØ§Ù„',        nameLatin: 'Al-Anfal',        revelationType: 'Medinan', ayahCount: 75),
    SurahSummary(number: 9,   nameArabic: 'Ø§Ù„ØªÙˆØ¨Ø©',         nameLatin: 'At-Tawbah',       revelationType: 'Medinan', ayahCount: 129),
    SurahSummary(number: 10,  nameArabic: 'ÙŠÙˆÙ†Ø³',           nameLatin: 'Yunus',           revelationType: 'Meccan',  ayahCount: 109),
    SurahSummary(number: 11,  nameArabic: 'Ù‡ÙˆØ¯',            nameLatin: 'Hud',             revelationType: 'Meccan',  ayahCount: 123),
    SurahSummary(number: 12,  nameArabic: 'ÙŠÙˆØ³Ù',           nameLatin: 'Yusuf',           revelationType: 'Meccan',  ayahCount: 111),
    SurahSummary(number: 13,  nameArabic: 'Ø§Ù„Ø±Ø¹Ø¯',          nameLatin: 'Ar-Ra\'d',        revelationType: 'Medinan', ayahCount: 43),
    SurahSummary(number: 14,  nameArabic: 'Ø¥Ø¨Ø±Ø§Ù‡ÙŠÙ…',        nameLatin: 'Ibrahim',         revelationType: 'Meccan',  ayahCount: 52),
    SurahSummary(number: 15,  nameArabic: 'Ø§Ù„Ø­Ø¬Ø±',          nameLatin: 'Al-Hijr',         revelationType: 'Meccan',  ayahCount: 99),
    SurahSummary(number: 16,  nameArabic: 'Ø§Ù„Ù†Ø­Ù„',          nameLatin: 'An-Nahl',         revelationType: 'Meccan',  ayahCount: 128),
    SurahSummary(number: 17,  nameArabic: 'Ø§Ù„Ø¥Ø³Ø±Ø§Ø¡',        nameLatin: 'Al-Isra',         revelationType: 'Meccan',  ayahCount: 111),
    SurahSummary(number: 18,  nameArabic: 'Ø§Ù„ÙƒÙ‡Ù',          nameLatin: 'Al-Kahf',         revelationType: 'Meccan',  ayahCount: 110),
    SurahSummary(number: 19,  nameArabic: 'Ù…Ø±ÙŠÙ…',           nameLatin: 'Maryam',          revelationType: 'Meccan',  ayahCount: 98),
    SurahSummary(number: 20,  nameArabic: 'Ø·Ù‡',             nameLatin: 'Ta-Ha',           revelationType: 'Meccan',  ayahCount: 135),
    SurahSummary(number: 21,  nameArabic: 'Ø§Ù„Ø£Ù†Ø¨ÙŠØ§Ø¡',       nameLatin: 'Al-Anbiya',       revelationType: 'Meccan',  ayahCount: 112),
    SurahSummary(number: 22,  nameArabic: 'Ø§Ù„Ø­Ø¬',           nameLatin: 'Al-Hajj',         revelationType: 'Medinan', ayahCount: 78),
    SurahSummary(number: 23,  nameArabic: 'Ø§Ù„Ù…Ø¤Ù…Ù†ÙˆÙ†',       nameLatin: 'Al-Mu\'minun',    revelationType: 'Meccan',  ayahCount: 118),
    SurahSummary(number: 24,  nameArabic: 'Ø§Ù„Ù†ÙˆØ±',          nameLatin: 'An-Nur',          revelationType: 'Medinan', ayahCount: 64),
    SurahSummary(number: 25,  nameArabic: 'Ø§Ù„ÙØ±Ù‚Ø§Ù†',        nameLatin: 'Al-Furqan',       revelationType: 'Meccan',  ayahCount: 77),
    SurahSummary(number: 26,  nameArabic: 'Ø§Ù„Ø´Ø¹Ø±Ø§Ø¡',        nameLatin: 'Ash-Shu\'ara',    revelationType: 'Meccan',  ayahCount: 227),
    SurahSummary(number: 27,  nameArabic: 'Ø§Ù„Ù†Ù…Ù„',          nameLatin: 'An-Naml',         revelationType: 'Meccan',  ayahCount: 93),
    SurahSummary(number: 28,  nameArabic: 'Ø§Ù„Ù‚ØµØµ',          nameLatin: 'Al-Qasas',        revelationType: 'Meccan',  ayahCount: 88),
    SurahSummary(number: 29,  nameArabic: 'Ø§Ù„Ø¹Ù†ÙƒØ¨ÙˆØª',       nameLatin: 'Al-\'Ankabut',    revelationType: 'Meccan',  ayahCount: 69),
    SurahSummary(number: 30,  nameArabic: 'Ø§Ù„Ø±ÙˆÙ…',          nameLatin: 'Ar-Rum',          revelationType: 'Meccan',  ayahCount: 60),
    SurahSummary(number: 31,  nameArabic: 'Ù„Ù‚Ù…Ø§Ù†',          nameLatin: 'Luqman',          revelationType: 'Meccan',  ayahCount: 34),
    SurahSummary(number: 32,  nameArabic: 'Ø§Ù„Ø³Ø¬Ø¯Ø©',         nameLatin: 'As-Sajdah',       revelationType: 'Meccan',  ayahCount: 30),
    SurahSummary(number: 33,  nameArabic: 'Ø§Ù„Ø£Ø­Ø²Ø§Ø¨',        nameLatin: 'Al-Ahzab',        revelationType: 'Medinan', ayahCount: 73),
    SurahSummary(number: 34,  nameArabic: 'Ø³Ø¨Ø£',            nameLatin: 'Saba',            revelationType: 'Meccan',  ayahCount: 54),
    SurahSummary(number: 35,  nameArabic: 'ÙØ§Ø·Ø±',           nameLatin: 'Fatir',           revelationType: 'Meccan',  ayahCount: 45),
    SurahSummary(number: 36,  nameArabic: 'ÙŠØ³',             nameLatin: 'Ya-Sin',          revelationType: 'Meccan',  ayahCount: 83),
    SurahSummary(number: 37,  nameArabic: 'Ø§Ù„ØµØ§ÙØ§Øª',        nameLatin: 'As-Saffat',       revelationType: 'Meccan',  ayahCount: 182),
    SurahSummary(number: 38,  nameArabic: 'Øµ',              nameLatin: 'Sad',             revelationType: 'Meccan',  ayahCount: 88),
    SurahSummary(number: 39,  nameArabic: 'Ø§Ù„Ø²Ù…Ø±',          nameLatin: 'Az-Zumar',        revelationType: 'Meccan',  ayahCount: 75),
    SurahSummary(number: 40,  nameArabic: 'ØºØ§ÙØ±',           nameLatin: 'Ghafir',          revelationType: 'Meccan',  ayahCount: 85),
    SurahSummary(number: 41,  nameArabic: 'ÙØµÙ„Øª',           nameLatin: 'Fussilat',        revelationType: 'Meccan',  ayahCount: 54),
    SurahSummary(number: 42,  nameArabic: 'Ø§Ù„Ø´ÙˆØ±Ù‰',         nameLatin: 'Ash-Shuraa',      revelationType: 'Meccan',  ayahCount: 53),
    SurahSummary(number: 43,  nameArabic: 'Ø§Ù„Ø²Ø®Ø±Ù',         nameLatin: 'Az-Zukhruf',      revelationType: 'Meccan',  ayahCount: 89),
    SurahSummary(number: 44,  nameArabic: 'Ø§Ù„Ø¯Ø®Ø§Ù†',         nameLatin: 'Ad-Dukhan',       revelationType: 'Meccan',  ayahCount: 59),
    SurahSummary(number: 45,  nameArabic: 'Ø§Ù„Ø¬Ø§Ø«ÙŠØ©',        nameLatin: 'Al-Jathiyah',     revelationType: 'Meccan',  ayahCount: 37),
    SurahSummary(number: 46,  nameArabic: 'Ø§Ù„Ø£Ø­Ù‚Ø§Ù',        nameLatin: 'Al-Ahqaf',        revelationType: 'Meccan',  ayahCount: 35),
    SurahSummary(number: 47,  nameArabic: 'Ù…Ø­Ù…Ø¯',           nameLatin: 'Muhammad',        revelationType: 'Medinan', ayahCount: 38),
    SurahSummary(number: 48,  nameArabic: 'Ø§Ù„ÙØªØ­',          nameLatin: 'Al-Fath',         revelationType: 'Medinan', ayahCount: 29),
    SurahSummary(number: 49,  nameArabic: 'Ø§Ù„Ø­Ø¬Ø±Ø§Øª',        nameLatin: 'Al-Hujurat',      revelationType: 'Medinan', ayahCount: 18),
    SurahSummary(number: 50,  nameArabic: 'Ù‚',              nameLatin: 'Qaf',             revelationType: 'Meccan',  ayahCount: 45),
    SurahSummary(number: 51,  nameArabic: 'Ø§Ù„Ø°Ø§Ø±ÙŠØ§Øª',       nameLatin: 'Adh-Dhariyat',    revelationType: 'Meccan',  ayahCount: 60),
    SurahSummary(number: 52,  nameArabic: 'Ø§Ù„Ø·ÙˆØ±',          nameLatin: 'At-Tur',          revelationType: 'Meccan',  ayahCount: 49),
    SurahSummary(number: 53,  nameArabic: 'Ø§Ù„Ù†Ø¬Ù…',          nameLatin: 'An-Najm',         revelationType: 'Meccan',  ayahCount: 62),
    SurahSummary(number: 54,  nameArabic: 'Ø§Ù„Ù‚Ù…Ø±',          nameLatin: 'Al-Qamar',        revelationType: 'Meccan',  ayahCount: 55),
    SurahSummary(number: 55,  nameArabic: 'Ø§Ù„Ø±Ø­Ù…Ù†',         nameLatin: 'Ar-Rahman',       revelationType: 'Medinan', ayahCount: 78),
    SurahSummary(number: 56,  nameArabic: 'Ø§Ù„ÙˆØ§Ù‚Ø¹Ø©',        nameLatin: 'Al-Waqi\'ah',     revelationType: 'Meccan',  ayahCount: 96),
    SurahSummary(number: 57,  nameArabic: 'Ø§Ù„Ø­Ø¯ÙŠØ¯',         nameLatin: 'Al-Hadid',        revelationType: 'Medinan', ayahCount: 29),
    SurahSummary(number: 58,  nameArabic: 'Ø§Ù„Ù…Ø¬Ø§Ø¯Ù„Ø©',       nameLatin: 'Al-Mujadila',     revelationType: 'Medinan', ayahCount: 22),
    SurahSummary(number: 59,  nameArabic: 'Ø§Ù„Ø­Ø´Ø±',          nameLatin: 'Al-Hashr',        revelationType: 'Medinan', ayahCount: 24),
    SurahSummary(number: 60,  nameArabic: 'Ø§Ù„Ù…Ù…ØªØ­Ù†Ø©',       nameLatin: 'Al-Mumtahanah',   revelationType: 'Medinan', ayahCount: 13),
    SurahSummary(number: 61,  nameArabic: 'Ø§Ù„ØµÙ',           nameLatin: 'As-Saf',          revelationType: 'Medinan', ayahCount: 14),
    SurahSummary(number: 62,  nameArabic: 'Ø§Ù„Ø¬Ù…Ø¹Ø©',         nameLatin: 'Al-Jumu\'ah',     revelationType: 'Medinan', ayahCount: 11),
    SurahSummary(number: 63,  nameArabic: 'Ø§Ù„Ù…Ù†Ø§ÙÙ‚ÙˆÙ†',      nameLatin: 'Al-Munafiqun',    revelationType: 'Medinan', ayahCount: 11),
    SurahSummary(number: 64,  nameArabic: 'Ø§Ù„ØªØºØ§Ø¨Ù†',        nameLatin: 'At-Taghabun',     revelationType: 'Medinan', ayahCount: 18),
    SurahSummary(number: 65,  nameArabic: 'Ø§Ù„Ø·Ù„Ø§Ù‚',         nameLatin: 'At-Talaq',        revelationType: 'Medinan', ayahCount: 12),
    SurahSummary(number: 66,  nameArabic: 'Ø§Ù„ØªØ­Ø±ÙŠÙ…',        nameLatin: 'At-Tahrim',       revelationType: 'Medinan', ayahCount: 12),
    SurahSummary(number: 67,  nameArabic: 'Ø§Ù„Ù…Ù„Ùƒ',          nameLatin: 'Al-Mulk',         revelationType: 'Meccan',  ayahCount: 30),
    SurahSummary(number: 68,  nameArabic: 'Ø§Ù„Ù‚Ù„Ù…',          nameLatin: 'Al-Qalam',        revelationType: 'Meccan',  ayahCount: 52),
    SurahSummary(number: 69,  nameArabic: 'Ø§Ù„Ø­Ø§Ù‚Ø©',         nameLatin: 'Al-Haqqah',       revelationType: 'Meccan',  ayahCount: 52),
    SurahSummary(number: 70,  nameArabic: 'Ø§Ù„Ù…Ø¹Ø§Ø±Ø¬',        nameLatin: 'Al-Ma\'arij',     revelationType: 'Meccan',  ayahCount: 44),
    SurahSummary(number: 71,  nameArabic: 'Ù†ÙˆØ­',            nameLatin: 'Nuh',             revelationType: 'Meccan',  ayahCount: 28),
    SurahSummary(number: 72,  nameArabic: 'Ø§Ù„Ø¬Ù†',           nameLatin: 'Al-Jinn',         revelationType: 'Meccan',  ayahCount: 28),
    SurahSummary(number: 73,  nameArabic: 'Ø§Ù„Ù…Ø²Ù…Ù„',         nameLatin: 'Al-Muzzammil',    revelationType: 'Meccan',  ayahCount: 20),
    SurahSummary(number: 74,  nameArabic: 'Ø§Ù„Ù…Ø¯Ø«Ø±',         nameLatin: 'Al-Muddaththir',  revelationType: 'Meccan',  ayahCount: 56),
    SurahSummary(number: 75,  nameArabic: 'Ø§Ù„Ù‚ÙŠØ§Ù…Ø©',        nameLatin: 'Al-Qiyamah',      revelationType: 'Meccan',  ayahCount: 40),
    SurahSummary(number: 76,  nameArabic: 'Ø§Ù„Ø¥Ù†Ø³Ø§Ù†',        nameLatin: 'Al-Insan',        revelationType: 'Medinan', ayahCount: 31),
    SurahSummary(number: 77,  nameArabic: 'Ø§Ù„Ù…Ø±Ø³Ù„Ø§Øª',       nameLatin: 'Al-Mursalat',     revelationType: 'Meccan',  ayahCount: 50),
    SurahSummary(number: 78,  nameArabic: 'Ø§Ù„Ù†Ø¨Ø£',          nameLatin: 'An-Naba',         revelationType: 'Meccan',  ayahCount: 40),
    SurahSummary(number: 79,  nameArabic: 'Ø§Ù„Ù†Ø§Ø²Ø¹Ø§Øª',       nameLatin: 'An-Nazi\'at',     revelationType: 'Meccan',  ayahCount: 46),
    SurahSummary(number: 80,  nameArabic: 'Ø¹Ø¨Ø³',            nameLatin: '\'Abasa',         revelationType: 'Meccan',  ayahCount: 42),
    SurahSummary(number: 81,  nameArabic: 'Ø§Ù„ØªÙƒÙˆÙŠØ±',        nameLatin: 'At-Takwir',       revelationType: 'Meccan',  ayahCount: 29),
    SurahSummary(number: 82,  nameArabic: 'Ø§Ù„Ø§Ù†ÙØ·Ø§Ø±',       nameLatin: 'Al-Infitar',      revelationType: 'Meccan',  ayahCount: 19),
    SurahSummary(number: 83,  nameArabic: 'Ø§Ù„Ù…Ø·ÙÙÙŠÙ†',       nameLatin: 'Al-Mutaffifin',   revelationType: 'Meccan',  ayahCount: 36),
    SurahSummary(number: 84,  nameArabic: 'Ø§Ù„Ø§Ù†Ø´Ù‚Ø§Ù‚',       nameLatin: 'Al-Inshiqaq',     revelationType: 'Meccan',  ayahCount: 25),
    SurahSummary(number: 85,  nameArabic: 'Ø§Ù„Ø¨Ø±ÙˆØ¬',         nameLatin: 'Al-Buruj',        revelationType: 'Meccan',  ayahCount: 22),
    SurahSummary(number: 86,  nameArabic: 'Ø§Ù„Ø·Ø§Ø±Ù‚',         nameLatin: 'At-Tariq',        revelationType: 'Meccan',  ayahCount: 17),
    SurahSummary(number: 87,  nameArabic: 'Ø§Ù„Ø£Ø¹Ù„Ù‰',         nameLatin: 'Al-A\'la',        revelationType: 'Meccan',  ayahCount: 19),
    SurahSummary(number: 88,  nameArabic: 'Ø§Ù„ØºØ§Ø´ÙŠØ©',        nameLatin: 'Al-Ghashiyah',    revelationType: 'Meccan',  ayahCount: 26),
    SurahSummary(number: 89,  nameArabic: 'Ø§Ù„ÙØ¬Ø±',          nameLatin: 'Al-Fajr',         revelationType: 'Meccan',  ayahCount: 30),
    SurahSummary(number: 90,  nameArabic: 'Ø§Ù„Ø¨Ù„Ø¯',          nameLatin: 'Al-Balad',        revelationType: 'Meccan',  ayahCount: 20),
    SurahSummary(number: 91,  nameArabic: 'Ø§Ù„Ø´Ù…Ø³',          nameLatin: 'Ash-Shams',       revelationType: 'Meccan',  ayahCount: 15),
    SurahSummary(number: 92,  nameArabic: 'Ø§Ù„Ù„ÙŠÙ„',          nameLatin: 'Al-Layl',         revelationType: 'Meccan',  ayahCount: 21),
    SurahSummary(number: 93,  nameArabic: 'Ø§Ù„Ø¶Ø­Ù‰',          nameLatin: 'Ad-Duhaa',        revelationType: 'Meccan',  ayahCount: 11),
    SurahSummary(number: 94,  nameArabic: 'Ø§Ù„Ø´Ø±Ø­',          nameLatin: 'Ash-Sharh',       revelationType: 'Meccan',  ayahCount: 8),
    SurahSummary(number: 95,  nameArabic: 'Ø§Ù„ØªÙŠÙ†',          nameLatin: 'At-Tin',          revelationType: 'Meccan',  ayahCount: 8),
    SurahSummary(number: 96,  nameArabic: 'Ø§Ù„Ø¹Ù„Ù‚',          nameLatin: 'Al-\'Alaq',       revelationType: 'Meccan',  ayahCount: 19),
    SurahSummary(number: 97,  nameArabic: 'Ø§Ù„Ù‚Ø¯Ø±',          nameLatin: 'Al-Qadr',         revelationType: 'Meccan',  ayahCount: 5),
    SurahSummary(number: 98,  nameArabic: 'Ø§Ù„Ø¨ÙŠÙ†Ø©',         nameLatin: 'Al-Bayyinah',     revelationType: 'Medinan', ayahCount: 8),
    SurahSummary(number: 99,  nameArabic: 'Ø§Ù„Ø²Ù„Ø²Ù„Ø©',        nameLatin: 'Az-Zalzalah',     revelationType: 'Medinan', ayahCount: 8),
    SurahSummary(number: 100, nameArabic: 'Ø§Ù„Ø¹Ø§Ø¯ÙŠØ§Øª',       nameLatin: 'Al-\'Adiyat',     revelationType: 'Meccan',  ayahCount: 11),
    SurahSummary(number: 101, nameArabic: 'Ø§Ù„Ù‚Ø§Ø±Ø¹Ø©',        nameLatin: 'Al-Qari\'ah',     revelationType: 'Meccan',  ayahCount: 11),
    SurahSummary(number: 102, nameArabic: 'Ø§Ù„ØªÙƒØ§Ø«Ø±',        nameLatin: 'At-Takathur',     revelationType: 'Meccan',  ayahCount: 8),
    SurahSummary(number: 103, nameArabic: 'Ø§Ù„Ø¹ØµØ±',          nameLatin: 'Al-\'Asr',        revelationType: 'Meccan',  ayahCount: 3),
    SurahSummary(number: 104, nameArabic: 'Ø§Ù„Ù‡Ù…Ø²Ø©',         nameLatin: 'Al-Humazah',      revelationType: 'Meccan',  ayahCount: 9),
    SurahSummary(number: 105, nameArabic: 'Ø§Ù„ÙÙŠÙ„',          nameLatin: 'Al-Fil',          revelationType: 'Meccan',  ayahCount: 5),
    SurahSummary(number: 106, nameArabic: 'Ù‚Ø±ÙŠØ´',           nameLatin: 'Quraysh',         revelationType: 'Meccan',  ayahCount: 4),
    SurahSummary(number: 107, nameArabic: 'Ø§Ù„Ù…Ø§Ø¹ÙˆÙ†',        nameLatin: 'Al-Ma\'un',       revelationType: 'Meccan',  ayahCount: 7),
    SurahSummary(number: 108, nameArabic: 'Ø§Ù„ÙƒÙˆØ«Ø±',         nameLatin: 'Al-Kawthar',      revelationType: 'Meccan',  ayahCount: 3),
    SurahSummary(number: 109, nameArabic: 'Ø§Ù„ÙƒØ§ÙØ±ÙˆÙ†',       nameLatin: 'Al-Kafirun',      revelationType: 'Meccan',  ayahCount: 6),
    SurahSummary(number: 110, nameArabic: 'Ø§Ù„Ù†ØµØ±',          nameLatin: 'An-Nasr',         revelationType: 'Medinan', ayahCount: 3),
    SurahSummary(number: 111, nameArabic: 'Ø§Ù„Ù…Ø³Ø¯',          nameLatin: 'Al-Masad',        revelationType: 'Meccan',  ayahCount: 5),
    SurahSummary(number: 112, nameArabic: 'Ø§Ù„Ø¥Ø®Ù„Ø§Øµ',        nameLatin: 'Al-Ikhlas',       revelationType: 'Meccan',  ayahCount: 4),
    SurahSummary(number: 113, nameArabic: 'Ø§Ù„ÙÙ„Ù‚',          nameLatin: 'Al-Falaq',        revelationType: 'Meccan',  ayahCount: 5),
    SurahSummary(number: 114, nameArabic: 'Ø§Ù„Ù†Ø§Ø³',          nameLatin: 'An-Nas',          revelationType: 'Meccan',  ayahCount: 6),
  ];
}
