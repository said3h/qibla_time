// lib/core/services/audio_service.dart
//
// Reproduce adhans desde assets y audio remoto cuando una feature
// necesita una previsualizacion o un play/pause simple.

import 'package:audioplayers/audioplayers.dart';

class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();
  static final AudioContext _defaultAudioContext = AudioContext(
    iOS: AudioContextIOS(
      category: AVAudioSessionCategory.playback,
    ),
  );

  AudioPlayer? _player;
  String? _currentSourceKey;
  bool _isConfigured = false;

  AudioPlayer _ensurePlayer() => _player ??= AudioPlayer();

  Future<AudioPlayer> _configuredPlayer() async {
    final player = _ensurePlayer();
    if (_isConfigured) return player;

    await player.setPlayerMode(PlayerMode.mediaPlayer);
    await player.setReleaseMode(ReleaseMode.stop);
    await player.setAudioContext(_defaultAudioContext);
    _isConfigured = true;
    return player;
  }

  String? get currentSourceKey => _currentSourceKey;

  bool get isPlaying => _player?.state == PlayerState.playing;

  Future<Duration?> get duration async {
    try {
      return await _player?.getDuration();
    } catch (_) {
      return null;
    }
  }

  Future<Duration?> get position async {
    try {
      return await _player?.getCurrentPosition();
    } catch (_) {
      return null;
    }
  }

  Stream<PlayerState> get onPlayerStateChanged =>
      _ensurePlayer().onPlayerStateChanged;
  Stream<void> get onPlayerComplete => _ensurePlayer().onPlayerComplete;
  Stream<Duration> get onPositionChanged => _ensurePlayer().onPositionChanged;
  Stream<Duration?> get onDurationChanged =>
      _ensurePlayer().onDurationChanged;

  Future<void> playAdhan(String fileName) async {
    await stop();
    _currentSourceKey = 'asset:$fileName';
    final player = await _configuredPlayer();
    await player.play(
      AssetSource('audio/$fileName'),
      mode: PlayerMode.mediaPlayer,
      ctx: _defaultAudioContext,
    );
  }

  Future<void> play(
    String fileName, {
    bool isLocalFile = false,
    String? sourceKey,
    bool stopFirst = true,
  }) async {
    final player = await _configuredPlayer();
    _currentSourceKey =
        sourceKey ?? (isLocalFile ? 'file:$fileName' : 'asset:$fileName');
    if (stopFirst) {
      await stop();
      _currentSourceKey =
          sourceKey ?? (isLocalFile ? 'file:$fileName' : 'asset:$fileName');
      if (isLocalFile) {
        await player.play(
          DeviceFileSource(fileName),
          mode: PlayerMode.mediaPlayer,
          ctx: _defaultAudioContext,
        );
      } else {
        await player.play(
          AssetSource('audio/$fileName'),
          mode: PlayerMode.mediaPlayer,
          ctx: _defaultAudioContext,
        );
      }
      return;
    }
    if (isLocalFile) {
      await player.play(
        DeviceFileSource(fileName),
        mode: PlayerMode.mediaPlayer,
        ctx: _defaultAudioContext,
      );
    } else {
      await player.play(
        AssetSource('audio/$fileName'),
        mode: PlayerMode.mediaPlayer,
        ctx: _defaultAudioContext,
      );
    }
  }

  Future<void> playUrl(
    String url, {
    String? sourceKey,
    bool stopFirst = true,
  }) async {
    final player = await _configuredPlayer();
    _currentSourceKey = sourceKey ?? 'url:$url';
    if (stopFirst) {
      await stop();
      _currentSourceKey = sourceKey ?? 'url:$url';
      await player.play(
        UrlSource(url),
        mode: PlayerMode.mediaPlayer,
        ctx: _defaultAudioContext,
      );
      return;
    }
    await player.setSourceUrl(url);
    await player.resume();
  }

  Future<void> stop() async {
    final player = _player;
    _currentSourceKey = null;
    if (player != null) {
      await player.stop();
    }
  }

  Future<void> pause() async {
    final player = _player;
    if (player != null) {
      await player.pause();
    }
  }

  Future<void> resume() async {
    final player = _player;
    if (player != null) {
      await player.resume();
    }
  }

  Future<void> setVolume(double volume) async {
    await _ensurePlayer().setVolume(volume.clamp(0.0, 1.0));
  }

  Future<void> seek(Duration position) async {
    await _ensurePlayer().seek(position);
  }

  Future<void> dispose() async {
    final player = _player;
    _player = null;
    _currentSourceKey = null;
    _isConfigured = false;
    await player?.dispose();
  }
}
