// lib/features/quran/services/quran_service.dart
//
// Estrategia offline-first:
//   1. Intenta la API (api.alquran.cloud)
//   2. Si falla (sin internet, timeout, error) → usa JSON local
//   3. El JSON local está en assets/data/quran_offline.json
//
// El usuario nunca ve un error — siempre ve contenido.

import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/quran_models.dart';

// ── Providers ──────────────────────────────────────────────────

final quranServiceProvider = Provider<QuranService>((ref) {
  return QuranService();
});

final quranSurahsProvider = Provider<List<SurahSummary>>((ref) {
  return QuranService.allSurahs;
});

final surahDetailProvider = FutureProvider.family<SurahDetail, SurahSummary>(
  (ref, summary) async {
    final service = ref.read(quranServiceProvider);
    return service.getSurahDetail(summary);
  },
);

// ── Servicio ───────────────────────────────────────────────────

class QuranService {
  static const _baseUrl = 'https://api.alquran.cloud/v1';
  static const _timeoutSeconds = 8;

  // Cache en memoria para no releer el JSON en cada petición
  static Map<int, SurahDetail>? _offlineCache;

  // ── Obtener detalle de una sura ─────────────────────────────

  Future<SurahDetail> getSurahDetail(SurahSummary summary) async {
    try {
      return await _fetchFromApi(summary);
    } catch (_) {
      // API falló → fallback al JSON local
      return await _fetchFromLocal(summary.number);
    }
  }

  // ── API online ──────────────────────────────────────────────

  Future<SurahDetail> _fetchFromApi(SurahSummary summary) async {
    // Petición paralela: árabe + español + transliteración
    final responses = await Future.wait([
      http.get(
        Uri.parse('$_baseUrl/surah/${summary.number}/ar.alafasy'),
      ).timeout(const Duration(seconds: _timeoutSeconds)),
      http.get(
        Uri.parse('$_baseUrl/surah/${summary.number}/es.asad'),
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

  // ── JSON local (fallback) ───────────────────────────────────

  Future<SurahDetail> _fetchFromLocal(int surahNumber) async {
    // Cargar y cachear el JSON completo la primera vez
    if (_offlineCache == null) {
      await _loadOfflineCache();
    }

    final detail = _offlineCache?[surahNumber];
    if (detail != null) return detail;

    // Si la sura no está en el JSON local devolvemos un placeholder
    return SurahDetail(
      summary: allSurahs.firstWhere(
        (s) => s.number == surahNumber,
        orElse: () => allSurahs.first,
      ),
      ayahs: [
        SurahAyah(
          number: 0,
          numberInSurah: 0,
          arabic: 'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ',
          transliteration: 'Bismi llāhi r-raḥmāni r-raḥīm',
          translation: 'Contenido no disponible sin conexión a internet.',
          audioUrl: '',
        ),
      ],
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

  // ── Lista completa de 114 suras ─────────────────────────────

  static List<SurahSummary> get allSurahs => [
    SurahSummary(number: 1,   nameArabic: 'الفاتحة',       nameLatin: 'Al-Fatiha',       revelationType: 'Meccan',  ayahCount: 7),
    SurahSummary(number: 2,   nameArabic: 'البقرة',         nameLatin: 'Al-Baqarah',      revelationType: 'Medinan', ayahCount: 286),
    SurahSummary(number: 3,   nameArabic: 'آل عمران',       nameLatin: 'Ali \'Imran',     revelationType: 'Medinan', ayahCount: 200),
    SurahSummary(number: 4,   nameArabic: 'النساء',         nameLatin: 'An-Nisa',         revelationType: 'Medinan', ayahCount: 176),
    SurahSummary(number: 5,   nameArabic: 'المائدة',        nameLatin: 'Al-Ma\'idah',     revelationType: 'Medinan', ayahCount: 120),
    SurahSummary(number: 6,   nameArabic: 'الأنعام',        nameLatin: 'Al-An\'am',       revelationType: 'Meccan',  ayahCount: 165),
    SurahSummary(number: 7,   nameArabic: 'الأعراف',        nameLatin: 'Al-A\'raf',       revelationType: 'Meccan',  ayahCount: 206),
    SurahSummary(number: 8,   nameArabic: 'الأنفال',        nameLatin: 'Al-Anfal',        revelationType: 'Medinan', ayahCount: 75),
    SurahSummary(number: 9,   nameArabic: 'التوبة',         nameLatin: 'At-Tawbah',       revelationType: 'Medinan', ayahCount: 129),
    SurahSummary(number: 10,  nameArabic: 'يونس',           nameLatin: 'Yunus',           revelationType: 'Meccan',  ayahCount: 109),
    SurahSummary(number: 11,  nameArabic: 'هود',            nameLatin: 'Hud',             revelationType: 'Meccan',  ayahCount: 123),
    SurahSummary(number: 12,  nameArabic: 'يوسف',           nameLatin: 'Yusuf',           revelationType: 'Meccan',  ayahCount: 111),
    SurahSummary(number: 13,  nameArabic: 'الرعد',          nameLatin: 'Ar-Ra\'d',        revelationType: 'Medinan', ayahCount: 43),
    SurahSummary(number: 14,  nameArabic: 'إبراهيم',        nameLatin: 'Ibrahim',         revelationType: 'Meccan',  ayahCount: 52),
    SurahSummary(number: 15,  nameArabic: 'الحجر',          nameLatin: 'Al-Hijr',         revelationType: 'Meccan',  ayahCount: 99),
    SurahSummary(number: 16,  nameArabic: 'النحل',          nameLatin: 'An-Nahl',         revelationType: 'Meccan',  ayahCount: 128),
    SurahSummary(number: 17,  nameArabic: 'الإسراء',        nameLatin: 'Al-Isra',         revelationType: 'Meccan',  ayahCount: 111),
    SurahSummary(number: 18,  nameArabic: 'الكهف',          nameLatin: 'Al-Kahf',         revelationType: 'Meccan',  ayahCount: 110),
    SurahSummary(number: 19,  nameArabic: 'مريم',           nameLatin: 'Maryam',          revelationType: 'Meccan',  ayahCount: 98),
    SurahSummary(number: 20,  nameArabic: 'طه',             nameLatin: 'Ta-Ha',           revelationType: 'Meccan',  ayahCount: 135),
    SurahSummary(number: 21,  nameArabic: 'الأنبياء',       nameLatin: 'Al-Anbiya',       revelationType: 'Meccan',  ayahCount: 112),
    SurahSummary(number: 22,  nameArabic: 'الحج',           nameLatin: 'Al-Hajj',         revelationType: 'Medinan', ayahCount: 78),
    SurahSummary(number: 23,  nameArabic: 'المؤمنون',       nameLatin: 'Al-Mu\'minun',    revelationType: 'Meccan',  ayahCount: 118),
    SurahSummary(number: 24,  nameArabic: 'النور',          nameLatin: 'An-Nur',          revelationType: 'Medinan', ayahCount: 64),
    SurahSummary(number: 25,  nameArabic: 'الفرقان',        nameLatin: 'Al-Furqan',       revelationType: 'Meccan',  ayahCount: 77),
    SurahSummary(number: 26,  nameArabic: 'الشعراء',        nameLatin: 'Ash-Shu\'ara',    revelationType: 'Meccan',  ayahCount: 227),
    SurahSummary(number: 27,  nameArabic: 'النمل',          nameLatin: 'An-Naml',         revelationType: 'Meccan',  ayahCount: 93),
    SurahSummary(number: 28,  nameArabic: 'القصص',          nameLatin: 'Al-Qasas',        revelationType: 'Meccan',  ayahCount: 88),
    SurahSummary(number: 29,  nameArabic: 'العنكبوت',       nameLatin: 'Al-\'Ankabut',    revelationType: 'Meccan',  ayahCount: 69),
    SurahSummary(number: 30,  nameArabic: 'الروم',          nameLatin: 'Ar-Rum',          revelationType: 'Meccan',  ayahCount: 60),
    SurahSummary(number: 31,  nameArabic: 'لقمان',          nameLatin: 'Luqman',          revelationType: 'Meccan',  ayahCount: 34),
    SurahSummary(number: 32,  nameArabic: 'السجدة',         nameLatin: 'As-Sajdah',       revelationType: 'Meccan',  ayahCount: 30),
    SurahSummary(number: 33,  nameArabic: 'الأحزاب',        nameLatin: 'Al-Ahzab',        revelationType: 'Medinan', ayahCount: 73),
    SurahSummary(number: 34,  nameArabic: 'سبأ',            nameLatin: 'Saba',            revelationType: 'Meccan',  ayahCount: 54),
    SurahSummary(number: 35,  nameArabic: 'فاطر',           nameLatin: 'Fatir',           revelationType: 'Meccan',  ayahCount: 45),
    SurahSummary(number: 36,  nameArabic: 'يس',             nameLatin: 'Ya-Sin',          revelationType: 'Meccan',  ayahCount: 83),
    SurahSummary(number: 37,  nameArabic: 'الصافات',        nameLatin: 'As-Saffat',       revelationType: 'Meccan',  ayahCount: 182),
    SurahSummary(number: 38,  nameArabic: 'ص',              nameLatin: 'Sad',             revelationType: 'Meccan',  ayahCount: 88),
    SurahSummary(number: 39,  nameArabic: 'الزمر',          nameLatin: 'Az-Zumar',        revelationType: 'Meccan',  ayahCount: 75),
    SurahSummary(number: 40,  nameArabic: 'غافر',           nameLatin: 'Ghafir',          revelationType: 'Meccan',  ayahCount: 85),
    SurahSummary(number: 41,  nameArabic: 'فصلت',           nameLatin: 'Fussilat',        revelationType: 'Meccan',  ayahCount: 54),
    SurahSummary(number: 42,  nameArabic: 'الشورى',         nameLatin: 'Ash-Shuraa',      revelationType: 'Meccan',  ayahCount: 53),
    SurahSummary(number: 43,  nameArabic: 'الزخرف',         nameLatin: 'Az-Zukhruf',      revelationType: 'Meccan',  ayahCount: 89),
    SurahSummary(number: 44,  nameArabic: 'الدخان',         nameLatin: 'Ad-Dukhan',       revelationType: 'Meccan',  ayahCount: 59),
    SurahSummary(number: 45,  nameArabic: 'الجاثية',        nameLatin: 'Al-Jathiyah',     revelationType: 'Meccan',  ayahCount: 37),
    SurahSummary(number: 46,  nameArabic: 'الأحقاف',        nameLatin: 'Al-Ahqaf',        revelationType: 'Meccan',  ayahCount: 35),
    SurahSummary(number: 47,  nameArabic: 'محمد',           nameLatin: 'Muhammad',        revelationType: 'Medinan', ayahCount: 38),
    SurahSummary(number: 48,  nameArabic: 'الفتح',          nameLatin: 'Al-Fath',         revelationType: 'Medinan', ayahCount: 29),
    SurahSummary(number: 49,  nameArabic: 'الحجرات',        nameLatin: 'Al-Hujurat',      revelationType: 'Medinan', ayahCount: 18),
    SurahSummary(number: 50,  nameArabic: 'ق',              nameLatin: 'Qaf',             revelationType: 'Meccan',  ayahCount: 45),
    SurahSummary(number: 51,  nameArabic: 'الذاريات',       nameLatin: 'Adh-Dhariyat',    revelationType: 'Meccan',  ayahCount: 60),
    SurahSummary(number: 52,  nameArabic: 'الطور',          nameLatin: 'At-Tur',          revelationType: 'Meccan',  ayahCount: 49),
    SurahSummary(number: 53,  nameArabic: 'النجم',          nameLatin: 'An-Najm',         revelationType: 'Meccan',  ayahCount: 62),
    SurahSummary(number: 54,  nameArabic: 'القمر',          nameLatin: 'Al-Qamar',        revelationType: 'Meccan',  ayahCount: 55),
    SurahSummary(number: 55,  nameArabic: 'الرحمن',         nameLatin: 'Ar-Rahman',       revelationType: 'Medinan', ayahCount: 78),
    SurahSummary(number: 56,  nameArabic: 'الواقعة',        nameLatin: 'Al-Waqi\'ah',     revelationType: 'Meccan',  ayahCount: 96),
    SurahSummary(number: 57,  nameArabic: 'الحديد',         nameLatin: 'Al-Hadid',        revelationType: 'Medinan', ayahCount: 29),
    SurahSummary(number: 58,  nameArabic: 'المجادلة',       nameLatin: 'Al-Mujadila',     revelationType: 'Medinan', ayahCount: 22),
    SurahSummary(number: 59,  nameArabic: 'الحشر',          nameLatin: 'Al-Hashr',        revelationType: 'Medinan', ayahCount: 24),
    SurahSummary(number: 60,  nameArabic: 'الممتحنة',       nameLatin: 'Al-Mumtahanah',   revelationType: 'Medinan', ayahCount: 13),
    SurahSummary(number: 61,  nameArabic: 'الصف',           nameLatin: 'As-Saf',          revelationType: 'Medinan', ayahCount: 14),
    SurahSummary(number: 62,  nameArabic: 'الجمعة',         nameLatin: 'Al-Jumu\'ah',     revelationType: 'Medinan', ayahCount: 11),
    SurahSummary(number: 63,  nameArabic: 'المنافقون',      nameLatin: 'Al-Munafiqun',    revelationType: 'Medinan', ayahCount: 11),
    SurahSummary(number: 64,  nameArabic: 'التغابن',        nameLatin: 'At-Taghabun',     revelationType: 'Medinan', ayahCount: 18),
    SurahSummary(number: 65,  nameArabic: 'الطلاق',         nameLatin: 'At-Talaq',        revelationType: 'Medinan', ayahCount: 12),
    SurahSummary(number: 66,  nameArabic: 'التحريم',        nameLatin: 'At-Tahrim',       revelationType: 'Medinan', ayahCount: 12),
    SurahSummary(number: 67,  nameArabic: 'الملك',          nameLatin: 'Al-Mulk',         revelationType: 'Meccan',  ayahCount: 30),
    SurahSummary(number: 68,  nameArabic: 'القلم',          nameLatin: 'Al-Qalam',        revelationType: 'Meccan',  ayahCount: 52),
    SurahSummary(number: 69,  nameArabic: 'الحاقة',         nameLatin: 'Al-Haqqah',       revelationType: 'Meccan',  ayahCount: 52),
    SurahSummary(number: 70,  nameArabic: 'المعارج',        nameLatin: 'Al-Ma\'arij',     revelationType: 'Meccan',  ayahCount: 44),
    SurahSummary(number: 71,  nameArabic: 'نوح',            nameLatin: 'Nuh',             revelationType: 'Meccan',  ayahCount: 28),
    SurahSummary(number: 72,  nameArabic: 'الجن',           nameLatin: 'Al-Jinn',         revelationType: 'Meccan',  ayahCount: 28),
    SurahSummary(number: 73,  nameArabic: 'المزمل',         nameLatin: 'Al-Muzzammil',    revelationType: 'Meccan',  ayahCount: 20),
    SurahSummary(number: 74,  nameArabic: 'المدثر',         nameLatin: 'Al-Muddaththir',  revelationType: 'Meccan',  ayahCount: 56),
    SurahSummary(number: 75,  nameArabic: 'القيامة',        nameLatin: 'Al-Qiyamah',      revelationType: 'Meccan',  ayahCount: 40),
    SurahSummary(number: 76,  nameArabic: 'الإنسان',        nameLatin: 'Al-Insan',        revelationType: 'Medinan', ayahCount: 31),
    SurahSummary(number: 77,  nameArabic: 'المرسلات',       nameLatin: 'Al-Mursalat',     revelationType: 'Meccan',  ayahCount: 50),
    SurahSummary(number: 78,  nameArabic: 'النبأ',          nameLatin: 'An-Naba',         revelationType: 'Meccan',  ayahCount: 40),
    SurahSummary(number: 79,  nameArabic: 'النازعات',       nameLatin: 'An-Nazi\'at',     revelationType: 'Meccan',  ayahCount: 46),
    SurahSummary(number: 80,  nameArabic: 'عبس',            nameLatin: '\'Abasa',         revelationType: 'Meccan',  ayahCount: 42),
    SurahSummary(number: 81,  nameArabic: 'التكوير',        nameLatin: 'At-Takwir',       revelationType: 'Meccan',  ayahCount: 29),
    SurahSummary(number: 82,  nameArabic: 'الانفطار',       nameLatin: 'Al-Infitar',      revelationType: 'Meccan',  ayahCount: 19),
    SurahSummary(number: 83,  nameArabic: 'المطففين',       nameLatin: 'Al-Mutaffifin',   revelationType: 'Meccan',  ayahCount: 36),
    SurahSummary(number: 84,  nameArabic: 'الانشقاق',       nameLatin: 'Al-Inshiqaq',     revelationType: 'Meccan',  ayahCount: 25),
    SurahSummary(number: 85,  nameArabic: 'البروج',         nameLatin: 'Al-Buruj',        revelationType: 'Meccan',  ayahCount: 22),
    SurahSummary(number: 86,  nameArabic: 'الطارق',         nameLatin: 'At-Tariq',        revelationType: 'Meccan',  ayahCount: 17),
    SurahSummary(number: 87,  nameArabic: 'الأعلى',         nameLatin: 'Al-A\'la',        revelationType: 'Meccan',  ayahCount: 19),
    SurahSummary(number: 88,  nameArabic: 'الغاشية',        nameLatin: 'Al-Ghashiyah',    revelationType: 'Meccan',  ayahCount: 26),
    SurahSummary(number: 89,  nameArabic: 'الفجر',          nameLatin: 'Al-Fajr',         revelationType: 'Meccan',  ayahCount: 30),
    SurahSummary(number: 90,  nameArabic: 'البلد',          nameLatin: 'Al-Balad',        revelationType: 'Meccan',  ayahCount: 20),
    SurahSummary(number: 91,  nameArabic: 'الشمس',          nameLatin: 'Ash-Shams',       revelationType: 'Meccan',  ayahCount: 15),
    SurahSummary(number: 92,  nameArabic: 'الليل',          nameLatin: 'Al-Layl',         revelationType: 'Meccan',  ayahCount: 21),
    SurahSummary(number: 93,  nameArabic: 'الضحى',          nameLatin: 'Ad-Duhaa',        revelationType: 'Meccan',  ayahCount: 11),
    SurahSummary(number: 94,  nameArabic: 'الشرح',          nameLatin: 'Ash-Sharh',       revelationType: 'Meccan',  ayahCount: 8),
    SurahSummary(number: 95,  nameArabic: 'التين',          nameLatin: 'At-Tin',          revelationType: 'Meccan',  ayahCount: 8),
    SurahSummary(number: 96,  nameArabic: 'العلق',          nameLatin: 'Al-\'Alaq',       revelationType: 'Meccan',  ayahCount: 19),
    SurahSummary(number: 97,  nameArabic: 'القدر',          nameLatin: 'Al-Qadr',         revelationType: 'Meccan',  ayahCount: 5),
    SurahSummary(number: 98,  nameArabic: 'البينة',         nameLatin: 'Al-Bayyinah',     revelationType: 'Medinan', ayahCount: 8),
    SurahSummary(number: 99,  nameArabic: 'الزلزلة',        nameLatin: 'Az-Zalzalah',     revelationType: 'Medinan', ayahCount: 8),
    SurahSummary(number: 100, nameArabic: 'العاديات',       nameLatin: 'Al-\'Adiyat',     revelationType: 'Meccan',  ayahCount: 11),
    SurahSummary(number: 101, nameArabic: 'القارعة',        nameLatin: 'Al-Qari\'ah',     revelationType: 'Meccan',  ayahCount: 11),
    SurahSummary(number: 102, nameArabic: 'التكاثر',        nameLatin: 'At-Takathur',     revelationType: 'Meccan',  ayahCount: 8),
    SurahSummary(number: 103, nameArabic: 'العصر',          nameLatin: 'Al-\'Asr',        revelationType: 'Meccan',  ayahCount: 3),
    SurahSummary(number: 104, nameArabic: 'الهمزة',         nameLatin: 'Al-Humazah',      revelationType: 'Meccan',  ayahCount: 9),
    SurahSummary(number: 105, nameArabic: 'الفيل',          nameLatin: 'Al-Fil',          revelationType: 'Meccan',  ayahCount: 5),
    SurahSummary(number: 106, nameArabic: 'قريش',           nameLatin: 'Quraysh',         revelationType: 'Meccan',  ayahCount: 4),
    SurahSummary(number: 107, nameArabic: 'الماعون',        nameLatin: 'Al-Ma\'un',       revelationType: 'Meccan',  ayahCount: 7),
    SurahSummary(number: 108, nameArabic: 'الكوثر',         nameLatin: 'Al-Kawthar',      revelationType: 'Meccan',  ayahCount: 3),
    SurahSummary(number: 109, nameArabic: 'الكافرون',       nameLatin: 'Al-Kafirun',      revelationType: 'Meccan',  ayahCount: 6),
    SurahSummary(number: 110, nameArabic: 'النصر',          nameLatin: 'An-Nasr',         revelationType: 'Medinan', ayahCount: 3),
    SurahSummary(number: 111, nameArabic: 'المسد',          nameLatin: 'Al-Masad',        revelationType: 'Meccan',  ayahCount: 5),
    SurahSummary(number: 112, nameArabic: 'الإخلاص',        nameLatin: 'Al-Ikhlas',       revelationType: 'Meccan',  ayahCount: 4),
    SurahSummary(number: 113, nameArabic: 'الفلق',          nameLatin: 'Al-Falaq',        revelationType: 'Meccan',  ayahCount: 5),
    SurahSummary(number: 114, nameArabic: 'الناس',          nameLatin: 'An-Nas',          revelationType: 'Meccan',  ayahCount: 6),
  ];
}
