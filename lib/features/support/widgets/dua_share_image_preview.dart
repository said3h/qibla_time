import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../hadith_share/models/hadith_share_data.dart';
import '../../hadith_share/models/hadith_share_theme.dart';
import '../../shared_share/widgets/share_branding_footer.dart';

class DuaShareImagePreview extends StatelessWidget {
  const DuaShareImagePreview({
    super.key,
    required this.data,
    required this.theme,
    this.cardOnly = false,
  });

  final HadithShareData data;
  final HadithShareThemeData theme;
  final bool cardOnly;

  @override
  Widget build(BuildContext context) {
    final maxCardWidth =
        theme.canvasSize.width - theme.canvasPadding.horizontal;
    final maxCardHeight =
        theme.canvasSize.height - theme.canvasPadding.vertical;
    final targetCardWidth = theme.canvasSize.width * theme.cardWidthFactor;
    final cardWidth =
        targetCardWidth < maxCardWidth ? targetCardWidth : maxCardWidth;
    final card = SizedBox(
      width: cardWidth,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxCardHeight),
        child: DuaShareImageCard(
          data: data,
          theme: theme,
        ),
      ),
    );

    if (cardOnly) {
      return card;
    }

    return ColoredBox(
      color: theme.canvasBackgroundColor,
      child: SizedBox(
        width: theme.canvasSize.width,
        height: theme.canvasSize.height,
        child: Center(
          child: Padding(
            padding: theme.canvasPadding,
            child: card,
          ),
        ),
      ),
    );
  }
}

class DuaShareImageCard extends StatelessWidget {
  const DuaShareImageCard({
    super.key,
    required this.data,
    required this.theme,
  });

  final HadithShareData data;
  final HadithShareThemeData theme;
  static const _cornerOrnamentAsset =
      'assets/images/app/share_corner_ornament.png';

  @override
  Widget build(BuildContext context) {
    final resolvedTheme = theme.resolveFor(data);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: resolvedTheme.cardBackgroundColor,
        borderRadius: BorderRadius.circular(resolvedTheme.cardRadius),
        border: Border.all(
          color: resolvedTheme.accentColor.withValues(alpha: 0.72),
          width: 1.4,
        ),
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
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      resolvedTheme.cardRadius - 14,
                    ),
                    border: Border.all(
                      color: resolvedTheme.accentColor.withValues(alpha: 0.28),
                      width: 0.9,
                    ),
                  ),
                ),
              ),
            ),
            const _CornerOrnament(
              asset: _cornerOrnamentAsset,
              alignment: Alignment.topLeft,
              angle: 0,
            ),
            const _CornerOrnament(
              asset: _cornerOrnamentAsset,
              alignment: Alignment.topRight,
              angle: math.pi / 2,
            ),
            const _CornerOrnament(
              asset: _cornerOrnamentAsset,
              alignment: Alignment.bottomRight,
              angle: math.pi,
            ),
            const _CornerOrnament(
              asset: _cornerOrnamentAsset,
              alignment: Alignment.bottomLeft,
              angle: -math.pi / 2,
            ),
            Padding(
              padding: resolvedTheme.cardPadding,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (data.hasArabicText) ...[
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text(
                        data.arabicText!.trim(),
                        textAlign: TextAlign.center,
                        maxLines: 9,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: resolvedTheme.arabicFontFamily,
                          fontSize: resolvedTheme.arabicFontSize,
                          height: resolvedTheme.arabicLineHeight,
                          fontWeight: FontWeight.w600,
                          color: resolvedTheme.accentColor,
                        ),
                      ),
                    ),
                    SizedBox(height: resolvedTheme.sectionSpacing),
                  ],
                  if (data.hasTranslation) ...[
                    Text(
                      data.translation.trim(),
                      textAlign: TextAlign.center,
                      maxLines: data.hasArabicText ? 13 : 16,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(
                        fontSize: resolvedTheme.translationFontSize,
                        height: resolvedTheme.translationLineHeight,
                        fontWeight: FontWeight.w600,
                        color: resolvedTheme.referenceTextColor,
                      ),
                    ),
                    SizedBox(height: resolvedTheme.sectionSpacing),
                  ],
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

class _CornerOrnament extends StatelessWidget {
  const _CornerOrnament({
    required this.asset,
    required this.alignment,
    required this.angle,
  });

  final String asset;
  final Alignment alignment;
  final double angle;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Align(
          alignment: alignment,
          child: Padding(
            padding: const EdgeInsets.all(17),
            child: Transform.rotate(
              angle: angle,
              child: Image.asset(
                asset,
                width: 172,
                height: 172,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
