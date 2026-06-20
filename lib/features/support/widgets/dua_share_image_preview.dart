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
        child: CustomPaint(
          foregroundPainter: _DuaShareCornerPainter(
            color: resolvedTheme.accentColor.withValues(alpha: 0.84),
            radius: resolvedTheme.cardRadius,
          ),
          child: Padding(
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
        ),
      ),
    );
  }
}

class _DuaShareCornerPainter extends CustomPainter {
  const _DuaShareCornerPainter({
    required this.color,
    required this.radius,
  });

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const inset = 22.0;
    const length = 68.0;
    const curl = 18.0;

    void drawCorner({required bool right, required bool bottom}) {
      final x = right ? size.width - inset : inset;
      final y = bottom ? size.height - inset : inset;
      final horizontalEnd = Offset(x + (right ? -length : length), y);
      final verticalEnd = Offset(x, y + (bottom ? -length : length));

      final path = Path()
        ..moveTo(x, y)
        ..lineTo(horizontalEnd.dx, horizontalEnd.dy)
        ..moveTo(x, y)
        ..lineTo(verticalEnd.dx, verticalEnd.dy);
      canvas.drawPath(path, paint);

      final curlRect = Rect.fromCircle(
        center: Offset(
          x + (right ? -length : length),
          y + (bottom ? -curl : curl),
        ),
        radius: curl,
      );
      canvas.drawArc(
        curlRect,
        right ? (bottom ? 0.2 : -1.8) : (bottom ? 1.4 : -0.2),
        right ? -1.15 : 1.15,
        false,
        paint,
      );

      final dotOffset = Offset(
        x + (right ? -length - 18 : length + 18),
        y,
      );
      canvas.drawCircle(dotOffset, 2.4, paint..style = PaintingStyle.fill);
      paint.style = PaintingStyle.stroke;
    }

    drawCorner(right: false, bottom: false);
    drawCorner(right: true, bottom: false);
    drawCorner(right: false, bottom: true);
    drawCorner(right: true, bottom: true);
  }

  @override
  bool shouldRepaint(covariant _DuaShareCornerPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}
