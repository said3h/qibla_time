import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../models/quran_models.dart';
import 'tajweed_text.dart';

@visibleForTesting
bool shouldRenderQuranWordByWordArabic({
  required String ayahArabic,
  required List<QuranWord> words,
}) {
  if (words.isEmpty) return false;
  if (!_hasArabicHarakat(ayahArabic)) return true;

  final wordText = words.map((word) => word.arabic).join('');
  return _hasArabicHarakat(wordText);
}

bool shouldUseQuranWordByWordArabic({
  required bool showWordByWord,
  required bool hasWordTapHandler,
  required String ayahArabic,
  required List<QuranWord> words,
}) {
  return showWordByWord &&
      hasWordTapHandler &&
      shouldRenderQuranWordByWordArabic(
        ayahArabic: ayahArabic,
        words: words,
      );
}

bool _hasArabicHarakat(String text) {
  return RegExp(r'[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED]')
      .hasMatch(text);
}

class QuranAyahCard extends StatelessWidget {
  const QuranAyahCard({
    super.key,
    required this.tokens,
    required this.l10n,
    required this.ayah,
    this.surahNumber,
    required this.canPlayAudio,
    required this.isLastRead,
    required this.isActiveAudio,
    required this.isPlayingAudio,
    required this.isBookmarked,
    this.isSelected = false,
    this.isSelectionMode = false,
    this.showTajweed = false,
    this.showWordByWord = false,
    required this.audioStatusLabel,
    required this.onToggleAudio,
    required this.onToggleBookmark,
    this.showTafsirAction = false,
    this.isTafsirOpen = false,
    this.onToggleTafsir,
    this.words = const [],
    this.onWordTap,
    this.margin = const EdgeInsets.only(bottom: 10),
  });

  final QiblaTokens tokens;
  final AppLocalizations l10n;
  final SurahAyah ayah;
  final int? surahNumber;
  final bool canPlayAudio;
  final bool isLastRead;
  final bool isActiveAudio;
  final bool isPlayingAudio;
  final bool isBookmarked;
  final bool isSelected;
  final bool isSelectionMode;
  final bool showTajweed;
  final bool showWordByWord;
  final String audioStatusLabel;
  final VoidCallback onToggleAudio;
  final VoidCallback onToggleBookmark;
  final bool showTafsirAction;
  final bool isTafsirOpen;
  final VoidCallback? onToggleTafsir;
  final List<QuranWord> words;
  final ValueChanged<QuranWord>? onWordTap;
  final EdgeInsets margin;

  Widget _buildArabicText(BuildContext context) {
    final style = tokens.arabicTextStyle(
      fontSize: 22,
      height: 1.8,
    );

    if (shouldUseQuranWordByWordArabic(
      showWordByWord: showWordByWord,
      hasWordTapHandler: onWordTap != null,
      ayahArabic: ayah.arabic,
      words: words,
    )) {
      return _buildWordByWordArabicText(style);
    }

    if (!showTajweed || ayah.tajweedHtml.trim().isEmpty) {
      return _buildPlainArabicText(style);
    }

    final tajweedSpans = TajweedText.buildSpans(
      html: ayah.tajweedHtml,
      baseStyle: style,
      plainText: ayah.arabic,
      surahNumber: surahNumber,
      ayahNumber: ayah.numberInSurah,
    );
    if (tajweedSpans.isEmpty) {
      return _buildPlainArabicText(style);
    }

    return SizedBox(
      width: double.infinity,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: RichText(
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
          textScaler: MediaQuery.textScalerOf(context),
          text: TextSpan(children: tajweedSpans),
        ),
      ),
    );
  }

  Widget _buildPlainArabicText(TextStyle style) {
    return SizedBox(
      width: double.infinity,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Text(
          ayah.arabic,
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
          style: style,
        ),
      ),
    );
  }

  Widget _buildWordByWordArabicText(TextStyle style) {
    return SizedBox(
      width: double.infinity,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Wrap(
          alignment: WrapAlignment.end,
          textDirection: TextDirection.rtl,
          spacing: 4,
          runSpacing: 6,
          children: words.map((word) {
            return InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => onWordTap?.call(word),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
                child: Text(
                  word.arabic,
                  textDirection: TextDirection.rtl,
                  style: style.copyWith(
                    color: tokens.primaryLight,
                    decoration: TextDecoration.underline,
                    decorationColor: tokens.primary.withValues(alpha: 0.45),
                    decorationThickness: 0.8,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mutedTextColor = tokens.textMuted.withValues(alpha: 0.78);

    return Container(
      margin: margin,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: isSelected
            ? tokens.primaryBg
            : isPlayingAudio
                ? tokens.primaryBg
                : isActiveAudio
                    ? tokens.activeBg
                    : isLastRead
                        ? tokens.activeBg
                        : tokens.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? tokens.primaryBorder
              : isPlayingAudio
                  ? tokens.primaryBorder
                  : isActiveAudio || isLastRead
                      ? tokens.activeBorder
                      : tokens.border,
          width: isActiveAudio ? 1.6 : 1,
        ),
        boxShadow: isActiveAudio
            ? [
                BoxShadow(
                  color: tokens.primary.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 13,
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
                    color: tokens.primaryBg.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: tokens.primaryBorder.withValues(alpha: 0.72),
                    ),
                  ),
                  child: Text(
                    l10n.quranLastReadingBadge,
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      color: tokens.primaryLight,
                    ),
                  ),
                ),
              if (isActiveAudio) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: tokens.primaryBg,
                    shape: BoxShape.circle,
                    border: Border.all(color: tokens.primaryBorder),
                  ),
                  child: Icon(
                    isPlayingAudio
                        ? Icons.graphic_eq_outlined
                        : Icons.pause_circle_outline,
                    size: 14,
                    color: tokens.primary,
                  ),
                ),
              ],
              const Spacer(),
              SizedBox(
                width: 96,
                height: 48,
                child: isSelectionMode
                    ? Align(
                        alignment: Alignment.centerRight,
                        child: Icon(
                          isSelected
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: isSelected ? tokens.primary : tokens.textMuted,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            tooltip: canPlayAudio
                                ? (isPlayingAudio
                                    ? l10n.quranPauseAudio
                                    : isActiveAudio
                                        ? l10n.quranResumeAudio
                                        : l10n.quranPlayAudio)
                                : l10n.quranAudioUnavailable,
                            onPressed: canPlayAudio ? onToggleAudio : null,
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 38,
                              minHeight: 38,
                            ),
                            icon: Icon(
                              !canPlayAudio
                                  ? Icons.volume_off_outlined
                                  : isPlayingAudio
                                      ? Icons.pause_circle_outline
                                      : Icons.play_circle_outline,
                              size: 22,
                              color: !canPlayAudio
                                  ? tokens.textMuted
                                  : tokens.primary,
                            ),
                          ),
                          IconButton(
                            tooltip: isBookmarked
                                ? l10n.quranRemoveBookmark
                                : l10n.quranSaveBookmark,
                            onPressed: onToggleBookmark,
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 38,
                              minHeight: 38,
                            ),
                            icon: Icon(
                              isBookmarked
                                  ? Icons.bookmark
                                  : Icons.bookmark_border,
                              size: 21,
                              color: isBookmarked
                                  ? tokens.primary
                                  : tokens.textMuted,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildArabicText(context),
          if (ayah.transliteration.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              ayah.transliteration,
              style: tokens.transliterationTextStyle(
                fontSize: 13,
                height: 1.65,
              ),
            ),
          ],
          if (ayah.translation.trim().isNotEmpty) ...[
            const SizedBox(height: 9),
            Text(
              ayah.translation,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                height: 1.65,
                color: tokens.textPrimary,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  l10n.quranAyahFooterHint(audioStatusLabel),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    fontSize: 9.5,
                    letterSpacing: 0.1,
                    color: mutedTextColor,
                  ),
                ),
              ),
              if (showTafsirAction && onToggleTafsir != null) ...[
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: onToggleTafsir,
                  icon: Icon(
                    isTafsirOpen
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.menu_book_rounded,
                    size: 15,
                  ),
                  label: Text(l10n.tafsirPanelTitle),
                  style: TextButton.styleFrom(
                    foregroundColor: tokens.primary,
                    textStyle: GoogleFonts.dmSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    minimumSize: const Size(0, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
