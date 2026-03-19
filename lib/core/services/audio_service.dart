import 'package:audioplayers/audioplayers.dart';

/// Servicio para reproducir archivos de audio (Adhan, Quran, etc.)
class AudioService {
  // Singleton
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _player = AudioPlayer();

  /// Estado del reproductor
  bool get isPlaying => _player.state == PlayerState.playing;

  /// Reproducir un archivo de audio desde assets
  /// [fileName] - Nombre del archivo (ej: 'adhan_makkah.mp3')
  /// [isLocalFile] - Si es true, busca en el sistema de archivos local
  Future<void> play(String fileName, {bool isLocalFile = false}) async {
    try {
      await _player.stop();
      
      if (isLocalFile) {
        await _player.play(DeviceFileSource(fileName));
      } else {
        await _player.play(AssetSource('audio/$fileName'));
      }
    } catch (e) {
      print('Error al reproducir audio: $e');
      rethrow;
    }
  }

  /// Detener la reproducción actual
  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (e) {
      print('Error al detener audio: $e');
    }
  }

  /// Pausar la reproducción
  Future<void> pause() async {
    try {
      await _player.pause();
    } catch (e) {
      print('Error al pausar audio: $e');
    }
  }

  /// Reanudar la reproducción
  Future<void> resume() async {
    try {
      await _player.resume();
    } catch (e) {
      print('Error al reanudar audio: $e');
    }
  }

  /// Establecer volumen (0.0 a 1.0)
  Future<void> setVolume(double volume) async {
    try {
      await _player.setVolume(volume);
    } catch (e) {
      print('Error al establecer volumen: $e');
    }
  }

  /// Liberar recursos del reproductor
  Future<void> dispose() async {
    try {
      await _player.stop();
      await _player.dispose();
    } catch (e) {
      print('Error al liberar recursos: $e');
    }
  }

  /// Escuchar cambios en el estado del jugador
  Stream<PlayerState> get onPlayerStateChanged => _player.onPlayerStateChanged;

  /// Escuchar cuando se completa la reproducción
  Stream<void> get onPlayerComplete => _player.onPlayerComplete;
}
