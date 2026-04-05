import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../../../core/localization/locale_controller.dart';
import '../../../core/services/audio_service.dart';
import '../models/quran_models.dart';
import 'quran_audio_download_service.dart';

enum QuranMiniPlaybackMode {
  none,
  ayah,
  surah,
}

class QuranMiniPlayerState {
  const QuranMiniPlayerState({
    required this.surahName,
    required this.surahNumber,
    required this.ayahNumber,
    required this.isPlaying,
    required this.playbackMode,
  });

  const QuranMiniPlayerState.idle()
      : surahName = '',
        surahNumber = 0,
        ayahNumber = 0,
        isPlaying = false,
        playbackMode = QuranMiniPlaybackMode.none;

  final String surahName;
  final int surahNumber;
  final int ayahNumber;
  final bool isPlaying;
  final QuranMiniPlaybackMode playbackMode;

  bool get isVisible =>
      surahName.trim().isNotEmpty && surahNumber > 0 && ayahNumber > 0;

  QuranMiniPlayerState copyWith({
    String? surahName,
    int? surahNumber,
    int? ayahNumber,
    bool? isPlaying,
    QuranMiniPlaybackMode? playbackMode,
  }) {
    return QuranMiniPlayerState(
      surahName: surahName ?? this.surahName,
      surahNumber: surahNumber ?? this.surahNumber,
      ayahNumber: ayahNumber ?? this.ayahNumber,
      isPlaying: isPlaying ?? this.isPlaying,
      playbackMode: playbackMode ?? this.playbackMode,
    );
  }
}

class _QueuedAyahAudio {
  const _QueuedAyahAudio({
    required this.ayah,
    required this.pathOrUrl,
    required this.isLocalFile,
  });

  final SurahAyah ayah;
  final String pathOrUrl;
  final bool isLocalFile;
}

final quranMiniPlayerControllerProvider = StateNotifierProvider<
    QuranMiniPlayerController, QuranMiniPlayerState>((ref) {
  return QuranMiniPlayerController(ref, AudioService.instance);
});

class QuranMiniPlayerController extends StateNotifier<QuranMiniPlayerState> {
  QuranMiniPlayerController(this._ref, this._audioService)
      : super(const QuranMiniPlayerState.idle()) {
    _playerStateSubscription = _audioService.onPlayerStateChanged.listen(
      _handlePlayerStateChanged,
    );
    _playerCompleteSubscription = _audioService.onPlayerComplete.listen((_) {
      unawaited(_handlePlaybackCompleted());
    });
  }

  final Ref _ref;
  final AudioService _audioService;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<void>? _playerCompleteSubscription;

  SurahSummary? _surahQueueSummary;
  List<SurahAyah> _surahQueue = const [];
  final Map<int, _QueuedAyahAudio> _resolvedSurahQueue = {};
  final Map<int, Future<void>> _prefetchingAyahTasks = {};
  int _surahQueueIndex = -1;

  bool get _isQuranSourceActive =>
      (_audioService.currentSourceKey ?? '').startsWith('quran:');

  Future<void> playAyah({
    required SurahSummary summary,
    required SurahAyah ayah,
  }) async {
    _clearQueueState();

    final sourceKey = 'quran:${summary.number}:${ayah.numberInSurah}';
    await _playResolvedAyahAudio(
      summary.number,
      ayah,
      sourceKey: sourceKey,
    );

    state = QuranMiniPlayerState(
      surahName: _surahLabel(summary),
      surahNumber: summary.number,
      ayahNumber: ayah.numberInSurah,
      isPlaying: true,
      playbackMode: QuranMiniPlaybackMode.ayah,
    );
  }

  Future<void> startSurahPlayback({
    required SurahSummary summary,
    required List<SurahAyah> queue,
    required bool preferDownloadedAudio,
  }) async {
    if (queue.isEmpty) return;

    _clearQueueState();
    _surahQueue = queue;
    _surahQueueSummary = summary;
    _surahQueueIndex = -1;

    try {
      await _primeSurahQueueForPlayback(
        summary.number,
        preferDownloadedAudio: preferDownloadedAudio,
      );
      await _playSurahQueueIndex(summary, 0);
    } catch (_) {
      _clearQueueState();
      rethrow;
    }
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

  Future<void> stop() async {
    _clearQueueState();
    await _audioService.stop();
    state = const QuranMiniPlayerState.idle();
  }

  void clear() {
    _clearQueueState();
    state = const QuranMiniPlayerState.idle();
  }

  Future<void> _handlePlaybackCompleted() async {
    if (state.playbackMode == QuranMiniPlaybackMode.surah &&
        _surahQueue.isNotEmpty &&
        _surahQueueIndex + 1 < _surahQueue.length) {
      try {
        final summary = _surahQueueSummary;
        if (summary == null) {
          clear();
          return;
        }
        await _playSurahQueueIndex(summary, _surahQueueIndex + 1);
        return;
      } catch (_) {
        clear();
        return;
      }
    }

    clear();
  }

  Future<_QueuedAyahAudio?> _resolveAyahAudioSource(
    int surahNumber,
    SurahAyah ayah,
  ) async {
    if (ayah.audioUrl.isEmpty) return null;

    final downloadService = _ref.read(quranAudioDownloadServiceProvider);
    final localPath = await downloadService.getDownloadedAyahPath(
      surahNumber,
      ayah,
    );
    if (localPath != null) {
      return _QueuedAyahAudio(
        ayah: ayah,
        pathOrUrl: localPath,
        isLocalFile: true,
      );
    }

    return _QueuedAyahAudio(
      ayah: ayah,
      pathOrUrl: ayah.audioUrl,
      isLocalFile: false,
    );
  }

  Future<_QueuedAyahAudio?> _primeSurahQueueAudio(
    int surahNumber,
    int index,
  ) async {
    if (index < 0 || index >= _surahQueue.length) return null;

    final ayah = _surahQueue[index];
    final cached = _resolvedSurahQueue[ayah.numberInSurah];
    if (cached != null) return cached;

    final resolved = await _resolveAyahAudioSource(surahNumber, ayah);
    if (resolved != null) {
      _resolvedSurahQueue[ayah.numberInSurah] = resolved;
    }
    return resolved;
  }

  Future<void> _primeSurahQueueForPlayback(
    int surahNumber, {
    required bool preferDownloadedAudio,
  }) async {
    if (_surahQueue.isEmpty) return;

    if (preferDownloadedAudio) {
      final paths = await _ref
          .read(quranAudioDownloadServiceProvider)
          .getKnownDownloadedAyahPaths(surahNumber, _surahQueue);
      for (final ayah in _surahQueue) {
        final localPath = paths[ayah.numberInSurah];
        if (localPath == null) continue;
        _resolvedSurahQueue[ayah.numberInSurah] = _QueuedAyahAudio(
          ayah: ayah,
          pathOrUrl: localPath,
          isLocalFile: true,
        );
      }
      unawaited(_prefetchUpcomingAyahsForPlayback(surahNumber, 0));
      return;
    }

    await _primeSurahQueueAudio(surahNumber, 0);
    unawaited(_prefetchUpcomingAyahsForPlayback(surahNumber, 0));
  }

  Future<void> _prefetchUpcomingAyahsForPlayback(
    int surahNumber,
    int currentIndex,
  ) async {
    const prefetchCount = 5;
    final lastIndexToPrefetch = currentIndex + prefetchCount;
    for (var index = currentIndex + 1;
        index < _surahQueue.length && index <= lastIndexToPrefetch;
        index++) {
      await _prefetchAyahForGaplessPlayback(surahNumber, index);
    }
  }

  Future<void> _prefetchAyahForGaplessPlayback(
    int surahNumber,
    int index,
  ) async {
    if (index < 0 || index >= _surahQueue.length) return;

    final ayah = _surahQueue[index];
    final cached = _resolvedSurahQueue[ayah.numberInSurah];
    if (cached != null && cached.isLocalFile) {
      return;
    }

    final existingTask = _prefetchingAyahTasks[ayah.numberInSurah];
    if (existingTask != null) {
      await existingTask;
      return;
    }

    final task = () async {
      try {
        final resolved = await _primeSurahQueueAudio(surahNumber, index);
        if (resolved == null || resolved.isLocalFile) {
          return;
        }

        final uri = Uri.tryParse(resolved.pathOrUrl);
        if (uri == null || !uri.hasScheme) {
          return;
        }

        final prefetchedFile = await _prefetchedAyahFile(surahNumber, ayah);
        if (!await prefetchedFile.exists()) {
          final response = await http.get(uri);
          if (response.statusCode < 200 ||
              response.statusCode >= 300 ||
              response.bodyBytes.isEmpty) {
            return;
          }

          await prefetchedFile.parent.create(recursive: true);
          await prefetchedFile.writeAsBytes(response.bodyBytes, flush: true);
        }

        _resolvedSurahQueue[ayah.numberInSurah] = _QueuedAyahAudio(
          ayah: ayah,
          pathOrUrl: prefetchedFile.path,
          isLocalFile: true,
        );
      } catch (_) {
        // Fall back to the original URL if prefetch fails.
      }
    }();

    _prefetchingAyahTasks[ayah.numberInSurah] = task;
    try {
      await task;
    } finally {
      _prefetchingAyahTasks.remove(ayah.numberInSurah);
    }
  }

  Future<File> _prefetchedAyahFile(int surahNumber, SurahAyah ayah) async {
    final tempDirectory = await getTemporaryDirectory();
    final prefetchDirectory = Directory(
      '${tempDirectory.path}${Platform.pathSeparator}quran_audio_prefetch${Platform.pathSeparator}surah_${surahNumber.toString().padLeft(3, '0')}',
    );
    return File(
      '${prefetchDirectory.path}${Platform.pathSeparator}ayah_${ayah.numberInSurah.toString().padLeft(3, '0')}.mp3',
    );
  }

  Future<void> _playQueuedAyahAudio(
    _QueuedAyahAudio queuedAyah, {
    required String sourceKey,
    bool stopFirst = true,
  }) async {
    if (queuedAyah.isLocalFile) {
      await _audioService.play(
        queuedAyah.pathOrUrl,
        isLocalFile: true,
        sourceKey: sourceKey,
        stopFirst: stopFirst,
      );
      return;
    }

    await _audioService.playUrl(
      queuedAyah.pathOrUrl,
      sourceKey: sourceKey,
      stopFirst: stopFirst,
    );
  }

  Future<void> _playResolvedAyahAudio(
    int surahNumber,
    SurahAyah ayah, {
    required String sourceKey,
    bool stopFirst = true,
  }) async {
    final resolved = await _resolveAyahAudioSource(surahNumber, ayah);
    if (resolved == null) {
      throw StateError('Audio not available for ayah ${ayah.numberInSurah}');
    }
    await _playQueuedAyahAudio(
      resolved,
      sourceKey: sourceKey,
      stopFirst: stopFirst,
    );
  }

  Future<void> _playSurahQueueIndex(SurahSummary summary, int index) async {
    if (index < 0 || index >= _surahQueue.length) return;

    final ayah = _surahQueue[index];
    final sourceKey = 'quran:surah:${summary.number}:${ayah.numberInSurah}';

    _surahQueueIndex = index;

    final resolved = await _primeSurahQueueAudio(summary.number, index);
    if (resolved == null) {
      throw StateError('Audio not available for ayah ${ayah.numberInSurah}');
    }

    await _playQueuedAyahAudio(
      resolved,
      sourceKey: sourceKey,
      stopFirst: false,
    );
    state = QuranMiniPlayerState(
      surahName: _surahLabel(summary),
      surahNumber: summary.number,
      ayahNumber: ayah.numberInSurah,
      isPlaying: true,
      playbackMode: QuranMiniPlaybackMode.surah,
    );
    unawaited(_prefetchUpcomingAyahsForPlayback(summary.number, index));
  }

  void _clearQueueState() {
    _surahQueueSummary = null;
    _surahQueue = const [];
    _surahQueueIndex = -1;
    _resolvedSurahQueue.clear();
    _prefetchingAyahTasks.clear();
  }

  String _surahLabel(SurahSummary summary) {
    return _ref.read(currentLanguageCodeProvider) == 'ar'
        ? summary.nameArabic
        : summary.nameLatin;
  }

  void _handlePlayerStateChanged(PlayerState playerState) {
    if (!_isQuranSourceActive) {
      if (state.isVisible) {
        clear();
      }
      return;
    }

    if (playerState == PlayerState.playing) {
      state = state.copyWith(isPlaying: true);
      return;
    }

    if (playerState == PlayerState.paused) {
      state = state.copyWith(isPlaying: false);
    }
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    _playerCompleteSubscription?.cancel();
    super.dispose();
  }
}
