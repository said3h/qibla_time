import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../shared_share/widgets/share_branding_footer.dart';
import '../../shared_share/widgets/share_content_badge.dart';
import '../models/ayah_share_data.dart';
import '../models/ayah_share_theme.dart';

class AyahShareCard extends StatelessWidget {
  const AyahShareCard({
    super.key,
    required this.data,
    required this.theme,
  });

  final AyahShareData data;
  final AyahShareThemeData theme;
  static const _frameAsset = 'assets/images/app/share_dua_frame.png';

  @override
  Widget build(BuildContext context) {
    final resolvedTheme = theme.resolveFor(data);
    final showArabicMetadata = data.hasArabicText;
    final showTranslationMetadata = data.hasTranslation;
    final showMetadata = showArabicMetadata || showTranslationMetadata;
    final contentPadding = EdgeInsets.fromLTRB(
      resolvedTheme.cardPadding.left * 1.25,
      resolvedTheme.cardPadding.top * 1.55,
      resolvedTheme.cardPadding.right * 1.25,
      resolvedTheme.cardPadding.bottom * 0.82,
    );

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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(resolvedTheme.cardRadius),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: Image.asset(
                _frameAsset,
                fit: BoxFit.fill,
              ),
            ),
            Padding(
              padding: contentPadding,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: ShareContentBadge(
                      label: data.badgeLabel,
                      accentColor: resolvedTheme.accentColor,
                    ),
                  ),
                  SizedBox(
                    height: resolvedTheme.sectionSpacing * 0.8,
                  ),
                  if (data.hasArabicText) ...[
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text(
                        data.arabicText.trim(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: resolvedTheme.arabicFontFamily,
                          fontSize: resolvedTheme.arabicFontSize,
                          height: resolvedTheme.arabicLineHeight,
                          fontWeight: FontWeight.w500,
                          color: resolvedTheme.primaryTextColor,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: resolvedTheme.sectionSpacing * 0.78,
                    ),
                  ],
                  if (data.hasTranslation) ...[
                    Text(
                      data.translation!.trim(),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(
                        fontSize: resolvedTheme.translationFontSize,
                        height: resolvedTheme.translationLineHeight,
                        fontWeight: FontWeight.w500,
                        color: resolvedTheme.primaryTextColor,
                      ),
                    ),
                    SizedBox(
                      height: resolvedTheme.sectionSpacing * 0.65,
                    ),
                  ],
                  if (showMetadata) ...[
                    Container(
                      width: double.infinity,
                      height: 1,
                      color: resolvedTheme.dividerColor,
                    ),
                    SizedBox(
                      height: resolvedTheme.contentSpacing * 0.78,
                    ),
                    if (showArabicMetadata) ...[
                      Directionality(
                        textDirection: TextDirection.rtl,
                        child: Text(
                          data.arabicReferenceLabel,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: resolvedTheme.arabicFontFamily,
                            fontSize: resolvedTheme.referenceFontSize * 1.02,
                            height: resolvedTheme.referenceLineHeight,
                            fontWeight: FontWeight.w600,
                            color: resolvedTheme.secondaryTextColor,
                          ),
                        ),
                      ),
                      if (showTranslationMetadata)
                        SizedBox(
                          height: resolvedTheme.contentSpacing * 0.35,
                        ),
                    ],
                    if (showTranslationMetadata)
                      Text(
                        data.referenceLabel,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.dmSans(
                          fontSize: resolvedTheme.referenceFontSize,
                          height: resolvedTheme.referenceLineHeight,
                          fontWeight: FontWeight.w600,
                          color: resolvedTheme.referenceTextColor,
                        ),
                      ),
                  ],
                  SizedBox(height: resolvedTheme.sectionSpacing * 1.15),
                  ShareBrandingFooter(
                    accentColor: resolvedTheme.accentColor,
                    mutedColor: resolvedTheme.brandingTextColor,
                    fontSize: resolvedTheme.brandingFontSize,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
