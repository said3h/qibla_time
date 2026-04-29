import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../models/quran_models.dart';
import 'tajweed_text.dart';

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
    required this.audioStatusLabel,
    required this.onToggleAudio,
    required this.onToggleBookmark,
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
  final String audioStatusLabel;
  final VoidCallback onToggleAudio;
  final VoidCallback onToggleBookmark;
  final EdgeInsets margin;

  Widget _buildArabicText() {
    final style = GoogleFonts.amiri(
      fontSize: 22,
      height: 1.8,
      color: tokens.textPrimary,
    );

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

    return Directionality(
      textDirection: TextDirection.rtl,
      child: RichText(
        textAlign: TextAlign.right,
        textDirection: TextDirection.rtl,
        text: TextSpan(children: tajweedSpans),
      ),
    );
  }

  Widget _buildPlainArabicText(TextStyle style) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Text(
        ayah.arabic,
        textAlign: TextAlign.right,
        textDirection: TextDirection.rtl,
        style: style,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: const EdgeInsets.all(16),
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
                  color: tokens.primary.withOpacity(0.08),
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
                                ? l10n.quranRemoveBookmark
                                : l10n.quranSaveBookmark,
                            onPressed: onToggleBookmark,
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
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildArabicText(),
          if (ayah.transliteration.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              ayah.transliteration,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                height: 1.7,
                fontStyle: FontStyle.italic,
                color: tokens.textSecondary,
              ),
            ),
          ],
          if (ayah.translation.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              ayah.translation,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                height: 1.7,
                color: tokens.textPrimary,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            l10n.quranAyahFooterHint(audioStatusLabel),
            style: GoogleFonts.dmSans(
              fontSize: 10,
              color: tokens.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
