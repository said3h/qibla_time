import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/audio_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../hafiz/screens/hafiz_mode_screen.dart';
import '../models/quran_models.dart';
import '../services/quran_reading_service.dart';
import '../services/quran_service.dart';

class QuranScreen extends ConsumerWidget {
  const QuranScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = QiblaThemes.current;
    final surahs = ref.watch(quranSurahsProvider);
    final lastReading = ref.watch(lastReadingProvider).valueOrNull;
    final bookmarks = ref.watch(quranBookmarksProvider).valueOrNull ?? const [];

    return Scaffold(
      backgroundColor: tokens.bgPage,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Coran',
                        style: GoogleFonts.amiri(
                          fontSize: 26,
                          color: tokens.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '114 suras · lectura continua',
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
                          color: tokens.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const HafizModeScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.auto_stories),
                  label: const Text('Hafiz'),
                ),
              ],
            ),
            if (lastReading == null && bookmarks.isEmpty) ...[
              const SizedBox(height: 16),
              const _ReadingHintCard(),
            ],
            if (lastReading != null) ...[
              const SizedBox(height: 16),
              _ContinueReadingCard(
                point: lastReading,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => QuranDetailScreen(
                        summary: _summaryFor(surahs, lastReading.surahNumber),
                        initialAyah: lastReading.ayahNumber,
                      ),
                    ),
                  );
                },
              ),
            ],
            if (bookmarks.isNotEmpty) ...[
              const SizedBox(height: 12),
              _BookmarksCard(
                bookmarks: bookmarks,
                onTap: (bookmark) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => QuranDetailScreen(
                        summary: _summaryFor(surahs, bookmark.surahNumber),
                        initialAyah: bookmark.ayahNumber,
                      ),
                    ),
                  );
                },
              ),
            ],
            const SizedBox(height: 16),
            ...surahs.map(
              (surah) => _SurahTile(
                surah: surah,
                lastReading: lastReading,
                bookmarks: bookmarks,
              ),
            ),
          ],
        ),
      ),
    );
  }

  SurahSummary _summaryFor(List<SurahSummary> surahs, int surahNumber) {
    return surahs.firstWhere(
      (surah) => surah.number == surahNumber,
      orElse: () => surahs.first,
    );
  }
}

class _ReadingHintCard extends StatelessWidget {
  const _ReadingHintCard();

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.bgSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tokens.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.menu_book_outlined, color: tokens.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LECTURA CONTINUA',
                  style: GoogleFonts.dmSans(
                    fontSize: 9,
                    letterSpacing: 1.4,
                    color: tokens.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Abre cualquier sura y guardaremos tu ultima aya para que puedas retomar mas tarde.',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    height: 1.5,
                    color: tokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Tambien podras guardar marcadores tocando el icono de bookmark dentro de la lectura.',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    height: 1.5,
                    color: tokens.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContinueReadingCard extends StatelessWidget {
  const _ContinueReadingCard({
    required this.point,
    required this.onTap,
  });

  final QuranReadingPoint point;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: tokens.primaryBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: tokens.primaryBorder),
        ),
        child: Row(
          children: [
            Icon(Icons.bookmark_added_outlined, color: tokens.primary, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CONTINUAR LECTURA',
                    style: GoogleFonts.dmSans(
                      fontSize: 9,
                      letterSpacing: 1.4,
                      color: tokens.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    point.shortLabel,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: tokens.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 16, color: tokens.primary),
          ],
        ),
      ),
    );
  }
}

class _BookmarksCard extends StatelessWidget {
  const _BookmarksCard({
    required this.bookmarks,
    required this.onTap,
  });

  final List<QuranReadingPoint> bookmarks;
  final ValueChanged<QuranReadingPoint> onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.bgSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MARCADORES',
            style: GoogleFonts.dmSans(
              fontSize: 9,
              letterSpacing: 1.4,
              color: tokens.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          ...bookmarks.take(3).map(
            (bookmark) => InkWell(
              onTap: () => onTap(bookmark),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.bookmark_outline, size: 16, color: tokens.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        bookmark.shortLabel,
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: tokens.textPrimary,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: tokens.textMuted,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SurahTile extends StatelessWidget {
  const _SurahTile({
    required this.surah,
    required this.lastReading,
    required this.bookmarks,
  });

  final SurahSummary surah;
  final QuranReadingPoint? lastReading;
  final List<QuranReadingPoint> bookmarks;

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;
    final isLastRead = lastReading?.surahNumber == surah.number;
    final bookmarkCount = bookmarks
        .where((bookmark) => bookmark.surahNumber == surah.number)
        .length;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: tokens.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isLastRead ? tokens.activeBorder : tokens.border),
      ),
      child: ListTile(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => QuranDetailScreen(summary: surah),
            ),
          );
        },
        leading: CircleAvatar(
          backgroundColor: tokens.primaryBg,
          foregroundColor: tokens.primary,
          child: Text(
            '${surah.number}',
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        title: Text(
          surah.nameLatin,
          style: GoogleFonts.dmSans(
            color: tokens.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${surah.revelationType} · ${surah.ayahCount} ayas',
              style: GoogleFonts.dmSans(
                fontSize: 11,
                color: tokens.textSecondary,
              ),
            ),
            if (isLastRead)
              Text(
                'Ultima lectura: aya ${lastReading!.ayahNumber}',
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  color: tokens.primary,
                ),
              ),
            if (bookmarkCount > 0)
              Text(
                '$bookmarkCount marcador${bookmarkCount == 1 ? '' : 'es'} guardado${bookmarkCount == 1 ? '' : 's'}',
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  color: tokens.textMuted,
                ),
              ),
          ],
        ),
        trailing: Text(
          surah.nameArabic,
          style: GoogleFonts.amiri(
            fontSize: 20,
            color: tokens.primaryLight,
          ),
        ),
      ),
    );
  }
}

class QuranDetailScreen extends ConsumerStatefulWidget {
  const QuranDetailScreen({
    super.key,
    required this.summary,
    this.initialAyah = 1,
  });

  final SurahSummary summary;
  final int initialAyah;

  @override
  ConsumerState<QuranDetailScreen> createState() => _QuranDetailScreenState();
}

class _QuranDetailScreenState extends ConsumerState<QuranDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  final AudioService _audioService = AudioService.instance;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<void>? _playerCompleteSubscription;
  bool _initialJumpDone = false;
  bool _initialReadingSaved = false;
  int? _activeAyahNumber;
  bool _isAudioPlaying = false;

  @override
  void initState() {
    super.initState();
    _playerStateSubscription = _audioService.onPlayerStateChanged.listen((
      state,
    ) {
      if (!mounted) return;
      if (state == PlayerState.playing) {
        setState(() => _isAudioPlaying = true);
      } else if (state == PlayerState.paused) {
        setState(() => _isAudioPlaying = false);
      }
    });
    _playerCompleteSubscription = _audioService.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() {
        _isAudioPlaying = false;
        _activeAyahNumber = null;
      });
    });
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    _playerCompleteSubscription?.cancel();
    _audioService.stop();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _saveReading(int ayahNumber, {bool showFeedback = true}) async {
    await ref
        .read(quranReadingServiceProvider)
        .saveLastReading(widget.summary, ayahNumber);
    ref.invalidate(lastReadingProvider);
    if (!mounted || !showFeedback) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Punto de lectura guardado en aya $ayahNumber'),
      ),
    );
  }

  Future<void> _toggleBookmark(int ayahNumber) async {
    final saved = await ref
        .read(quranReadingServiceProvider)
        .toggleBookmark(widget.summary, ayahNumber);
    ref.invalidate(quranBookmarksProvider);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved
              ? 'Marcador guardado en aya $ayahNumber'
              : 'Marcador eliminado de aya $ayahNumber',
        ),
      ),
    );
  }

  bool _canPlayAyahAudio(SurahAyah ayah, SurahLoadSource source) {
    if (ayah.audioUrl.isEmpty) return false;
    return source != SurahLoadSource.placeholder;
  }

  String _audioStatusLabel(SurahAyah ayah, SurahLoadSource source) {
    if (!_canPlayAyahAudio(ayah, source)) {
      return 'Audio no disponible para esta aya.';
    }
    switch (source) {
      case SurahLoadSource.online:
        return 'Audio disponible para esta aya.';
      case SurahLoadSource.offline:
        return 'Audio disponible si tienes conexion.';
      case SurahLoadSource.placeholder:
        return 'Audio no disponible para esta aya.';
    }
  }

  Future<void> _toggleAyahAudio(
    SurahAyah ayah,
    SurahLoadSource source,
  ) async {
    if (!_canPlayAyahAudio(ayah, source)) return;

    final sourceKey = 'quran:${widget.summary.number}:${ayah.numberInSurah}';
    try {
      if (_activeAyahNumber == ayah.numberInSurah &&
          _audioService.currentSourceKey == sourceKey) {
        if (_isAudioPlaying) {
          await _audioService.pause();
          if (!mounted) return;
          setState(() => _isAudioPlaying = false);
        } else {
          await _audioService.resume();
          if (!mounted) return;
          setState(() => _isAudioPlaying = true);
        }
        return;
      }

      await _audioService.playUrl(
        ayah.audioUrl,
        sourceKey: sourceKey,
      );
      if (!mounted) return;
      setState(() {
        _activeAyahNumber = ayah.numberInSurah;
        _isAudioPlaying = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _activeAyahNumber = null;
        _isAudioPlaying = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo reproducir el audio ahora mismo. Comprueba tu conexion e intentalo de nuevo.',
          ),
        ),
      );
    }
  }

  Future<void> _toggleActiveAudioFromIndicator() async {
    if (_activeAyahNumber == null) return;

    if (_isAudioPlaying) {
      await _audioService.pause();
      if (!mounted) return;
      setState(() => _isAudioPlaying = false);
      return;
    }

    await _audioService.resume();
    if (!mounted) return;
    setState(() => _isAudioPlaying = true);
  }

  Future<void> _stopActiveAudio() async {
    await _audioService.stop();
    if (!mounted) return;
    setState(() {
      _isAudioPlaying = false;
      _activeAyahNumber = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;
    final detailAsync = ref.watch(surahLoadResultProvider(widget.summary));
    final bookmarks = ref.watch(quranBookmarksProvider).valueOrNull ?? const [];
    final lastReading = ref.watch(lastReadingProvider).valueOrNull;

    return Scaffold(
      backgroundColor: tokens.bgPage,
      appBar: AppBar(
        title: Text(widget.summary.nameLatin),
      ),
      body: detailAsync.when(
        data: (result) {
          final detail = result.detail;
          if (!_initialReadingSaved) {
            _initialReadingSaved = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _saveReading(widget.initialAyah, showFeedback: false);
            });
          }
          if (!_initialJumpDone && widget.initialAyah > 1) {
            _initialJumpDone = true;
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              final targetOffset = (widget.initialAyah - 1) * 220.0;
              final maxExtent = _scrollController.position.maxScrollExtent;
              await _scrollController.animateTo(
                targetOffset.clamp(0.0, maxExtent),
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOut,
              );
            });
          }

          return ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: detail.ayahs.length + 1,
            itemBuilder: (_, index) {
              if (index == 0) {
                return Column(
                  children: [
                    _buildTopBanner(tokens, result.source, widget.initialAyah),
                    if (_activeAyahNumber != null)
                      _buildActiveAudioIndicator(tokens),
                  ],
                );
              }

              final ayah = detail.ayahs[index - 1];
              final canPlayAudio = _canPlayAyahAudio(ayah, result.source);
              final isLastRead = lastReading?.surahNumber == widget.summary.number &&
                  lastReading?.ayahNumber == ayah.numberInSurah;
              final isActiveAudio = _activeAyahNumber == ayah.numberInSurah;
              final isPlayingAudio = isActiveAudio && _isAudioPlaying;
              final isBookmarked = bookmarks.any(
                (bookmark) =>
                    bookmark.surahNumber == widget.summary.number &&
                    bookmark.ayahNumber == ayah.numberInSurah,
              );

              return InkWell(
                onTap: () => _saveReading(ayah.numberInSurah),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isLastRead ? tokens.activeBg : tokens.bgSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isLastRead ? tokens.activeBorder : tokens.border,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: tokens.primaryBg,
                            foregroundColor: tokens.primary,
                            child: Text(
                              '${ayah.numberInSurah}',
                              style: GoogleFonts.dmSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          if (isLastRead)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: tokens.primaryBg,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: tokens.primaryBorder),
                              ),
                              child: Text(
                                'Ultima lectura',
                                style: GoogleFonts.dmSans(
                                  fontSize: 10,
                                  color: tokens.primaryLight,
                                ),
                              ),
                            ),
                          const Spacer(),
                          IconButton(
                            tooltip: canPlayAudio
                                ? (isPlayingAudio
                                      ? 'Pausar audio'
                                      : isActiveAudio
                                          ? 'Reanudar audio'
                                          : 'Reproducir audio')
                                : 'Audio no disponible',
                            onPressed: canPlayAudio
                                ? () => _toggleAyahAudio(ayah, result.source)
                                : null,
                            icon: Icon(
                              !canPlayAudio
                                  ? Icons.volume_off_outlined
                                  : isPlayingAudio
                                      ? Icons.pause_circle_outline
                                      : Icons.play_circle_outline,
                              color: !canPlayAudio
                                  ? tokens.textMuted
                                  : tokens.primary,
                            ),
                          ),
                          IconButton(
                            tooltip: isBookmarked
                                ? 'Quitar marcador'
                                : 'Guardar marcador',
                            onPressed: () => _toggleBookmark(ayah.numberInSurah),
                            icon: Icon(
                              isBookmarked
                                  ? Icons.bookmark
                                  : Icons.bookmark_border,
                              color: isBookmarked
                                  ? tokens.primary
                                  : tokens.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        ayah.arabic,
                        textAlign: TextAlign.right,
                        style: GoogleFonts.amiri(
                          fontSize: 22,
                          height: 1.8,
                          color: tokens.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        ayah.translation,
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          height: 1.7,
                          color: tokens.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${_audioStatusLabel(ayah, result.source)} Toca esta aya para guardar aqui tu punto de lectura.',
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
                          color: tokens.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => Center(child: CircularProgressIndicator(color: tokens.primary)),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'No se pudo cargar esta sura ahora mismo. Comprueba la conexion e intentalo de nuevo.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(color: tokens.textSecondary),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBanner(
    QiblaTokens tokens,
    SurahLoadSource source,
    int initialAyah,
  ) {
    final hasResume = initialAyah > 1;
    final textParts = <String>[];
    if (hasResume) {
      textParts.add('Retomando desde la aya $initialAyah.');
    }
    final sourceMessage = switch (source) {
      SurahLoadSource.online =>
        'Contenido cargado online. Puedes reproducir el audio de cada aya mientras tengas conexion.',
      SurahLoadSource.offline =>
        'Texto cargado offline. El audio de cada aya puede requerir conexion.',
      SurahLoadSource.placeholder =>
        'Contenido parcial sin conexion. El audio no esta disponible.',
    };
    textParts.add(sourceMessage);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tokens.primaryBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tokens.primaryBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: tokens.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              textParts.join(' '),
              style: GoogleFonts.dmSans(
                fontSize: 11,
                height: 1.5,
                color: tokens.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveAudioIndicator(QiblaTokens tokens) {
    final ayahNumber = _activeAyahNumber;
    if (ayahNumber == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tokens.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tokens.border),
      ),
      child: Row(
        children: [
          Icon(
            _isAudioPlaying
                ? Icons.volume_up_outlined
                : Icons.pause_circle_outline,
            color: tokens.primary,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isAudioPlaying
                      ? 'Reproduciendo aya $ayahNumber'
                      : 'Aya $ayahNumber en pausa',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: tokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Puedes pausar, reanudar o detener esta recitacion.',
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    color: tokens.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: _isAudioPlaying ? 'Pausar audio' : 'Reanudar audio',
            onPressed: _toggleActiveAudioFromIndicator,
            icon: Icon(
              _isAudioPlaying
                  ? Icons.pause_circle_outline
                  : Icons.play_circle_outline,
              color: tokens.primary,
            ),
          ),
          IconButton(
            tooltip: 'Detener audio',
            onPressed: _stopActiveAudio,
            icon: Icon(
              Icons.stop_circle_outlined,
              color: tokens.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
