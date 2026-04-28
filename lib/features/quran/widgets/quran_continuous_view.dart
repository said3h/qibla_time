import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../models/quran_models.dart';
import 'tajweed_text.dart';

/// Renders a surah as a single flowing Arabic text block, similar to Mushaf
/// page layout. Each ayah ends with an inline number marker ﴿N﴾.
class QuranContinuousView extends StatefulWidget {
  const QuranContinuousView({
    super.key,
    required this.tokens,
    required this.ayahs,
    required this.surahNumber,
    this.currentAyahIndex,
    this.showTajweed = false,
    this.header,
  });

  final QiblaTokens tokens;
  final List<SurahAyah> ayahs;
  final int surahNumber;
  final int? currentAyahIndex;
  final bool showTajweed;

  /// Optional header widget rendered above the Arabic text (e.g. the top
  /// banner and audio card from QuranDetailScreen).
  final Widget? header;

  @override
  State<QuranContinuousView> createState() => _QuranContinuousViewState();
}

class _QuranContinuousViewState extends State<QuranContinuousView> {
  final ScrollController _scrollController = ScrollController();
  int? _lastAutoScrolledAyahIndex;

  // The Bismillah text used as a visual separator before surah content.
  // Surah 1 already has it as ayah 1; surah 9 has none by tradition.
  static const _bismillah = 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ';

  bool get _shouldShowBismillah =>
      widget.surahNumber != 1 && widget.surahNumber != 9;

  @override
  void initState() {
    super.initState();
    _scheduleAutoScroll();
  }

  @override
  void didUpdateWidget(covariant QuranContinuousView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentAyahIndex != widget.currentAyahIndex ||
        oldWidget.ayahs.length != widget.ayahs.length) {
      _scheduleAutoScroll();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scheduleAutoScroll() {
    final currentAyahIndex = widget.currentAyahIndex;
    if (currentAyahIndex == null ||
        currentAyahIndex < 0 ||
        currentAyahIndex >= widget.ayahs.length ||
        currentAyahIndex == _lastAutoScrolledAyahIndex) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final maxScrollExtent = _scrollController.position.maxScrollExtent;
      if (maxScrollExtent <= 0) return;

      _lastAutoScrolledAyahIndex = currentAyahIndex;
      final targetFraction = _estimatedReadingFraction(currentAyahIndex);
      final targetOffset = (maxScrollExtent * targetFraction)
          .clamp(0.0, maxScrollExtent)
          .toDouble();

      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    });
  }

  double _estimatedReadingFraction(int currentAyahIndex) {
    var totalWeight = 0;
    var beforeWeight = 0;

    for (var index = 0; index < widget.ayahs.length; index++) {
      final ayah = widget.ayahs[index];
      final weight = ayah.arabic.length + ayah.numberInSurah.toString().length;
      totalWeight += weight;
      if (index < currentAyahIndex) {
        beforeWeight += weight;
      }
    }

    if (totalWeight <= 0) return 0;

    final activeWeight = widget.ayahs[currentAyahIndex].arabic.length;
    final centeredWeight = beforeWeight + (activeWeight * 0.35);
    final fraction = centeredWeight / totalWeight;
    return (fraction - 0.08).clamp(0.0, 1.0).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 44),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.header != null) ...[
                widget.header!,
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
        color: widget.tokens.bgSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: widget.tokens.border),
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
          color: widget.tokens.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  List<InlineSpan> _buildSpans() {
    final spans = <InlineSpan>[];

    for (var index = 0; index < widget.ayahs.length; index++) {
      final ayah = widget.ayahs[index];
      final isActiveAyah = widget.currentAyahIndex == index;
      final activeBackground =
          isActiveAyah ? widget.tokens.primary.withOpacity(0.13) : null;

      final ayahStyle = GoogleFonts.amiri(
        fontSize: 27,
        height: 2.15,
        color: widget.tokens.textPrimary,
        backgroundColor: activeBackground,
        fontWeight: isActiveAyah ? FontWeight.w700 : FontWeight.w400,
      );
      if (widget.showTajweed && ayah.tajweedHtml.trim().isNotEmpty) {
        spans.addAll(
          TajweedText.buildSpans(
            html: ayah.tajweedHtml,
            baseStyle: ayahStyle,
            plainText: ayah.arabic,
          ),
        );
      } else {
        spans.add(
          TextSpan(
            text: ayah.arabic,
            style: ayahStyle,
          ),
        );
      }

      spans.add(
        TextSpan(
          text: '  ﴿${ayah.numberInSurah}﴾  ',
          style: GoogleFonts.amiri(
            fontSize: 17,
            height: 2.15,
            color: widget.tokens.primary.withOpacity(isActiveAyah ? 1 : 0.92),
            backgroundColor: activeBackground,
            fontWeight: isActiveAyah ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      );
    }

    return spans;
  }
}
