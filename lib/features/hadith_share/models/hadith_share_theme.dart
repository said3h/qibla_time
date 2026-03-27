import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import 'hadith_share_data.dart';

class HadithShareThemeData {
  const HadithShareThemeData({
    required this.canvasSize,
    required this.cardWidthFactor,
    required this.canvasPadding,
    required this.cardPadding,
    required this.cardRadius,
    required this.cardBackgroundColor,
    required this.canvasBackgroundColor,
    required this.shadowColor,
    required this.accentColor,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    required this.brandingTextColor,
    required this.referenceTextColor,
    required this.dividerColor,
    required this.arabicFontFamily,
    required this.arabicFontSize,
    required this.translationFontSize,
    required this.referenceFontSize,
    required this.brandingFontSize,
    required this.sectionSpacing,
    required this.contentSpacing,
    required this.translationLineHeight,
    required this.arabicLineHeight,
    required this.referenceLineHeight,
  });

  final Size canvasSize;
  final double cardWidthFactor;
  final EdgeInsets canvasPadding;
  final EdgeInsets cardPadding;
  final double cardRadius;
  final Color cardBackgroundColor;
  final Color canvasBackgroundColor;
  final Color shadowColor;
  final Color accentColor;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final Color brandingTextColor;
  final Color referenceTextColor;
  final Color dividerColor;
  final String? arabicFontFamily;
  final double arabicFontSize;
  final double translationFontSize;
  final double referenceFontSize;
  final double brandingFontSize;
  final double sectionSpacing;
  final double contentSpacing;
  final double translationLineHeight;
  final double arabicLineHeight;
  final double referenceLineHeight;

  factory HadithShareThemeData.fromTokens(
    QiblaTokens tokens, {
    bool transparentBackground = true,
    String? arabicFontFamily = 'Amiri',
  }) {
    return HadithShareThemeData(
      canvasSize: const Size(1080, 1920),
      cardWidthFactor: 0.78,
      canvasPadding: const EdgeInsets.symmetric(horizontal: 64, vertical: 88),
      cardPadding: const EdgeInsets.symmetric(horizontal: 64, vertical: 72),
      cardRadius: 42,
      cardBackgroundColor: tokens.bgSurface,
      canvasBackgroundColor: transparentBackground
          ? Colors.transparent
          : tokens.bgPage,
      shadowColor: Colors.black.withOpacity(0.18),
      accentColor: tokens.primary,
      primaryTextColor: tokens.textPrimary,
      secondaryTextColor: tokens.textSecondary,
      brandingTextColor: tokens.textMuted,
      referenceTextColor: tokens.primaryLight,
      dividerColor: tokens.borderMed,
      arabicFontFamily: arabicFontFamily,
      arabicFontSize: 58,
      translationFontSize: 34,
      referenceFontSize: 24,
      brandingFontSize: 22,
      sectionSpacing: 28,
      contentSpacing: 18,
      translationLineHeight: 1.55,
      arabicLineHeight: 1.75,
      referenceLineHeight: 1.35,
    );
  }

  HadithShareThemeData resolveFor(HadithShareData data) {
    final arabicLength = (data.arabicText ?? '').trim().length;
    final translationLength = data.translation.trim().length;
    final referenceLength = data.reference.trim().length;
    final densityScore =
        (arabicLength / 320) + (translationLength / 540) + (referenceLength / 120);

    if (densityScore <= 1.25) {
      return this;
    }

    final compactScale = densityScore > 1.8 ? 0.78 : 0.88;
    double scaledPadding(double original, double minimum) {
      final scaled = original * compactScale;
      if (original <= minimum) {
        return scaled < original ? scaled : original;
      }
      return scaled < minimum ? minimum : scaled;
    }

    return copyWith(
      arabicFontSize: arabicFontSize * compactScale,
      translationFontSize: translationFontSize * compactScale,
      referenceFontSize: referenceFontSize * compactScale,
      brandingFontSize: brandingFontSize * compactScale,
      cardPadding: EdgeInsets.fromLTRB(
        scaledPadding(cardPadding.left, 28.0),
        scaledPadding(cardPadding.top, 32.0),
        scaledPadding(cardPadding.right, 28.0),
        scaledPadding(cardPadding.bottom, 32.0),
      ),
      sectionSpacing: (sectionSpacing * compactScale)
          .clamp(18.0, sectionSpacing)
          .toDouble(),
      contentSpacing: (contentSpacing * compactScale)
          .clamp(12.0, contentSpacing)
          .toDouble(),
    );
  }

  HadithShareThemeData copyWith({
    Size? canvasSize,
    double? cardWidthFactor,
    EdgeInsets? canvasPadding,
    EdgeInsets? cardPadding,
    double? cardRadius,
    Color? cardBackgroundColor,
    Color? canvasBackgroundColor,
    Color? shadowColor,
    Color? accentColor,
    Color? primaryTextColor,
    Color? secondaryTextColor,
    Color? brandingTextColor,
    Color? referenceTextColor,
    Color? dividerColor,
    String? arabicFontFamily,
    double? arabicFontSize,
    double? translationFontSize,
    double? referenceFontSize,
    double? brandingFontSize,
    double? sectionSpacing,
    double? contentSpacing,
    double? translationLineHeight,
    double? arabicLineHeight,
    double? referenceLineHeight,
  }) {
    return HadithShareThemeData(
      canvasSize: canvasSize ?? this.canvasSize,
      cardWidthFactor: cardWidthFactor ?? this.cardWidthFactor,
      canvasPadding: canvasPadding ?? this.canvasPadding,
      cardPadding: cardPadding ?? this.cardPadding,
      cardRadius: cardRadius ?? this.cardRadius,
      cardBackgroundColor: cardBackgroundColor ?? this.cardBackgroundColor,
      canvasBackgroundColor: canvasBackgroundColor ?? this.canvasBackgroundColor,
      shadowColor: shadowColor ?? this.shadowColor,
      accentColor: accentColor ?? this.accentColor,
      primaryTextColor: primaryTextColor ?? this.primaryTextColor,
      secondaryTextColor: secondaryTextColor ?? this.secondaryTextColor,
      brandingTextColor: brandingTextColor ?? this.brandingTextColor,
      referenceTextColor: referenceTextColor ?? this.referenceTextColor,
      dividerColor: dividerColor ?? this.dividerColor,
      arabicFontFamily: arabicFontFamily ?? this.arabicFontFamily,
      arabicFontSize: arabicFontSize ?? this.arabicFontSize,
      translationFontSize: translationFontSize ?? this.translationFontSize,
      referenceFontSize: referenceFontSize ?? this.referenceFontSize,
      brandingFontSize: brandingFontSize ?? this.brandingFontSize,
      sectionSpacing: sectionSpacing ?? this.sectionSpacing,
      contentSpacing: contentSpacing ?? this.contentSpacing,
      translationLineHeight: translationLineHeight ?? this.translationLineHeight,
      arabicLineHeight: arabicLineHeight ?? this.arabicLineHeight,
      referenceLineHeight: referenceLineHeight ?? this.referenceLineHeight,
    );
  }
}
