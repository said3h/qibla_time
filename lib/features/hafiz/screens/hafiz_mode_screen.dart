import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/l10n.dart';
import '../../quran/models/quran_models.dart';
import '../../quran/services/quran_service.dart';
import '../models/hafiz_models.dart';
import '../services/hafiz_service.dart';

bool _isArabicOnly(BuildContext context) =>
    Localizations.localeOf(context).languageCode == 'ar';

class HafizModeScreen extends ConsumerWidget {
  const HafizModeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = QiblaThemes.current;
    final l10n = context.l10n;
    final isArabicOnly = _isArabicOnly(context);
    final surahs = ref.watch(quranSurahsProvider);
    final progress = ref.watch(hafizProgressProvider);

    return Scaffold(
      backgroundColor: tokens.bgPage,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Text('Hafiz', style: GoogleFonts.amiri(fontSize: 26, fontWeight: FontWeight.bold, color: tokens.primary)),
            Text(
              l10n.hafizSubtitle,
              textAlign: isArabicOnly ? TextAlign.right : TextAlign.left,
              style: GoogleFonts.dmSans(fontSize: 11, color: tokens.textSecondary),
            ),
            const SizedBox(height: 16),
            _buildSummary(tokens, progress, isArabicOnly),
            if (progress.isEmpty) ...[
              const SizedBox(height: 12),
              _buildEmptyState(tokens, isArabicOnly),
            ],
            const SizedBox(height: 16),
            ...surahs.take(20).map((surah) {
              final plan = progress.where((item) => item.surahNumber == surah.number).cast<HafizProgress?>().firstOrNull;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: tokens.bgSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: tokens.border),
                ),
                child: ListTile(
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => HafizPracticeScreen(summary: surah, initialPlan: plan),
                    ));
                  },
                  title: Text(surah.nameLatin, style: GoogleFonts.dmSans(color: tokens.textPrimary, fontWeight: FontWeight.w500)),
                  subtitle: Text(
                    plan == null
                        ? l10n.hafizSurahNoPlan(surah.ayahCount)
                        : l10n.hafizSurahProgress(
                            plan.startAyah,
                            plan.endAyah,
                            (plan.completion * 100).round(),
                          ),
                    textAlign: isArabicOnly ? TextAlign.right : TextAlign.left,
                    style: GoogleFonts.dmSans(fontSize: 11, color: tokens.textSecondary),
                  ),
                  trailing: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      surah.nameArabic,
                      textAlign: TextAlign.right,
                      style: GoogleFonts.amiri(fontSize: 20, color: tokens.primaryLight),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary(
    QiblaTokens tokens,
    List<HafizProgress> progress,
    bool isArabicOnly,
  ) {
    final l10n = appLocalizationsForCurrentLocale();
    final completed = progress.where((item) => item.completedRepetitions >= item.targetRepetitions).length;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.primaryBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tokens.primaryBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: _stat(
              tokens,
              '${progress.length}',
              l10n.hafizActivePlans,
              isArabicOnly,
            ),
          ),
          Expanded(
            child: _stat(
              tokens,
              '$completed',
              l10n.hafizReviewedSurahs,
              isArabicOnly,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(QiblaTokens tokens, bool isArabicOnly) {
    final l10n = appLocalizationsForCurrentLocale();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.bgSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tokens.border),
      ),
      child: Column(
        crossAxisAlignment:
            isArabicOnly ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            l10n.hafizEmptyTitle,
            textAlign: isArabicOnly ? TextAlign.right : TextAlign.left,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: tokens.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.hafizEmptyBody,
            textAlign: isArabicOnly ? TextAlign.right : TextAlign.left,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              height: 1.6,
              color: tokens.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: tokens.primaryBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: tokens.primaryBorder),
            ),
            child: Text(
              l10n.hafizEmptyHint,
              textAlign: isArabicOnly ? TextAlign.right : TextAlign.left,
              style: GoogleFonts.dmSans(
                fontSize: 11,
                color: tokens.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(
    QiblaTokens tokens,
    String value,
    String label,
    bool isArabicOnly,
  ) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.dmSans(fontSize: 22, fontWeight: FontWeight.w600, color: tokens.primaryLight)),
        Text(
          label,
          textAlign: isArabicOnly ? TextAlign.right : TextAlign.left,
          style: GoogleFonts.dmSans(fontSize: 10, color: tokens.textSecondary),
        ),
      ],
    );
  }
}

class HafizPracticeScreen extends ConsumerStatefulWidget {
  const HafizPracticeScreen({super.key, required this.summary, this.initialPlan});

  final SurahSummary summary;
  final HafizProgress? initialPlan;

  @override
  ConsumerState<HafizPracticeScreen> createState() => _HafizPracticeScreenState();
}

class _HafizPracticeScreenState extends ConsumerState<HafizPracticeScreen> {
  final AudioPlayer _player = AudioPlayer();
  int _startAyah = 1;
  int _endAyah = 1;
  int _targetRepetitions = 5;
  int _currentIndex = 0;
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    _startAyah = widget.initialPlan?.startAyah ?? 1;
    _endAyah = widget.initialPlan?.endAyah ?? (widget.summary.ayahCount >= 5 ? 5 : widget.summary.ayahCount);
    _targetRepetitions = widget.initialPlan?.targetRepetitions ?? 5;
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;
    final l10n = context.l10n;
    final isArabicOnly = _isArabicOnly(context);
    final detailAsync = ref.watch(surahDetailProvider(widget.summary));

    return Scaffold(
      backgroundColor: tokens.bgPage,
      appBar: AppBar(title: Text(widget.summary.nameLatin)),
      body: detailAsync.when(
        data: (detail) {
          final segment = detail.ayahs.where((ayah) => ayah.numberInSurah >= _startAyah && ayah.numberInSurah <= _endAyah).toList();
          final currentAyah = segment.isEmpty ? null : segment[_currentIndex.clamp(0, segment.length - 1)];
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildControls(tokens, detail),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: tokens.bgSurface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: tokens.border),
                ),
                child: Column(
                  crossAxisAlignment: isArabicOnly
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.hafizSelectedSegment,
                      textAlign:
                          isArabicOnly ? TextAlign.right : TextAlign.left,
                      style: GoogleFonts.dmSans(fontSize: 10, letterSpacing: 1.2, color: tokens.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.hafizAyahRange(_startAyah, _endAyah),
                      textAlign:
                          isArabicOnly ? TextAlign.right : TextAlign.left,
                      style: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.w600, color: tokens.primaryLight),
                    ),
                    const SizedBox(height: 12),
                    if (currentAyah != null) ...[
                      Directionality(
                        textDirection: TextDirection.rtl,
                        child: Text(
                          currentAyah.arabic,
                          textAlign: TextAlign.right,
                          style: GoogleFonts.amiri(fontSize: 24, height: 1.8, color: tokens.textPrimary),
                        ),
                      ),
                      if (currentAyah.transliteration.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          currentAyah.transliteration,
                          textAlign:
                              isArabicOnly ? TextAlign.right : TextAlign.left,
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            height: 1.7,
                            fontStyle: FontStyle.italic,
                            color: tokens.textSecondary,
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Text(
                        currentAyah.translation,
                        textAlign:
                            isArabicOnly ? TextAlign.right : TextAlign.left,
                        style: GoogleFonts.dmSans(fontSize: 13, height: 1.7, color: tokens.textPrimary),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: currentAyah == null ? null : () => _playAyah(currentAyah),
                            icon: Icon(_playing ? Icons.pause_circle : Icons.play_circle),
                            label: Text(_playing ? l10n.commonPause : l10n.commonPlay),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: segment.length <= 1 ? null : () {
                              setState(() {
                                _currentIndex = (_currentIndex + 1) % segment.length;
                              });
                            },
                            icon: const Icon(Icons.repeat),
                            label: Text(l10n.commonNext),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton(
                      onPressed: () async {
                        final plan = HafizProgress(
                          surahNumber: widget.summary.number,
                          surahName: widget.summary.nameLatin,
                          startAyah: _startAyah,
                          endAyah: _endAyah,
                          targetRepetitions: _targetRepetitions,
                          completedRepetitions: widget.initialPlan?.completedRepetitions ?? 0,
                          nextReviewAt: DateTime.now().add(const Duration(days: 1)),
                          updatedAt: DateTime.now(),
                        );
                        await ref.read(hafizServiceProvider).savePlan(plan);
                        ref.read(hafizProgressProvider.notifier).state = ref.read(hafizServiceProvider).getProgress();
                        if (!mounted) return;
                        ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(content: Text(l10n.hafizPlanSaved)));
                      },
                      child: Text(l10n.hafizSavePlan),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: widget.initialPlan == null
                          ? null
                          : () async {
                              await ref.read(hafizServiceProvider).incrementRepetition(widget.summary.number);
                              ref.read(hafizProgressProvider.notifier).state = ref.read(hafizServiceProvider).getProgress();
                              if (!mounted) return;
                              ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(content: Text(l10n.hafizRepetitionLogged)));
                            },
                      child: Text(l10n.hafizLogRepetition),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => Center(child: CircularProgressIndicator(color: tokens.primary)),
        error: (_, __) => Center(child: Text(l10n.hafizLoadError, style: GoogleFonts.dmSans(color: tokens.textSecondary))),
      ),
    );
  }

  Widget _buildControls(QiblaTokens tokens, SurahDetail detail) {
    final l10n = context.l10n;
    final isArabicOnly = _isArabicOnly(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.border),
      ),
      child: Column(
        crossAxisAlignment:
            isArabicOnly ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            l10n.hafizConfigureSession,
            textAlign: isArabicOnly ? TextAlign.right : TextAlign.left,
            style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600, color: tokens.textPrimary),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.hafizStartAyah(_startAyah),
            textAlign: isArabicOnly ? TextAlign.right : TextAlign.left,
            style: GoogleFonts.dmSans(color: tokens.textSecondary),
          ),
          Slider(
            value: _startAyah.toDouble(),
            min: 1,
            max: detail.summary.ayahCount.toDouble(),
            divisions: detail.summary.ayahCount - 1,
            onChanged: (value) {
              setState(() {
                _startAyah = value.round();
                if (_endAyah < _startAyah) _endAyah = _startAyah;
              });
            },
          ),
          Text(
            l10n.hafizEndAyah(_endAyah),
            textAlign: isArabicOnly ? TextAlign.right : TextAlign.left,
            style: GoogleFonts.dmSans(color: tokens.textSecondary),
          ),
          Slider(
            value: _endAyah.toDouble(),
            min: _startAyah.toDouble(),
            max: detail.summary.ayahCount.toDouble(),
            divisions: detail.summary.ayahCount - _startAyah,
            onChanged: (value) {
              setState(() {
                _endAyah = value.round();
              });
            },
          ),
          Text(
            l10n.hafizTargetRepetitions(_targetRepetitions),
            textAlign: isArabicOnly ? TextAlign.right : TextAlign.left,
            style: GoogleFonts.dmSans(color: tokens.textSecondary),
          ),
          Slider(
            value: _targetRepetitions.toDouble(),
            min: 3,
            max: 20,
            divisions: 17,
            onChanged: (value) => setState(() => _targetRepetitions = value.round()),
          ),
        ],
      ),
    );
  }

  Future<void> _playAyah(SurahAyah ayah) async {
    if (_playing) {
      await _player.pause();
      setState(() => _playing = false);
      return;
    }
    await _player.play(UrlSource(ayah.audioUrl));
    setState(() => _playing = true);
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playing = false);
    });
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
