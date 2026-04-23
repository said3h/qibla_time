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
  static const _bismillah = 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ';

  bool get _shouldShowBismillah => surahNumber != 1 && surahNumber != 9;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 44),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (header != null) ...[
                header!,
                const SizedBox(height: 12),
              ],
              _buildTextBlock(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextBlock() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 30),
      decoration: BoxDecoration(
        color: tokens.bgSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tokens.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_shouldShowBismillah) ...[
            _buildBismillah(),
            const SizedBox(height: 18),
          ],
          Directionality(
            textDirection: TextDirection.rtl,
            child: RichText(
              textAlign: TextAlign.justify,
              textDirection: TextDirection.rtl,
              text: TextSpan(children: _buildSpans()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBismillah() {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Text(
        _bismillah,
        textAlign: TextAlign.center,
        style: GoogleFonts.amiri(
          fontSize: 26,
          height: 1.8,
          color: tokens.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  List<InlineSpan> _buildSpans() {
    final spans = <InlineSpan>[];

    for (final ayah in ayahs) {
      spans.add(
        TextSpan(
          text: ayah.arabic,
          style: GoogleFonts.amiri(
            fontSize: 27,
            height: 2.15,
            color: tokens.textPrimary,
          ),
        ),
      );

      spans.add(
        TextSpan(
          text: '  ﴿${ayah.numberInSurah}﴾  ',
          style: GoogleFonts.amiri(
            fontSize: 17,
            height: 2.15,
            color: tokens.primary.withOpacity(0.92),
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return spans;
  }
}
