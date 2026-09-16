import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../models/dua_model.dart';
import '../utils/dua_locale_presentation.dart';

/// Each repetition label belongs to one part, never to the whole sequence.
class DuaPartsContent extends StatelessWidget {
  const DuaPartsContent(
      {super.key,
      required this.parts,
      required this.tokens,
      required this.languageCode,
      this.arabicFontSize = 19});

  final List<DuaPart> parts;
  final QiblaTokens tokens;
  final String languageCode;
  final double arabicFontSize;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < parts.length; i++) ...[
            if (i > 0) const SizedBox(height: 16),
            Text(
                DuaLocalePresentation.repeatCountLabel(
                    languageCode, parts[i].count),
                style: TextStyle(color: tokens.primary, fontSize: 11)),
            const SizedBox(height: 4),
            Text(parts[i].arabicText,
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                style: tokens.arabicTextStyle(
                    fontSize: arabicFontSize, height: 1.9)),
            if (languageCode != 'ar' &&
                parts[i].transliteration.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(parts[i].transliteration,
                  style: tokens.transliterationTextStyle(
                      fontSize: 11, height: 1.6)),
            ],
            if (languageCode != 'ar' && parts[i].translation.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(parts[i].translation,
                  style: TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 12,
                      color: tokens.textPrimary,
                      height: 1.7)),
            ],
          ],
        ],
      );
}
