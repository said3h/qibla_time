import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../shared_share/widgets/share_content_badge.dart';
import '../models/hadith_share_data.dart';
import '../models/hadith_share_theme.dart';

class HadithShareCard extends StatelessWidget {
  const HadithShareCard({
    super.key,
    required this.data,
    required this.theme,
  });

  final HadithShareData data;
  final HadithShareThemeData theme;

  @override
  Widget build(BuildContext context) {
    final resolvedTheme = theme.resolveFor(data);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: resolvedTheme.cardBackgroundColor,
        borderRadius: BorderRadius.circular(resolvedTheme.cardRadius),
        boxShadow: [
          BoxShadow(
            color: resolvedTheme.shadowColor,
            blurRadius: 64,
            spreadRadius: 2,
            offset: const Offset(0, 24),
          ),
        ],
      ),
      child: Padding(
        padding: resolvedTheme.cardPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShareContentBadge(
              label: data.badgeLabel,
              accentColor: resolvedTheme.accentColor,
            ),
            if (data.hasArabicText) ...[
              SizedBox(height: resolvedTheme.sectionSpacing),
              SizedBox(
                width: double.infinity,
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    data.arabicText!.trim(),
                    textAlign: TextAlign.right,
                    maxLines: 8,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: resolvedTheme.arabicFontFamily,
                      fontSize: resolvedTheme.arabicFontSize,
                      height: resolvedTheme.arabicLineHeight,
                      fontWeight: FontWeight.w500,
                      color: resolvedTheme.primaryTextColor,
                    ),
                  ),
                ),
              ),
              SizedBox(height: resolvedTheme.sectionSpacing),
            ] else
              SizedBox(height: resolvedTheme.sectionSpacing * 0.7),
            if (data.hasTranslation) ...[
              SizedBox(
                width: double.infinity,
                child: Text(
                  data.translation.trim(),
                  textAlign: TextAlign.left,
                  maxLines: data.hasArabicText ? 13 : 16,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    fontSize: resolvedTheme.translationFontSize,
                    height: resolvedTheme.translationLineHeight,
                    fontWeight: FontWeight.w500,
                    color: resolvedTheme.primaryTextColor,
                  ),
                ),
              ),
              SizedBox(height: resolvedTheme.sectionSpacing),
            ],
            Container(
              width: double.infinity,
              height: 1,
              color: resolvedTheme.dividerColor,
            ),
            SizedBox(height: resolvedTheme.contentSpacing),
            if (data.hasArabicReference) ...[
              SizedBox(
                width: double.infinity,
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    data.arabicReference!.trim(),
                    textAlign: TextAlign.right,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: resolvedTheme.arabicFontFamily,
                      fontSize: resolvedTheme.referenceFontSize * 1.02,
                      height: resolvedTheme.referenceLineHeight,
                      fontWeight: FontWeight.w600,
                      color: resolvedTheme.secondaryTextColor,
                    ),
                  ),
                ),
              ),
              SizedBox(height: resolvedTheme.contentSpacing * 0.55),
            ],
            SizedBox(
              width: double.infinity,
              child: Text(
                data.reference.trim(),
                textAlign: TextAlign.left,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.dmSans(
                  fontSize: resolvedTheme.referenceFontSize,
                  height: resolvedTheme.referenceLineHeight,
                  fontWeight: FontWeight.w600,
                  color: resolvedTheme.referenceTextColor,
                ),
              ),
            ),
            SizedBox(height: resolvedTheme.contentSpacing * 1.2),
            SizedBox(
              width: double.infinity,
              child: Text(
                data.branding.trim(),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.dmSans(
                  fontSize: resolvedTheme.brandingFontSize,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                  color: resolvedTheme.brandingTextColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
