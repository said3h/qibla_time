import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/l10n.dart';

class PurificationGuideScreen extends StatelessWidget {
  const PurificationGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;
    final l10n = context.l10n;
    final isArabicOnly = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      backgroundColor: tokens.bgPage,
      appBar: AppBar(
        title: Text(
          l10n.purificationGuideTitle,
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
          _GuideIntroCard(
            title: l10n.purificationGuideSubtitle,
            body: l10n.purificationGuideIntro,
            isArabicOnly: isArabicOnly,
          ),
          const SizedBox(height: 12),
          _GuideSectionCard(
            icon: Icons.water_drop_outlined,
            title: l10n.purificationGuideWuduTitle,
            body: l10n.purificationGuideWuduBody,
            isArabicOnly: isArabicOnly,
          ),
          const SizedBox(height: 12),
          _GuideSectionCard(
            icon: Icons.shower_outlined,
            title: l10n.purificationGuideGhuslTitle,
            body: l10n.purificationGuideGhuslBody,
            isArabicOnly: isArabicOnly,
          ),
          const SizedBox(height: 12),
          _GuideSectionCard(
            icon: Icons.info_outline_rounded,
            title: l10n.purificationGuideFinalNoteTitle,
            body: l10n.purificationGuideFinalNoteBody,
            isArabicOnly: isArabicOnly,
          ),
        ],
      ),
    );
  }
}

class _GuideIntroCard extends StatelessWidget {
  const _GuideIntroCard({
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
            style: isArabicOnly
                ? GoogleFonts.amiri(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: tokens.textPrimary,
                  )
                : GoogleFonts.dmSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: tokens.textPrimary,
                  ),
          ),
          const SizedBox(height: 12),
          Text(
            body,
            textAlign: isArabicOnly ? TextAlign.right : TextAlign.left,
            style: isArabicOnly
                ? GoogleFonts.amiri(
                    fontSize: 18,
                    height: 1.7,
                    color: tokens.textSecondary,
                  )
                : GoogleFonts.dmSans(
                    fontSize: 14,
                    height: 1.7,
                    color: tokens.textSecondary,
                  ),
          ),
        ],
      ),
    );
  }
}

class _GuideSectionCard extends StatelessWidget {
  const _GuideSectionCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.isArabicOnly,
  });

  final IconData icon;
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: tokens.primaryBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: tokens.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  textAlign: isArabicOnly ? TextAlign.right : TextAlign.left,
                  style: isArabicOnly
                      ? GoogleFonts.amiri(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: tokens.textPrimary,
                        )
                      : GoogleFonts.dmSans(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: tokens.textPrimary,
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            body,
            textAlign: isArabicOnly ? TextAlign.right : TextAlign.left,
            style: isArabicOnly
                ? GoogleFonts.amiri(
                    fontSize: 18,
                    height: 1.75,
                    color: tokens.textSecondary,
                  )
                : GoogleFonts.dmSans(
                    fontSize: 14,
                    height: 1.75,
                    color: tokens.textSecondary,
                  ),
          ),
        ],
      ),
    );
  }
}
