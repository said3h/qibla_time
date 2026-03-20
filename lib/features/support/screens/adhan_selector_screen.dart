import 'dart:async';

import 'package:flutter/material.dart';
import '../../../core/models/adhan_model.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/theme/app_theme.dart';

/// Pantalla para seleccionar y previsualizar el Adhan
class AdhanSelectorScreen extends StatefulWidget {
  const AdhanSelectorScreen({super.key});

  @override
  State<AdhanSelectorScreen> createState() => _AdhanSelectorScreenState();
}

class _AdhanSelectorScreenState extends State<AdhanSelectorScreen> {
  final AudioService _audioService = AudioService.instance;
  final SettingsService _settingsService = SettingsService.instance;

  String _selectedAdhan = 'azan1.mp3';
  String? _playingAdhan;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;

  @override
  void initState() {
    super.initState();
    _loadSelectedAdhan();
    _setupAudioListeners();
  }

  void _setupAudioListeners() {
    _positionSubscription = _audioService.onPositionChanged.listen((pos) {
      if (mounted) {
        setState(() {
          _position = pos;
        });
      }
    });

    _durationSubscription = _audioService.onDurationChanged.listen((dur) {
      if (mounted && dur != null) {
        setState(() {
          _duration = dur;
        });
      }
    });
  }

  Future<void> _loadSelectedAdhan() async {
    final saved = await _settingsService.getAdhan();
    if (mounted) {
      setState(() {
        _selectedAdhan = saved;
      });
    }
  }

  Future<void> _selectAdhan(String file) async {
    await _settingsService.saveAdhan(file);
    if (!mounted) return;
    setState(() {
      _selectedAdhan = file;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Adhan guardado: ${_getAdhanName(file)}'),
        backgroundColor: AppTheme.primaryGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _getAdhanName(String file) {
    final adhan = AdhanModel.availableAdhans.firstWhere(
      (a) => a.file == file,
      orElse: () => AdhanModel(name: file, file: file),
    );
    return adhan.name;
  }

  Future<void> _playPreview(String file) async {
    try {
      if (_playingAdhan == file) {
        // Ya está reproduciendo este, lo pausamos/reproducimos
        final isPlaying = _audioService.isPlaying;
        if (isPlaying) {
          await _audioService.pause();
          setState(() {
            _playingAdhan = null;
          });
        } else {
          await _audioService.resume();
          setState(() {
            _playingAdhan = file;
          });
        }
      } else {
        // Reproducir nuevo
        setState(() {
          _playingAdhan = file;
          _position = Duration.zero;
          _duration = Duration.zero;
        });
        await _audioService.play(file);

        // Obtener duración
        final dur = await _audioService.duration;
        if (mounted && dur != null) {
          setState(() {
            _duration = dur;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al reproducir: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _playingAdhan = null;
        });
      }
    }
  }

  void _seekTo(double value) {
    final position = _duration.inMilliseconds * value;
    _audioService.seek(Duration(milliseconds: position.toInt()));
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _audioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: const Text(
          'Seleccionar Adhan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.backgroundWhite,
        elevation: 0,
        iconTheme: IconThemeData(color: AppTheme.primaryGreen),
      ),
      body: Column(
        children: [
          // Header informativo
          _buildHeader(),

          // Barra de reproducción fija
          if (_playingAdhan != null) _buildPlayerBar(),

          // Lista de adhans
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: AdhanModel.availableAdhans.length,
              itemBuilder: (context, index) {
                final adhan = AdhanModel.availableAdhans[index];
                final isSelected = adhan.file == _selectedAdhan;
                final isPlaying = _playingAdhan == adhan.file;

                return _buildAdhanTile(adhan, isSelected, isPlaying);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryGreen,
            AppTheme.primaryGreen.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.music_note,
            color: Colors.white,
            size: 48,
          ),
          const SizedBox(height: 12),
          const Text(
            'Elige tu Adhan favorito',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Puedes previsualizar cada uno antes de seleccionar',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerBar() {
    final currentAdhan = AdhanModel.availableAdhans.firstWhere(
      (a) => a.file == _playingAdhan,
      orElse: () => AdhanModel(name: 'Adhan', file: _playingAdhan!),
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryGreen,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Nombre del Adhan reproduciendo
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.accentGold,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.equalizer,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentAdhan.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                    Text(
                      'Reproduciendo...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Slider de progreso
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppTheme.primaryGreen,
              inactiveTrackColor: AppTheme.primaryGreen.withOpacity(0.3),
              thumbColor: AppTheme.accentGold,
              overlayColor: AppTheme.accentGold.withOpacity(0.2),
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(
              value: _duration.inMilliseconds > 0
                  ? _position.inMilliseconds / _duration.inMilliseconds
                  : 0,
              onChanged: _seekTo,
            ),
          ),
          // Tiempo y controles
          Row(
            children: [
              Text(
                _formatDuration(_position),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              // Botón Play/Pause
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryGreen.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(
                    _audioService.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: () => _playPreview(_playingAdhan!),
                ),
              ),
              const Spacer(),
              Text(
                _formatDuration(_duration),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdhanTile(AdhanModel adhan, bool isSelected, bool isPlaying) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected
            ? AppTheme.primaryGreen.withOpacity(0.1)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? AppTheme.primaryGreen
              : Colors.grey.shade200,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 8,
        ),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: isPlaying
                ? AppTheme.accentGold
                : isSelected
                    ? AppTheme.primaryGreen
                    : Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isPlaying ? Icons.equalizer : Icons.music_note,
            color: isPlaying
                ? Colors.white
                : isSelected
                    ? Colors.white
                    : Colors.grey.shade600,
          ),
        ),
        title: Text(
          adhan.name,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? AppTheme.primaryGreen : AppTheme.textDark,
          ),
        ),
        subtitle: adhan.description != null
            ? Text(
                adhan.description!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Botón de preview
            IconButton(
              icon: Icon(
                isPlaying && _audioService.isPlaying
                    ? Icons.pause_circle
                    : Icons.play_circle,
                size: 32,
              ),
              color: isPlaying
                  ? AppTheme.accentGold
                  : AppTheme.primaryGreen,
              onPressed: () => _playPreview(adhan.file),
            ),
            // Checkbox de selección
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppTheme.primaryGreen,
              ),
          ],
        ),
        onTap: () => _selectAdhan(adhan.file),
      ),
    );
  }
}
