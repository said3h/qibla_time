import 'package:flutter_test/flutter_test.dart';
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
}
