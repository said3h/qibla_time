// lib/core/services/audio_service.dart
//
// Reproduce adhans desde assets y audio remoto cuando una feature
// necesita una previsualizacion o un play/pause simple.

import 'package:audioplayers/audioplayers.dart';

class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();

  AudioPlayer? _player;
  String? _currentSourceKey;

  AudioPlayer _ensurePlayer() => _player ??= AudioPlayer();

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
    await _ensurePlayer().play(AssetSource('audio/$fileName'));
  }

  Future<void> play(
    String fileName, {
    bool isLocalFile = false,
    String? sourceKey,
  }) async {
    await stop();
    if (isLocalFile) {
      _currentSourceKey = sourceKey ?? 'file:$fileName';
      await _ensurePlayer().play(DeviceFileSource(fileName));
    } else {
      _currentSourceKey = sourceKey ?? 'asset:$fileName';
      await _ensurePlayer().play(AssetSource('audio/$fileName'));
    }
  }

  Future<void> playUrl(String url, {String? sourceKey}) async {
    await stop();
    _currentSourceKey = sourceKey ?? 'url:$url';
    await _ensurePlayer().play(UrlSource(url));
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
    await player?.dispose();
  }
}
