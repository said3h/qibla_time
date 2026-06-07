import 'package:flutter_test/flutter_test.dart';
import 'package:qibla_time/features/quran/models/quran_models.dart';
import 'package:qibla_time/features/quran/screens/quran_screen.dart';
import 'package:qibla_time/features/quran/services/quran_mini_player_service.dart';

void main() {
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
}
