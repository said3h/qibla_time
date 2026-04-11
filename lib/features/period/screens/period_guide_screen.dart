import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/l10n.dart';

class PeriodGuideScreen extends StatelessWidget {
  const PeriodGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;
    final l10n = context.l10n;
    final isArabicOnly = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      backgroundColor: tokens.bgPage,
      appBar: AppBar(
        title: Text(
          l10n.periodGuideTitle,
          style: isArabicOnly
              ? GoogleFonts.amiri(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: tokens.primary,
                )
              : GoogleFonts.dmSerifDisplay(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: tokens.primary,
                ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _PeriodIntroCard(
            body: l10n.periodGuideIntro,
            isArabicOnly: isArabicOnly,
          ),
          const SizedBox(height: 12),
          _PeriodSectionCard(
            icon: Icons.check_circle_outline_rounded,
            title: l10n.periodGuideAllowed,
            items: [
              l10n.periodGuideAllowedDhikr,
              l10n.periodGuideAllowedDua,
              l10n.periodGuideAllowedListenQuran,
              l10n.periodGuideAllowedReadTranslation,
            ],
            isArabicOnly: isArabicOnly,
          ),
          const SizedBox(height: 12),
          _PeriodSectionCard(
            icon: Icons.pause_circle_outline_rounded,
            title: l10n.periodGuidePaused,
            items: [
              l10n.periodGuidePausedPrayer,
              l10n.periodGuidePausedFasting,
              l10n.periodGuidePausedTawaf,
              l10n.periodGuidePausedTouchQuran,
            ],
            isArabicOnly: isArabicOnly,
          ),
          const SizedBox(height: 12),
          _PeriodNoteCard(
            title: l10n.periodGuideNote,
            body: l10n.periodGuideNoteBody,
            isArabicOnly: isArabicOnly,
          ),
        ],
      ),
    );
  }
}

class _PeriodIntroCard extends StatelessWidget {
  const _PeriodIntroCard({
    required this.body,
    required this.isArabicOnly,
  });

  final String body;
  final bool isArabicOnly;

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tokens.primaryBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tokens.primaryBorder),
      ),
      child: Text(
        body,
        textAlign: isArabicOnly ? TextAlign.right : TextAlign.left,
        style: _bodyStyle(tokens, isArabicOnly).copyWith(
          color: tokens.textPrimary,
          height: 1.6,
        ),
      ),
    );
  }
}

class _PeriodSectionCard extends StatelessWidget {
  const _PeriodSectionCard({
    required this.icon,
    required this.title,
    required this.items,
    required this.isArabicOnly,
  });

  final IconData icon;
  final String title;
  final List<String> items;
  final bool isArabicOnly;

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tokens.bgSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: tokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            textDirection: isArabicOnly ? TextDirection.rtl : TextDirection.ltr,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: tokens.primaryBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: tokens.primaryBorder),
                ),
                child: Icon(icon, color: tokens.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  textAlign: isArabicOnly ? TextAlign.right : TextAlign.left,
                  style: _headingStyle(tokens, isArabicOnly),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                textDirection:
                    isArabicOnly ? TextDirection.rtl : TextDirection.ltr,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: tokens.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      textAlign:
                          isArabicOnly ? TextAlign.right : TextAlign.left,
                      style: _bodyStyle(tokens, isArabicOnly),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodNoteCard extends StatelessWidget {
  const _PeriodNoteCard({
    required this.title,
    required this.body,
    required this.isArabicOnly,
  });

  final String title;
  final String body;
  final bool isArabicOnly;

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tokens.bgSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: tokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            textAlign: isArabicOnly ? TextAlign.right : TextAlign.left,
            style: _headingStyle(tokens, isArabicOnly),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            textAlign: isArabicOnly ? TextAlign.right : TextAlign.left,
            style: _bodyStyle(tokens, isArabicOnly),
          ),
        ],
      ),
    );
  }
}

TextStyle _headingStyle(QiblaTokens tokens, bool isArabicOnly) {
  return isArabicOnly
      ? GoogleFonts.amiri(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: tokens.primaryLight,
        )
      : GoogleFonts.dmSerifDisplay(
          fontSize: 20,
          fontWeight: FontWeight.w400,
          color: tokens.primaryLight,
        );
}

TextStyle _bodyStyle(QiblaTokens tokens, bool isArabicOnly) {
  return isArabicOnly
      ? GoogleFonts.amiri(
          fontSize: 16,
          height: 1.75,
          color: tokens.textPrimary,
        )
      : GoogleFonts.dmSans(
          fontSize: 13,
          height: 1.65,
          color: tokens.textPrimary,
        );
}
