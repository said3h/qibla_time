import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/audio_service.dart';

class QuranMiniPlayerState {
  const QuranMiniPlayerState({
    required this.surahName,
    required this.surahNumber,
    required this.ayahNumber,
    required this.isPlaying,
  });

  const QuranMiniPlayerState.idle()
      : surahName = '',
        surahNumber = 0,
        ayahNumber = 0,
        isPlaying = false;

  final String surahName;
  final int surahNumber;
  final int ayahNumber;
  final bool isPlaying;

  bool get isVisible =>
      surahName.trim().isNotEmpty && surahNumber > 0 && ayahNumber > 0;

  QuranMiniPlayerState copyWith({
    String? surahName,
    int? surahNumber,
    int? ayahNumber,
    bool? isPlaying,
  }) {
    return QuranMiniPlayerState(
      surahName: surahName ?? this.surahName,
      surahNumber: surahNumber ?? this.surahNumber,
      ayahNumber: ayahNumber ?? this.ayahNumber,
      isPlaying: isPlaying ?? this.isPlaying,
    );
  }
}

final quranMiniPlayerControllerProvider = StateNotifierProvider<
    QuranMiniPlayerController, QuranMiniPlayerState>((ref) {
  return QuranMiniPlayerController(AudioService.instance);
});

class QuranMiniPlayerController extends StateNotifier<QuranMiniPlayerState> {
  QuranMiniPlayerController(this._audioService)
      : super(const QuranMiniPlayerState.idle()) {
    _playerStateSubscription = _audioService.onPlayerStateChanged.listen(
      _handlePlayerStateChanged,
    );
    _playerCompleteSubscription = _audioService.onPlayerComplete.listen((_) {
      if (_isQuranSourceActive) {
        clear();
      }
    });
  }

  final AudioService _audioService;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<void>? _playerCompleteSubscription;

  bool get _isQuranSourceActive =>
      (_audioService.currentSourceKey ?? '').startsWith('quran:');

  void setSession({
    required String surahName,
    required int surahNumber,
    required int ayahNumber,
    required bool isPlaying,
  }) {
    state = QuranMiniPlayerState(
      surahName: surahName,
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      isPlaying: isPlaying,
    );
  }

  void updatePlayback(bool isPlaying) {
    if (!state.isVisible) return;
    state = state.copyWith(isPlaying: isPlaying);
  }

  Future<void> togglePlayPause() async {
    if (!_isQuranSourceActive) {
      clear();
      return;
    }

    if (state.isPlaying) {
      await _audioService.pause();
      return;
    }

    await _audioService.resume();
  }

  void clear() {
    if (!state.isVisible) return;
    state = const QuranMiniPlayerState.idle();
  }

  void _handlePlayerStateChanged(PlayerState playerState) {
    if (!_isQuranSourceActive) {
      clear();
      return;
    }

    if (playerState == PlayerState.playing) {
      updatePlayback(true);
      return;
    }

    if (playerState == PlayerState.paused) {
      updatePlayback(false);
    }
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    _playerCompleteSubscription?.cancel();
    super.dispose();
  }
}
