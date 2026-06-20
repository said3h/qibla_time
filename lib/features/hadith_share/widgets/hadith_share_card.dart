import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../shared_share/widgets/share_branding_footer.dart';
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
  static const _frameAsset = 'assets/images/app/share_dua_frame.png';

  @override
  Widget build(BuildContext context) {
    final resolvedTheme = theme.resolveFor(data);
    final showArabicMetadata = data.hasArabicText && data.hasArabicReference;
    final showTranslationMetadata =
        data.hasTranslation && data.reference.trim().isNotEmpty;
    final showMetadata = showArabicMetadata || showTranslationMetadata;
    final showBadge = data.badgeLabel.trim().isNotEmpty;
    final footerBottom = resolvedTheme.cardPadding.bottom * 0.58;
    final footerHeight = resolvedTheme.brandingFontSize * 2.75;
    final contentBottom =
        footerBottom + footerHeight + resolvedTheme.sectionSpacing * 0.55;
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
            Positioned(
              left: contentPadding.left,
              top: contentPadding.top,
              right: contentPadding.right,
              bottom: contentBottom,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Align(
                    alignment: Alignment.center,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: SizedBox(
                        width: constraints.maxWidth,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (showBadge) ...[
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
                            ],
                            if (data.hasArabicText) ...[
                              Directionality(
                                textDirection: TextDirection.rtl,
                                child: Text(
                                  data.arabicText!.trim(),
                                  textAlign: TextAlign.center,
                                  maxLines: 20,
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
                              SizedBox(
                                height: resolvedTheme.sectionSpacing * 0.78,
                              ),
                            ],
                            if (data.hasTranslation) ...[
                              Text(
                                data.translation.trim(),
                                textAlign: TextAlign.center,
                                maxLines: data.hasArabicText ? 28 : 34,
                                overflow: TextOverflow.ellipsis,
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
                                    data.arabicReference!.trim(),
                                    textAlign: TextAlign.center,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily:
                                          resolvedTheme.arabicFontFamily,
                                      fontSize:
                                          resolvedTheme.referenceFontSize *
                                              1.02,
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
                                  data.reference.trim(),
                                  textAlign: TextAlign.center,
                                  maxLines: 4,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.dmSans(
                                    fontSize: resolvedTheme.referenceFontSize,
                                    height: resolvedTheme.referenceLineHeight,
                                    fontWeight: FontWeight.w600,
                                    color: resolvedTheme.referenceTextColor,
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              left: contentPadding.left,
              right: contentPadding.right,
              bottom: footerBottom,
              height: footerHeight,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: ShareBrandingFooter(
                  accentColor: resolvedTheme.accentColor,
                  mutedColor: resolvedTheme.brandingTextColor,
                  fontSize: resolvedTheme.brandingFontSize,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
