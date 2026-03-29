import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Servicio para reproducir audio de hadices
/// NOTA: Los hadices no tienen audio oficial disponible como el CorÃ¡n.
/// Este servicio es un placeholder para futura implementaciÃ³n.
class HadithAudioService {
  final AudioPlayer _player = AudioPlayer();

  bool _isPlaying = false;
  String? _currentHadithId;

  /// Verifica si el audio estÃ¡ disponible para un hadiz
  /// Actualmente retorna false ya que no hay audio oficial de hadices
  bool isAudioAvailable(String hadithId) {
    // TODO: Implementar cuando haya audio disponible
    // Posibles fuentes futuras:
    // - API de hadith con audio
    // - Audio generado por TTS (text-to-speech)
    return false;
  }

  /// Reproduce el audio de un hadiz
  /// Actualmente no implementado
  Future<void> playHadith(String hadithId, {String? arabicText}) async {
    if (!isAudioAvailable(hadithId)) {
      throw UnsupportedError(
        'El audio de hadices no estÃ¡ disponible actualmente. '
        'Los hadices no tienen recitaciÃ³n oficial como el CorÃ¡n.',
      );
    }

    try {
      await _player.stop();

      // TODO: Cuando haya audio disponible, implementar:
      // - Reproducir desde URL
      // - O reproducir desde archivo local
      // await _player.play(UrlSource(audioUrl));

      _currentHadithId = hadithId;
      _isPlaying = true;
    } catch (e) {
      rethrow;
    }
  }

  /// Pausa la reproducciÃ³n
  Future<void> pause() async {
    await _player.pause();
    _isPlaying = false;
  }

  /// Reanuda la reproducciÃ³n
  Future<void> resume() async {
    await _player.resume();
    _isPlaying = true;
  }

  /// Detiene la reproducciÃ³n
  Future<void> stop() async {
    await _player.stop();
    _isPlaying = false;
    _currentHadithId = null;
  }

  /// Alterna entre play/pause
  Future<void> togglePlayPause(String hadithId, {String? arabicText}) async {
    if (_isPlaying && _currentHadithId == hadithId) {
      await pause();
    } else {
      await playHadith(hadithId, arabicText: arabicText);
    }
  }

  /// Estado actual
  bool get isPlaying => _isPlaying;
  String? get currentHadithId => _currentHadithId;

  /// Stream del estado del jugador
  Stream<PlayerState> get playerStateStream => _player.onPlayerStateChanged;

  /// Dispose
  void dispose() {
    _player.dispose();
  }
}

// â”€â”€ Providers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

final hadithAudioServiceProvider = Provider<HadithAudioService>((ref) {
  return HadithAudioService();
});

final hadithAudioPlayingProvider = StateProvider<String?>((ref) => null);
