import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../models/quran_models.dart';

/// Renders a surah as a single flowing Arabic text block, similar to Mushaf
/// page layout. Each ayah ends with an inline number marker ﴿N﴾.
///
/// This is a pure rendering widget: it does not modify data or manage state.
class QuranContinuousView extends StatelessWidget {
  const QuranContinuousView({
    super.key,
    required this.tokens,
    required this.ayahs,
    required this.surahNumber,
    this.header,
  });

  final QiblaTokens tokens;
  final List<SurahAyah> ayahs;
  final int surahNumber;

  /// Optional header widget rendered above the Arabic text (e.g. the top
  /// banner and audio card from QuranDetailScreen).
  final Widget? header;

  // The Bismillah text used as a visual separator before surah content.
  // Surah 1 already has it as ayah 1; surah 9 has none by tradition.
  static const _bismillah =
      'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (header != null) ...[
            header!,
            const SizedBox(height: 8),
          ],
          _buildTextBlock(),
        ],
      ),
    );
  }

  Widget _buildTextBlock() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
      decoration: BoxDecoration(
        color: tokens.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.border),
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: RichText(
          textAlign: TextAlign.justify,
          textDirection: TextDirection.rtl,
          text: TextSpan(
            children: _buildSpans(),
          ),
        ),
      ),
    );
  }

  List<InlineSpan> _buildSpans() {
    final spans = <InlineSpan>[];

    // Show Bismillah header for every surah except Al-Fatihah (1, whose first
    // ayah IS the Bismillah) and At-Tawbah (9, which has no Bismillah).
    if (surahNumber != 1 && surahNumber != 9) {
      spans.add(
        TextSpan(
          text: '$_bismillah\n\n',
          style: GoogleFonts.amiri(
            fontSize: 22,
            height: 2.2,
            color: tokens.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    for (final ayah in ayahs) {
      // Arabic ayah text
      spans.add(
        TextSpan(
          text: ayah.arabic,
          style: GoogleFonts.amiri(
            fontSize: 26,
            height: 2.2,
            color: tokens.textPrimary,
          ),
        ),
      );

      // Inline ayah number marker ﴿N﴾ — styled smaller and in primary colour
      // to mimic the end-of-verse marker in printed Masahif.
      spans.add(
        TextSpan(
          text: ' ﴿${ayah.numberInSurah}﴾ ',
          style: GoogleFonts.amiri(
            fontSize: 18,
            height: 2.2,
            color: tokens.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return spans;
  }
}
