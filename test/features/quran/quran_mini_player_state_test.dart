import 'package:flutter_test/flutter_test.dart';
import 'package:qibla_time/features/quran/models/quran_models.dart';
import 'package:qibla_time/features/quran/screens/quran_screen.dart';
import 'package:qibla_time/features/quran/services/quran_mini_player_service.dart';
import 'package:qibla_time/features/quran/widgets/quran_ayah_card.dart';
import 'package:qibla_time/features/quran/widgets/quran_continuous_view.dart';

void main() {
  const testSurahs = [
    SurahSummary(
      number: 1,
      nameArabic: 'الفاتحة',
      nameLatin: 'Al-Fatiha',
      revelationType: 'Meccan',
      ayahCount: 7,
    ),
    SurahSummary(
      number: 2,
      nameArabic: 'البقرة',
      nameLatin: 'Al-Baqarah',
      revelationType: 'Medinan',
      ayahCount: 286,
    ),
    SurahSummary(
      number: 18,
      nameArabic: 'الكهف',
      nameLatin: 'Al-Kahf',
      revelationType: 'Meccan',
      ayahCount: 110,
    ),
    SurahSummary(
      number: 36,
      nameArabic: 'يس',
      nameLatin: 'Ya-Sin',
      revelationType: 'Meccan',
      ayahCount: 83,
    ),
    SurahSummary(
      number: 112,
      nameArabic: 'الإخلاص',
      nameLatin: 'Al-Ikhlas',
      revelationType: 'Meccan',
      ayahCount: 4,
    ),
  ];

  group('QuranMiniPlayerState', () {
    test('idle state is not visible', () {
      const state = QuranMiniPlayerState.idle();

      expect(state.isVisible, isFalse);
      expect(state.playbackMode, QuranMiniPlaybackMode.none);
    });

    test('visible state requires surah and ayah context', () {
      const state = QuranMiniPlayerState(
        surahName: 'Al-Fatiha',
        surahNumber: 1,
        ayahNumber: 1,
        isPlaying: true,
        playbackMode: QuranMiniPlaybackMode.ayah,
      );

      expect(state.isVisible, isTrue);
    });

    test('copyWith preserves playback mode when changing play state', () {
      const state = QuranMiniPlayerState(
        surahName: 'Al-Baqarah',
        surahNumber: 2,
        ayahNumber: 255,
        isPlaying: true,
        playbackMode: QuranMiniPlaybackMode.surah,
      );

      final paused = state.copyWith(isPlaying: false);

      expect(paused.isPlaying, isFalse);
      expect(paused.playbackMode, QuranMiniPlaybackMode.surah);
      expect(paused.ayahNumber, 255);
    });
  });

  group('quranAudioQueueFromAyah', () {
    test('starts at the selected ayah and keeps later playable ayahs', () {
      final queue = quranAudioQueueFromAyah(
        ayahs: const [
          SurahAyah(
            number: 1,
            numberInSurah: 1,
            arabic: '',
            transliteration: '',
            translation: '',
            audioUrl: 'https://audio.test/001001.mp3',
          ),
          SurahAyah(
            number: 2,
            numberInSurah: 2,
            arabic: '',
            transliteration: '',
            translation: '',
            audioUrl: 'https://audio.test/001002.mp3',
          ),
          SurahAyah(
            number: 3,
            numberInSurah: 3,
            arabic: '',
            transliteration: '',
            translation: '',
            audioUrl: '',
          ),
          SurahAyah(
            number: 4,
            numberInSurah: 4,
            arabic: '',
            transliteration: '',
            translation: '',
            audioUrl: 'https://audio.test/001004.mp3',
          ),
        ],
        startAyahNumber: 2,
      );

      expect(
        queue.map((ayah) => ayah.numberInSurah),
        [2, 4],
      );
    });
  });

  group('shouldReplaceQuranDetailForPlaybackSurah', () {
    test('syncs the detail screen when continuous playback changes surah', () {
      const previous = QuranMiniPlayerState(
        surahName: 'Al-Fatiha',
        surahNumber: 1,
        ayahNumber: 7,
        isPlaying: true,
        playbackMode: QuranMiniPlaybackMode.surah,
      );
      const next = QuranMiniPlayerState(
        surahName: 'Al-Baqarah',
        surahNumber: 2,
        ayahNumber: 1,
        isPlaying: true,
        playbackMode: QuranMiniPlaybackMode.surah,
      );

      expect(
        shouldReplaceQuranDetailForPlaybackSurah(
          currentScreenSurahNumber: 1,
          previous: previous,
          next: next,
        ),
        isTrue,
      );
    });

    test('does not sync for ayah-only playback changes', () {
      const previous = QuranMiniPlayerState(
        surahName: 'Al-Fatiha',
        surahNumber: 1,
        ayahNumber: 7,
        isPlaying: true,
        playbackMode: QuranMiniPlaybackMode.ayah,
      );
      const next = QuranMiniPlayerState(
        surahName: 'Al-Baqarah',
        surahNumber: 2,
        ayahNumber: 1,
        isPlaying: true,
        playbackMode: QuranMiniPlaybackMode.ayah,
      );

      expect(
        shouldReplaceQuranDetailForPlaybackSurah(
          currentScreenSurahNumber: 1,
          previous: previous,
          next: next,
        ),
        isFalse,
      );
    });

    test('does not sync when only the ayah changes within the same surah', () {
      const previous = QuranMiniPlayerState(
        surahName: 'Al-Fatiha',
        surahNumber: 1,
        ayahNumber: 8,
        isPlaying: true,
        playbackMode: QuranMiniPlaybackMode.surah,
      );
      const next = QuranMiniPlayerState(
        surahName: 'Al-Fatiha',
        surahNumber: 1,
        ayahNumber: 9,
        isPlaying: true,
        playbackMode: QuranMiniPlaybackMode.surah,
      );

      expect(
        shouldReplaceQuranDetailForPlaybackSurah(
          currentScreenSurahNumber: 1,
          previous: previous,
          next: next,
        ),
        isFalse,
      );
    });
  });

  group('shouldScheduleQuranContinuousAutoScroll', () {
    test('does not auto-scroll when only active ayah changes', () {
      expect(
        shouldScheduleQuranContinuousAutoScroll(
          oldEnableAutoScroll: true,
          newEnableAutoScroll: true,
          oldSurahNumber: 2,
          newSurahNumber: 2,
          oldAyahCount: 286,
          newAyahCount: 286,
        ),
        isFalse,
      );
    });

    test('allows auto-scroll when the surah changes', () {
      expect(
        shouldScheduleQuranContinuousAutoScroll(
          oldEnableAutoScroll: true,
          newEnableAutoScroll: true,
          oldSurahNumber: 1,
          newSurahNumber: 2,
          oldAyahCount: 7,
          newAyahCount: 286,
        ),
        isTrue,
      );
    });
  });

  group('parseQuranReferenceQuery', () {
    test('accepts common surah ayah reference formats', () {
      final references = ['2:255', '2: 255', '2/255', '2 255'];

      for (final value in references) {
        final reference = parseQuranReferenceQuery(value, testSurahs);
        expect(reference?.surahNumber, 2);
        expect(reference?.ayahNumber, 255);
      }
    });

    test('validates that the ayah exists in the surah', () {
      expect(parseQuranReferenceQuery('1:1', testSurahs)?.ayahNumber, 1);
      expect(parseQuranReferenceQuery('18:10', testSurahs)?.ayahNumber, 10);
      expect(parseQuranReferenceQuery('36:1', testSurahs)?.ayahNumber, 1);
      expect(parseQuranReferenceQuery('112:4', testSurahs)?.ayahNumber, 4);
      expect(parseQuranReferenceQuery('112:5', testSurahs), isNull);
      expect(parseQuranReferenceQuery('115:1', testSurahs), isNull);
    });
  });

  group('partialQuranReferenceSurahNumber', () {
    test('recognizes an unfinished surah reference', () {
      expect(partialQuranReferenceSurahNumber('2:'), 2);
      expect(partialQuranReferenceSurahNumber('2: '), 2);
      expect(partialQuranReferenceSurahNumber('112/'), 112);
    });

    test('rejects invalid unfinished references', () {
      expect(partialQuranReferenceSurahNumber('115:'), isNull);
      expect(partialQuranReferenceSurahNumber('baqarah:'), isNull);
      expect(partialQuranReferenceSurahNumber('2:255'), isNull);
    });
  });

  group('shouldApplySavedQuranViewMode', () {
    test('does not apply the saved mode after a manual toggle', () {
      expect(
        shouldApplySavedQuranViewMode(
          userChangedViewMode: true,
          mounted: true,
        ),
        isFalse,
      );
    });

    test('applies the saved mode only while mounted and untouched', () {
      expect(
        shouldApplySavedQuranViewMode(
          userChangedViewMode: false,
          mounted: true,
        ),
        isTrue,
      );
      expect(
        shouldApplySavedQuranViewMode(
          userChangedViewMode: false,
          mounted: false,
        ),
        isFalse,
      );
    });
  });

  group('nextQuranViewModeGeneration', () {
    test('increments the render generation on every view mode toggle', () {
      expect(nextQuranViewModeGeneration(0), 1);
      expect(nextQuranViewModeGeneration(4), 5);
    });
  });

  group('QuranWord', () {
    test('returns requested translation with English fallback', () {
      const word = QuranWord(
        surahNumber: 1,
        ayahNumber: 1,
        position: 1,
        arabic: 'بِسْمِ',
        transliteration: 'Bismi',
        translations: {
          'en': 'In the name',
          'es': 'En el nombre',
        },
      );

      expect(word.translationFor('es'), 'En el nombre');
      expect(word.translationFor('fr'), 'In the name');
      expect(word.translationLanguageFor('es'), 'es');
      expect(word.translationLanguageFor('fr'), 'en');
    });

    test('reports English as the active language when Spanish is unavailable',
        () {
      const word = QuranWord(
        surahNumber: 1,
        ayahNumber: 1,
        position: 1,
        arabic: 'بِسْمِ',
        transliteration: 'Bismi',
        translations: {
          'en': 'In the name',
        },
      );

      expect(word.translationFor('es'), 'In the name');
      expect(word.translationLanguageFor('es'), 'en');
    });
  });

  group('supportsQuranWordByWordOnline', () {
    test('is hidden by default behind the production feature flag', () {
      expect(supportsQuranWordByWordOnline(1), isFalse);
      expect(supportsQuranWordByWordOnline(2), isFalse);
      expect(supportsQuranWordByWordOnline(18), isFalse);
      expect(supportsQuranWordByWordOnline(114), isFalse);
      expect(supportsQuranWordByWordOnline(0), isFalse);
      expect(supportsQuranWordByWordOnline(115), isFalse);
    });
  });

  group('shouldRenderQuranWordByWordArabic', () {
    test('does not replace vocalized ayah text with unvocalized word data', () {
      const words = [
        QuranWord(
          surahNumber: 112,
          ayahNumber: 1,
          position: 1,
          arabic: 'قل',
          transliteration: '',
          translations: {},
        ),
      ];

      expect(
        shouldRenderQuranWordByWordArabic(
          ayahArabic: 'قُلْ',
          words: words,
        ),
        isFalse,
      );
    });

    test('allows word-by-word rendering when word data keeps harakat', () {
      const words = [
        QuranWord(
          surahNumber: 1,
          ayahNumber: 1,
          position: 1,
          arabic: 'بِسْمِ',
          transliteration: '',
          translations: {},
        ),
      ];

      expect(
        shouldRenderQuranWordByWordArabic(
          ayahArabic: 'بِسْمِ اللَّهِ',
          words: words,
        ),
        isTrue,
      );
    });
  });

  group('shouldUseQuranWordByWordArabic', () {
    const words = [
      QuranWord(
        surahNumber: 1,
        ayahNumber: 1,
        position: 1,
        arabic: 'بِسْمِ',
        transliteration: '',
        translations: {},
      ),
    ];

    test('requires the production toggle to be on', () {
      expect(
        shouldUseQuranWordByWordArabic(
          showWordByWord: false,
          hasWordTapHandler: true,
          ayahArabic: 'بِسْمِ اللَّهِ',
          words: words,
        ),
        isFalse,
      );
    });

    test('requires a tap handler before rendering tappable words', () {
      expect(
        shouldUseQuranWordByWordArabic(
          showWordByWord: true,
          hasWordTapHandler: false,
          ayahArabic: 'بِسْمِ اللَّهِ',
          words: words,
        ),
        isFalse,
      );
    });
  });
}
