import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/adhan_model.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/theme/app_theme.dart';

class AdhanSelectorScreen extends StatefulWidget {
  const AdhanSelectorScreen({super.key});

  @override
  State<AdhanSelectorScreen> createState() => _AdhanSelectorScreenState();
}

class _AdhanSelectorScreenState extends State<AdhanSelectorScreen> {
  final AudioService _audioService = AudioService.instance;
  final SettingsService _settingsService = SettingsService.instance;

  String _selectedAdhan = 'azan1.mp3';
  String? _activeAdhan;
  bool _isPreviewPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<void>? _playerCompleteSubscription;

  @override
  void initState() {
    super.initState();
    _loadSelectedAdhan();
    _setupAudioListeners();
  }

  void _setupAudioListeners() {
    _positionSubscription = _audioService.onPositionChanged.listen((pos) {
      if (!mounted) return;
      setState(() {
        _position = pos;
      });
    });

    _durationSubscription = _audioService.onDurationChanged.listen((dur) {
      if (!mounted || dur == null) return;
      setState(() {
        _duration = dur;
      });
    });

    _playerStateSubscription = _audioService.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() {
        _isPreviewPlaying = state == PlayerState.playing;
      });
    });

    _playerCompleteSubscription = _audioService.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() {
        _isPreviewPlaying = false;
        _activeAdhan = null;
        _position = Duration.zero;
      });
    });
  }

  Future<void> _loadSelectedAdhan() async {
    final saved = await _settingsService.getAdhan();
    if (!mounted) return;
    setState(() {
      _selectedAdhan = saved;
    });
  }

  Future<void> _selectAdhan(String file) async {
    await _settingsService.saveAdhan(file);
    if (!mounted) return;
    setState(() {
      _selectedAdhan = file;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Adhan seleccionado: ${_getAdhanName(file)}'),
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

  String _secondaryText(AdhanModel adhan, bool isActive, bool isPlaying) {
    if (isPlaying) return 'Reproduciendo...';
    if (isActive) return 'Vista previa en pausa';
    if (adhan.description != null && adhan.description!.trim().isNotEmpty) {
      return adhan.description!;
    }
    return 'Vista previa';
  }

  Future<void> _togglePreview(String file) async {
    try {
      if (_activeAdhan == file) {
        if (_isPreviewPlaying) {
          await _audioService.pause();
          if (!mounted) return;
          setState(() {
            _isPreviewPlaying = false;
          });
        } else {
          await _audioService.resume();
          if (!mounted) return;
          setState(() {
            _isPreviewPlaying = true;
          });
        }
        return;
      }

      setState(() {
        _activeAdhan = file;
        _isPreviewPlaying = true;
        _position = Duration.zero;
        _duration = Duration.zero;
      });
      await _audioService.play(file, sourceKey: 'adhan:$file');

      final dur = await _audioService.duration;
      if (!mounted || dur == null) return;
      setState(() {
        _duration = dur;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _activeAdhan = null;
        _isPreviewPlaying = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No hemos podido reproducir la vista previa.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _seekTo(double value) {
    if (_duration.inMilliseconds <= 0) return;
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
    _playerStateSubscription?.cancel();
    _playerCompleteSubscription?.cancel();
    _audioService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;

    return Scaffold(
      backgroundColor: tokens.bgPage,
      appBar: AppBar(
        title: Text(
          'Seleccionar adhan',
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
        ),
        backgroundColor: tokens.bgApp,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildHeader(tokens),
          if (_activeAdhan != null) _buildPlayerBar(tokens),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: AdhanModel.availableAdhans.length,
              itemBuilder: (context, index) {
                final adhan = AdhanModel.availableAdhans[index];
                final isSelected = adhan.file == _selectedAdhan;
                final isActive = _activeAdhan == adhan.file;

                return _buildAdhanTile(
                  tokens,
                  adhan,
                  isSelected,
                  isActive,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(QiblaTokens tokens) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tokens.bgSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tokens.primaryBorder),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: tokens.primaryBg,
              shape: BoxShape.circle,
              border: Border.all(color: tokens.primaryBorder),
            ),
            child: Icon(
              Icons.record_voice_over,
              color: tokens.primary,
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Elige el adhan para tus avisos',
            style: GoogleFonts.dmSans(
              color: tokens.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Puedes escuchar una vista previa breve antes de seleccionarlo.',
            style: GoogleFonts.dmSans(
              color: tokens.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerBar(QiblaTokens tokens) {
    final currentAdhan = AdhanModel.availableAdhans.firstWhere(
      (a) => a.file == _activeAdhan,
      orElse: () => AdhanModel(name: 'Adhan', file: _activeAdhan!),
    );

    final sliderValue = _duration.inMilliseconds > 0
        ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.activeBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.activeBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: tokens.primaryBg,
                  shape: BoxShape.circle,
                  border: Border.all(color: tokens.primaryBorder),
                ),
                child: Icon(
                  _isPreviewPlaying ? Icons.pause : Icons.record_voice_over,
                  color: tokens.primary,
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
                      style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: tokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _isPreviewPlaying ? 'Reproduciendo...' : 'Vista previa en pausa',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: tokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _isPreviewPlaying ? tokens.primary : tokens.textMuted,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: tokens.primary,
              inactiveTrackColor: tokens.primaryBg,
              thumbColor: tokens.primaryLight,
              overlayColor: tokens.primaryBg,
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(
              value: sliderValue,
              onChanged: _seekTo,
            ),
          ),
          Row(
            children: [
              Text(
                _formatDuration(_position),
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: tokens.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: _activeAdhan == null ? null : () => _togglePreview(_activeAdhan!),
                icon: Icon(_isPreviewPlaying ? Icons.pause : Icons.record_voice_over),
                label: Text(_isPreviewPlaying ? 'Pausar' : 'Reanudar'),
              ),
              const Spacer(),
              Text(
                _formatDuration(_duration),
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: tokens.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdhanTile(
    QiblaTokens tokens,
    AdhanModel adhan,
    bool isSelected,
    bool isActive,
  ) {
    final isPlaying = isActive && _isPreviewPlaying;
    final hasHighlight = isSelected || isActive;
    final subtitleText = _secondaryText(adhan, isActive, isPlaying);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isActive
            ? tokens.activeBg
            : isSelected
                ? tokens.primaryBg
                : tokens.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? tokens.activeBorder
              : isSelected
                  ? tokens.primaryBorder
                  : tokens.border,
          width: hasHighlight ? 2 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isActive ? tokens.primaryBg : tokens.bgSurface2,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? tokens.primaryBorder : tokens.border,
            ),
          ),
          child: Icon(
            isPlaying ? Icons.pause : Icons.record_voice_over,
            color: isActive ? tokens.primary : tokens.textSecondary,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                adhan.name,
                style: GoogleFonts.dmSans(
                  fontWeight: hasHighlight ? FontWeight.w700 : FontWeight.w600,
                  color: tokens.textPrimary,
                  fontSize: 15,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: tokens.primary,
                size: 18,
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              if (isActive) ...[
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isPlaying ? tokens.primary : tokens.textMuted,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  subtitleText,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: isActive ? tokens.textPrimary : tokens.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        trailing: IconButton(
          tooltip: isPlaying
              ? 'Pausar vista previa'
              : isActive
                  ? 'Reanudar vista previa'
                  : 'Escuchar vista previa',
          icon: Icon(
            isPlaying ? Icons.pause : Icons.record_voice_over,
            size: 28,
          ),
          color: isActive ? tokens.primary : tokens.textSecondary,
          onPressed: () => _togglePreview(adhan.file),
        ),
        onTap: () => _selectAdhan(adhan.file),
      ),
    );
  }
}
