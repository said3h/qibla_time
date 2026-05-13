import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../models/tafsir_entry.dart';
import '../providers/tafsir_provider.dart';

class TafsirPanel extends ConsumerStatefulWidget {
  const TafsirPanel({
    super.key,
    required this.surahNumber,
    required this.ayahNumber,
    required this.languageCode,
    this.tafsirId,
    this.initiallyExpanded = false,
  });

  final int surahNumber;
  final int ayahNumber;
  final String languageCode;
  final String? tafsirId;
  final bool initiallyExpanded;

  @override
  ConsumerState<TafsirPanel> createState() => _TafsirPanelState();
}

class _TafsirPanelState extends ConsumerState<TafsirPanel> {
  late bool _expanded = widget.initiallyExpanded;

  TafsirRequest get _request {
    return TafsirRequest(
      surahNumber: widget.surahNumber,
      ayahNumber: widget.ayahNumber,
      languageCode: widget.languageCode,
      tafsirId: widget.tafsirId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.bgSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: tokens.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(
                      Icons.menu_book_rounded,
                      color: tokens.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Tafsir',
                        style: GoogleFonts.dmSans(
                          color: tokens.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 180),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: tokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: _expanded
                  ? _TafsirPanelBody(
                      key: const ValueKey('tafsir-panel-body'),
                      tokens: tokens,
                      request: _request,
                    )
                  : const SizedBox.shrink(
                      key: ValueKey('tafsir-panel-collapsed'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TafsirPanelBody extends ConsumerWidget {
  const _TafsirPanelBody({
    super.key,
    required this.tokens,
    required this.request,
  });

  final QiblaTokens tokens;
  final TafsirRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultAsync = ref.watch(tafsirEntryProvider(request));

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: resultAsync.when(
        loading: () => _PanelStateMessage(
          tokens: tokens,
          icon: Icons.hourglass_top_rounded,
          title: 'Loading tafsir',
          message: 'Checking the tafsir source.',
        ),
        error: (_, __) => _PanelStateMessage(
          tokens: tokens,
          icon: Icons.info_outline_rounded,
          title: 'Tafsir unavailable',
          message: 'The tafsir could not be loaded safely.',
          isError: true,
        ),
        data: (result) {
          if (!result.hasEntry) {
            return _PanelStateMessage(
              tokens: tokens,
              icon: Icons.info_outline_rounded,
              title: 'No tafsir available',
              message: _safeMessageFor(result.errorCode),
              source: _sourceLabel(result.source),
              isError: result.errorCode != null,
            );
          }

          return _PanelSuccess(
            tokens: tokens,
            result: result,
          );
        },
      ),
    );
  }

  String _safeMessageFor(String? errorCode) {
    return switch (errorCode) {
      'tafsir_not_configured' =>
        'No tafsir source is configured for this ayah yet.',
      'missing_tafsir_id' => 'No tafsir resource is selected yet.',
      'invalid_ayah_reference' => 'The ayah reference is not valid.',
      'empty_tafsir_text' => 'No usable tafsir text was found.',
      'invalid_tafsir_text' => 'The tafsir response was rejected for safety.',
      'invalid_verse_alignment' =>
        'The tafsir response did not match this ayah.',
      _ => 'Tafsir is not available for this ayah yet.',
    };
  }
}

class _PanelSuccess extends StatelessWidget {
  const _PanelSuccess({
    required this.tokens,
    required this.result,
  });

  final QiblaTokens tokens;
  final TafsirLoadResult result;

  @override
  Widget build(BuildContext context) {
    final entry = result.entry!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SourcePill(
          tokens: tokens,
          label: 'Source: ${_sourceLabel(result.source)}',
        ),
        const SizedBox(height: 12),
        Text(
          entry.resourceName,
          style: GoogleFonts.dmSans(
            color: tokens.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          entry.text,
          style: GoogleFonts.dmSans(
            color: tokens.textSecondary,
            height: 1.55,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _PanelStateMessage extends StatelessWidget {
  const _PanelStateMessage({
    required this.tokens,
    required this.icon,
    required this.title,
    required this.message,
    this.source,
    this.isError = false,
  });

  final QiblaTokens tokens;
  final IconData icon;
  final String title;
  final String message;
  final String? source;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final accent = isError ? tokens.danger : tokens.primary;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.bgSurface2,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tokens.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: accent, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.dmSans(
                      color: tokens.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: GoogleFonts.dmSans(
                      color: tokens.textSecondary,
                      height: 1.4,
                      fontSize: 13,
                    ),
                  ),
                  if (source != null) ...[
                    const SizedBox(height: 10),
                    _SourcePill(
                      tokens: tokens,
                      label: 'Source: $source',
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SourcePill extends StatelessWidget {
  const _SourcePill({
    required this.tokens,
    required this.label,
  });

  final QiblaTokens tokens;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tokens.primaryBg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: tokens.primaryBorder),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(
            label,
            style: GoogleFonts.dmSans(
              color: tokens.primary,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }
}

String _sourceLabel(TafsirLoadSource source) {
  return switch (source) {
    TafsirLoadSource.api => 'api',
    TafsirLoadSource.cache => 'cache',
    TafsirLoadSource.offline => 'offline',
    TafsirLoadSource.online => 'online',
    TafsirLoadSource.unavailable => 'fallback',
  };
}
