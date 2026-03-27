import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: resolvedTheme.accentColor.withOpacity(0.10),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'HADITH',
                style: GoogleFonts.dmSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.8,
                  color: resolvedTheme.accentColor,
                ),
              ),
            ),
            if (data.hasArabicText) ...[
              SizedBox(height: resolvedTheme.sectionSpacing),
              Directionality(
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
              SizedBox(height: resolvedTheme.sectionSpacing),
            ] else
              SizedBox(height: resolvedTheme.sectionSpacing * 0.7),
            Text(
              data.translation.trim(),
              maxLines: data.hasArabicText ? 13 : 16,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.dmSans(
                fontSize: resolvedTheme.translationFontSize,
                height: resolvedTheme.translationLineHeight,
                fontWeight: FontWeight.w500,
                color: resolvedTheme.primaryTextColor,
              ),
            ),
            SizedBox(height: resolvedTheme.sectionSpacing),
            Container(
              width: double.infinity,
              height: 1,
              color: resolvedTheme.dividerColor,
            ),
            SizedBox(height: resolvedTheme.contentSpacing),
            Text(
              data.reference.trim(),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.dmSans(
                fontSize: resolvedTheme.referenceFontSize,
                height: resolvedTheme.referenceLineHeight,
                fontWeight: FontWeight.w600,
                color: resolvedTheme.referenceTextColor,
              ),
            ),
            SizedBox(height: resolvedTheme.contentSpacing * 1.2),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                data.branding.trim(),
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
