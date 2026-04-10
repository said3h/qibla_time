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
          _WuduGuideCard(
            isArabicOnly: isArabicOnly,
          ),
          const SizedBox(height: 12),
          _GhuslGuideCard(
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

class _WuduGuideCard extends StatelessWidget {
  const _WuduGuideCard({
    required this.isArabicOnly,
  });

  final bool isArabicOnly;

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;
    final l10n = context.l10n;
    final steps = <_PurificationStep>[
      _PurificationStep(
        number: 1,
        title: l10n.purificationGuideWuduStep1Title,
        body: l10n.purificationGuideWuduStep1Body,
        badge: l10n.purificationGuideWuduRepeatOnce,
      ),
      _PurificationStep(
        number: 2,
        title: l10n.purificationGuideWuduStep2Title,
        body: l10n.purificationGuideWuduStep2Body,
        badge: l10n.purificationGuideWuduRepeatOnce,
      ),
      _PurificationStep(
        number: 3,
        title: l10n.purificationGuideWuduStep3Title,
        body: l10n.purificationGuideWuduStep3Body,
        badge: l10n.purificationGuideWuduRepeatThreeTimes,
      ),
      _PurificationStep(
        number: 4,
        title: l10n.purificationGuideWuduStep4Title,
        body: l10n.purificationGuideWuduStep4Body,
        badge: l10n.purificationGuideWuduRepeatThreeTimes,
      ),
      _PurificationStep(
        number: 5,
        title: l10n.purificationGuideWuduStep5Title,
        body: l10n.purificationGuideWuduStep5Body,
        badge: l10n.purificationGuideWuduRepeatThreeTimes,
      ),
      _PurificationStep(
        number: 6,
        title: l10n.purificationGuideWuduStep6Title,
        body: l10n.purificationGuideWuduStep6Body,
        badge: l10n.purificationGuideWuduRepeatThreeTimes,
      ),
      _PurificationStep(
        number: 7,
        title: l10n.purificationGuideWuduStep7Title,
        body: l10n.purificationGuideWuduStep7Body,
        badge: l10n.purificationGuideWuduRepeatThreeTimes,
      ),
      _PurificationStep(
        number: 8,
        title: l10n.purificationGuideWuduStep8Title,
        body: l10n.purificationGuideWuduStep8Body,
        badge: l10n.purificationGuideWuduRepeatOnce,
      ),
      _PurificationStep(
        number: 9,
        title: l10n.purificationGuideWuduStep9Title,
        body: l10n.purificationGuideWuduStep9Body,
        badge: l10n.purificationGuideWuduRepeatOnce,
      ),
      _PurificationStep(
        number: 10,
        title: l10n.purificationGuideWuduStep10Title,
        body: l10n.purificationGuideWuduStep10Body,
        badge: l10n.purificationGuideWuduRepeatThreeTimes,
      ),
    ];

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
          _GuideSectionHeader(
            icon: Icons.water_drop_outlined,
            title: l10n.purificationGuideWuduTitle,
            isArabicOnly: isArabicOnly,
          ),
          const SizedBox(height: 14),
          _GuideMiniSection(
            title: l10n.purificationGuideWuduWhatIsLabel,
            isArabicOnly: isArabicOnly,
            child: Text(
              l10n.purificationGuideWuduWhatIsBody,
              textAlign: isArabicOnly ? TextAlign.right : TextAlign.left,
              style: _sectionBodyStyle(tokens),
            ),
          ),
          const SizedBox(height: 12),
          _GuideMiniSection(
            title: l10n.purificationGuideWuduWhenNeededLabel,
            isArabicOnly: isArabicOnly,
            child: Column(
              children: [
                _GuideBulletLine(
                  text: l10n.purificationGuideWuduWhenNeededPrayer,
                  isArabicOnly: isArabicOnly,
                ),
                _GuideBulletLine(
                  text: l10n.purificationGuideWuduWhenNeededBathroom,
                  isArabicOnly: isArabicOnly,
                ),
                _GuideBulletLine(
                  text: l10n.purificationGuideWuduWhenNeededPurityLoss,
                  isArabicOnly: isArabicOnly,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: tokens.primaryBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: tokens.primaryBorder),
            ),
            child: Text(
              l10n.purificationGuideWuduStepsSubtitle,
              textAlign: isArabicOnly ? TextAlign.right : TextAlign.left,
              style: _sectionBodyStyle(tokens).copyWith(
                color: tokens.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            l10n.purificationGuideWuduStepsTitle,
            textAlign: isArabicOnly ? TextAlign.right : TextAlign.left,
            style: _sectionHeadingStyle(tokens),
          ),
          const SizedBox(height: 12),
          ...steps.map(
            (step) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _PurificationStepCard(
                step: step,
                isArabicOnly: isArabicOnly,
              ),
            ),
          ),
          const SizedBox(height: 4),
          _GuideMiniSection(
            title: l10n.purificationGuideWuduNotesTitle,
            isArabicOnly: isArabicOnly,
            child: Column(
              children: [
                _GuideBulletLine(
                  text: l10n.purificationGuideWuduNoteModeration,
                  isArabicOnly: isArabicOnly,
                ),
                _GuideBulletLine(
                  text: l10n.purificationGuideWuduNoteWater,
                  isArabicOnly: isArabicOnly,
                ),
                _GuideBulletLine(
                  text: l10n.purificationGuideWuduNoteOrder,
                  isArabicOnly: isArabicOnly,
                ),
                _GuideBulletLine(
                  text: l10n.purificationGuideWuduNoteObstacles,
                  isArabicOnly: isArabicOnly,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _sectionHeadingStyle(QiblaTokens tokens) {
    return _guideSectionHeadingStyle(tokens, isArabicOnly);
  }

  TextStyle _sectionBodyStyle(QiblaTokens tokens) {
    return _guideSectionBodyStyle(tokens, isArabicOnly);
  }
}

class _GhuslGuideCard extends StatelessWidget {
  const _GhuslGuideCard({
    required this.isArabicOnly,
  });

  final bool isArabicOnly;

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;
    final l10n = context.l10n;
    final steps = <_PurificationStep>[
      _PurificationStep(
        number: 1,
        title: l10n.purificationGuideGhuslStep1Title,
        body: l10n.purificationGuideGhuslStep1Body,
        badge: l10n.purificationGuideGhuslBadgeEssential,
      ),
      _PurificationStep(
        number: 2,
        title: l10n.purificationGuideGhuslStep2Title,
        body: l10n.purificationGuideGhuslStep2Body,
        badge: l10n.purificationGuideGhuslBadgeRecommended,
      ),
      _PurificationStep(
        number: 3,
        title: l10n.purificationGuideGhuslStep3Title,
        body: l10n.purificationGuideGhuslStep3Body,
        badge: l10n.purificationGuideGhuslBadgeRecommended,
      ),
      _PurificationStep(
        number: 4,
        title: l10n.purificationGuideGhuslStep4Title,
        body: l10n.purificationGuideGhuslStep4Body,
        badge: l10n.purificationGuideGhuslBadgeUntilClean,
      ),
      _PurificationStep(
        number: 5,
        title: l10n.purificationGuideGhuslStep5Title,
        body: l10n.purificationGuideGhuslStep5Body,
        badge: l10n.purificationGuideGhuslBadgeRecommended,
      ),
      _PurificationStep(
        number: 6,
        title: l10n.purificationGuideGhuslStep6Title,
        body: l10n.purificationGuideGhuslStep6Body,
        badge: l10n.purificationGuideGhuslBadgeUsuallyThreeTimes,
      ),
      _PurificationStep(
        number: 7,
        title: l10n.purificationGuideGhuslStep7Title,
        body: l10n.purificationGuideGhuslStep7Body,
        badge: l10n.purificationGuideGhuslBadgeNoFixedCount,
      ),
      _PurificationStep(
        number: 8,
        title: l10n.purificationGuideGhuslStep8Title,
        body: l10n.purificationGuideGhuslStep8Body,
        badge: l10n.purificationGuideGhuslBadgeEssential,
      ),
    ];

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
          _GuideSectionHeader(
            icon: Icons.shower_outlined,
            title: l10n.purificationGuideGhuslTitle,
            isArabicOnly: isArabicOnly,
          ),
          const SizedBox(height: 14),
          _GuideMiniSection(
            title: l10n.purificationGuideGhuslWhatIsLabel,
            isArabicOnly: isArabicOnly,
            child: Text(
              l10n.purificationGuideGhuslWhatIsBody,
              textAlign: isArabicOnly ? TextAlign.right : TextAlign.left,
              style: _guideSectionBodyStyle(tokens, isArabicOnly),
            ),
          ),
          const SizedBox(height: 12),
          _GuideMiniSection(
            title: l10n.purificationGuideGhuslWhenNeededLabel,
            isArabicOnly: isArabicOnly,
            child: Column(
              children: [
                _GuideBulletLine(
                  text: l10n.purificationGuideGhuslWhenNeededRelations,
                  isArabicOnly: isArabicOnly,
                ),
                _GuideBulletLine(
                  text: l10n.purificationGuideGhuslWhenNeededMenstruation,
                  isArabicOnly: isArabicOnly,
                ),
                _GuideBulletLine(
                  text: l10n.purificationGuideGhuslWhenNeededPostnatal,
                  isArabicOnly: isArabicOnly,
                ),
                _GuideBulletLine(
                  text: l10n.purificationGuideGhuslWhenNeededDischarge,
                  isArabicOnly: isArabicOnly,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: tokens.primaryBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: tokens.primaryBorder),
            ),
            child: Text(
              l10n.purificationGuideGhuslStepsSubtitle,
              textAlign: isArabicOnly ? TextAlign.right : TextAlign.left,
              style: _guideSectionBodyStyle(tokens, isArabicOnly).copyWith(
                color: tokens.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _GuideMiniSection(
            title: l10n.purificationGuideGhuslValidityTitle,
            isArabicOnly: isArabicOnly,
            child: Column(
              children: [
                _GuideBulletLine(
                  text: l10n.purificationGuideGhuslValidityRecommended,
                  isArabicOnly: isArabicOnly,
                ),
                _GuideBulletLine(
                  text: l10n.purificationGuideGhuslValidityMinimum,
                  isArabicOnly: isArabicOnly,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            l10n.purificationGuideGhuslStepsTitle,
            textAlign: isArabicOnly ? TextAlign.right : TextAlign.left,
            style: _guideSectionHeadingStyle(tokens, isArabicOnly),
          ),
          const SizedBox(height: 12),
          ...steps.map(
            (step) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _PurificationStepCard(
                step: step,
                isArabicOnly: isArabicOnly,
              ),
            ),
          ),
          const SizedBox(height: 4),
          _GuideMiniSection(
            title: l10n.purificationGuideGhuslNotesTitle,
            isArabicOnly: isArabicOnly,
            child: Column(
              children: [
                _GuideBulletLine(
                  text: l10n.purificationGuideGhuslNoteDrySpots,
                  isArabicOnly: isArabicOnly,
                ),
                _GuideBulletLine(
                  text: l10n.purificationGuideGhuslNoteScalp,
                  isArabicOnly: isArabicOnly,
                ),
                _GuideBulletLine(
                  text: l10n.purificationGuideGhuslNoteBarriers,
                  isArabicOnly: isArabicOnly,
                ),
                _GuideBulletLine(
                  text: l10n.purificationGuideGhuslNoteSimplicity,
                  isArabicOnly: isArabicOnly,
                ),
              ],
            ),
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

TextStyle _guideSectionHeadingStyle(
  QiblaTokens tokens,
  bool isArabicOnly,
) {
  return isArabicOnly
      ? GoogleFonts.amiri(
          fontSize: 21,
          fontWeight: FontWeight.w700,
          color: tokens.textPrimary,
        )
      : GoogleFonts.dmSans(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: tokens.textPrimary,
        );
}

TextStyle _guideSectionBodyStyle(
  QiblaTokens tokens,
  bool isArabicOnly,
) {
  return isArabicOnly
      ? GoogleFonts.amiri(
          fontSize: 18,
          height: 1.75,
          color: tokens.textSecondary,
        )
      : GoogleFonts.dmSans(
          fontSize: 14,
          height: 1.7,
          color: tokens.textSecondary,
        );
}

class _GuideSectionHeader extends StatelessWidget {
  const _GuideSectionHeader({
    required this.icon,
    required this.title,
    required this.isArabicOnly,
  });

  final IconData icon;
  final String title;
  final bool isArabicOnly;

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      textDirection: isArabicOnly ? TextDirection.rtl : TextDirection.ltr,
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
    final baseStyle = isArabicOnly
        ? GoogleFonts.amiri(
            fontSize: 18,
            height: 1.75,
            color: tokens.textSecondary,
          )
        : GoogleFonts.dmSans(
            fontSize: 14,
            height: 1.75,
            color: tokens.textSecondary,
          );
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
          _GuideSectionHeader(
            icon: icon,
            title: title,
            isArabicOnly: isArabicOnly,
          ),
          const SizedBox(height: 14),
          ..._buildBodyContent(tokens, baseStyle),
        ],
      ),
    );
  }

  List<Widget> _buildBodyContent(QiblaTokens tokens, TextStyle baseStyle) {
    final widgets = <Widget>[];
    final lines = body.split('\n');
    final stepPattern = RegExp(r'^(\d+)\.\s+(.*)$');

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) {
        widgets.add(const SizedBox(height: 12));
        continue;
      }

      final stepMatch = stepPattern.firstMatch(line);
      if (stepMatch != null) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              textDirection:
                  isArabicOnly ? TextDirection.rtl : TextDirection.ltr,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: tokens.primaryBg,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    stepMatch.group(1)!,
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: tokens.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    stepMatch.group(2)!,
                    textAlign: isArabicOnly ? TextAlign.right : TextAlign.left,
                    style: baseStyle.copyWith(
                      fontWeight: FontWeight.w600,
                      color: tokens.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        continue;
      }

      if (line.startsWith('•')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              textDirection:
                  isArabicOnly ? TextDirection.rtl : TextDirection.ltr,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Icon(
                    Icons.circle,
                    size: 6,
                    color: tokens.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    line.substring(1).trim(),
                    textAlign: isArabicOnly ? TextAlign.right : TextAlign.left,
                    style: baseStyle,
                  ),
                ),
              ],
            ),
          ),
        );
        continue;
      }

      final isHeading = line.endsWith(':');
      widgets.add(
        Padding(
          padding: EdgeInsets.only(bottom: isHeading ? 8 : 6),
          child: Text(
            line,
            textAlign: isArabicOnly ? TextAlign.right : TextAlign.left,
            style: isHeading
                ? baseStyle.copyWith(
                    fontWeight: FontWeight.w800,
                    color: tokens.textPrimary,
                  )
                : baseStyle,
          ),
        ),
      );
    }

    return widgets;
  }
}

class _GuideMiniSection extends StatelessWidget {
  const _GuideMiniSection({
    required this.title,
    required this.child,
    required this.isArabicOnly,
  });

  final String title;
  final Widget child;
  final bool isArabicOnly;

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tokens.bgSurface2,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tokens.border),
      ),
      child: Column(
        crossAxisAlignment:
            isArabicOnly ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            title,
            textAlign: isArabicOnly ? TextAlign.right : TextAlign.left,
            style: isArabicOnly
                ? GoogleFonts.amiri(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: tokens.textPrimary,
                  )
                : GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: tokens.textPrimary,
                  ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _GuideBulletLine extends StatelessWidget {
  const _GuideBulletLine({
    required this.text,
    required this.isArabicOnly,
  });

  final String text;
  final bool isArabicOnly;

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;
    final textStyle = isArabicOnly
        ? GoogleFonts.amiri(
            fontSize: 18,
            height: 1.7,
            color: tokens.textSecondary,
          )
        : GoogleFonts.dmSans(
            fontSize: 14,
            height: 1.65,
            color: tokens.textSecondary,
          );
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        textDirection: isArabicOnly ? TextDirection.rtl : TextDirection.ltr,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Icon(
              Icons.circle,
              size: 6,
              color: tokens.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              textAlign: isArabicOnly ? TextAlign.right : TextAlign.left,
              style: textStyle,
            ),
          ),
        ],
      ),
    );
  }
}

class _PurificationStepCard extends StatelessWidget {
  const _PurificationStepCard({
    required this.step,
    required this.isArabicOnly,
  });

  final _PurificationStep step;
  final bool isArabicOnly;

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;
    final titleStyle = isArabicOnly
        ? GoogleFonts.amiri(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: tokens.textPrimary,
          )
        : GoogleFonts.dmSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: tokens.textPrimary,
          );
    final bodyStyle = isArabicOnly
        ? GoogleFonts.amiri(
            fontSize: 18,
            height: 1.7,
            color: tokens.textSecondary,
          )
        : GoogleFonts.dmSans(
            fontSize: 13.5,
            height: 1.65,
            color: tokens.textSecondary,
          );
    final badgeTextStyle = isArabicOnly
        ? GoogleFonts.amiri(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: tokens.primary,
          )
        : GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: tokens.primary,
          );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.bgSurface2,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tokens.border),
      ),
      child: Directionality(
        textDirection: isArabicOnly ? TextDirection.rtl : TextDirection.ltr,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: tokens.primaryBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: tokens.primaryBorder),
                  ),
                  child: Text(
                    '${step.number}',
                    style: badgeTextStyle.copyWith(
                      fontSize: isArabicOnly ? 16 : 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    step.title,
                    textAlign: isArabicOnly ? TextAlign.right : TextAlign.left,
                    style: titleStyle,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: tokens.primaryBg,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: tokens.primaryBorder),
                  ),
                  child: Text(
                    step.badge,
                    style: badgeTextStyle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              step.body,
              textAlign: isArabicOnly ? TextAlign.right : TextAlign.left,
              style: bodyStyle,
            ),
          ],
        ),
      ),
    );
  }
}

class _PurificationStep {
  const _PurificationStep({
    required this.number,
    required this.title,
    required this.body,
    required this.badge,
  });

  final int number;
  final String title;
  final String body;
  final String badge;
}
