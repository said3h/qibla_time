// lib/core/services/audio_service.dart
//
// Reproduce adhans desde Flutter assets para el preview
// en AdhanSelectorScreen.

import 'package:audioplayers/audioplayers.dart';

class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();

  final AudioPlayer _player = AudioPlayer();

  /// Estado del reproductor
  bool get isPlaying => _player.state == PlayerState.playing;

  /// Duración total del audio actual
  Future<Duration?> get duration async {
    try {
      return await _player.getDuration();
    } catch (e) {
      return null;
    }
  }

  /// Posición actual de reproducción
  Future<Duration?> get position async {
    try {
      return await _player.getCurrentPosition();
    } catch (e) {
      return null;
    }
  }

  Stream<PlayerState> get onPlayerStateChanged => _player.onPlayerStateChanged;
  Stream<void>        get onPlayerComplete      => _player.onPlayerComplete;
  Stream<Duration>    get onPositionChanged     => _player.onPositionChanged;
  Stream<Duration?>   get onDurationChanged     => _player.onDurationChanged;

  /// [fileName] viene de AdhanModel.file — ej: 'azan1.mp3'
  /// AssetSource busca en assets/audio/ (declarado en pubspec.yaml)
  Future<void> playAdhan(String fileName) async {
    await stop();
    await _player.play(AssetSource('audio/$fileName'));
    // resuelve a: assets/audio/azan1.mp3
  }

  /// Alias para compatibilidad con código existente
  Future<void> play(String fileName, {bool isLocalFile = false}) async {
    await stop();
    if (isLocalFile) {
      await _player.play(DeviceFileSource(fileName));
    } else {
      await _player.play(AssetSource('audio/$fileName'));
    }
  }

  Future<void> stop()   async => _player.stop();
  Future<void> pause()  async => _player.pause();
  Future<void> resume() async => _player.resume();

  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume.clamp(0.0, 1.0));
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> dispose() async => _player.dispose();
}
