import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../models/tafsir_entry.dart';
import '../providers/tafsir_provider.dart';

const _isTafsirInternalBuild =
    bool.fromEnvironment('QIBLA_INTERNAL_TAFSIR_BUILD');
const _tafsirPreviewLimit = 520;

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
        color: tokens.bgSurface2,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: tokens.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                        'Tafsir de la aleya',
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
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
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
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: resultAsync.when(
        loading: () => _PanelStateMessage(
          tokens: tokens,
          icon: Icons.hourglass_top_rounded,
          title: 'Cargando tafsir',
          message: 'Buscando la explicacion de esta aleya.',
        ),
        error: (_, __) => _PanelStateMessage(
          tokens: tokens,
          icon: Icons.info_outline_rounded,
          title: 'Tafsir no disponible',
          message: 'No se pudo cargar la explicacion ahora.',
          isError: true,
        ),
        data: (result) {
          if (!result.hasEntry) {
            return _PanelStateMessage(
              tokens: tokens,
              icon: Icons.info_outline_rounded,
              title: 'Tafsir no disponible',
              message: _safeMessageFor(result.errorCode),
              source: _shouldShowInternalDetails
                  ? _sourceLabel(result.source)
                  : null,
              debugInfo: result.debugInfo,
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
        'Todavia no hay una fuente de tafsir disponible para esta aleya.',
      'missing_tafsir_id' => 'No hay tafsir disponible para este idioma.',
      'invalid_ayah_reference' => 'No hay tafsir disponible para esta aleya.',
      'empty_tafsir_text' => 'No hay tafsir disponible para esta aleya.',
      'invalid_tafsir_text' => 'No hay tafsir disponible para esta aleya.',
      'invalid_verse_alignment' => 'No hay tafsir disponible para esta aleya.',
      _ => 'No hay tafsir disponible para esta aleya.',
    };
  }
}

class _PanelSuccess extends StatefulWidget {
  const _PanelSuccess({
    required this.tokens,
    required this.result,
  });

  final QiblaTokens tokens;
  final TafsirLoadResult result;

  @override
  State<_PanelSuccess> createState() => _PanelSuccessState();
}

class _PanelSuccessState extends State<_PanelSuccess> {
  bool _showFullText = false;

  @override
  Widget build(BuildContext context) {
    final tokens = widget.tokens;
    final result = widget.result;
    final entry = result.entry!;
    final text = entry.text.trim();
    final isLong = text.length > _tafsirPreviewLimit;
    final visibleText = isLong && !_showFullText
        ? '${text.substring(0, _tafsirPreviewLimit).trimRight()}...'
        : text;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.bgSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tokens.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              visibleText,
              style: GoogleFonts.dmSans(
                color: tokens.textSecondary,
                height: 1.56,
                fontSize: 14,
              ),
            ),
            if (isLong) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () =>
                      setState(() => _showFullText = !_showFullText),
                  icon: Icon(
                    _showFullText
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                  ),
                  label: Text(_showFullText ? 'Mostrar menos' : 'Leer mas'),
                  style: TextButton.styleFrom(
                    foregroundColor: tokens.primary,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 34),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
            if (_shouldShowInternalDetails) ...[
              const SizedBox(height: 10),
              _SourcePill(
                tokens: tokens,
                label: 'Source: ${_sourceLabel(result.source)}',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

bool get _shouldShowInternalDetails => kDebugMode || _isTafsirInternalBuild;

class _PanelStateMessage extends StatelessWidget {
  const _PanelStateMessage({
    required this.tokens,
    required this.icon,
    required this.title,
    required this.message,
    this.source,
    this.debugInfo,
    this.isError = false,
  });

  final QiblaTokens tokens;
  final IconData icon;
  final String title;
  final String message;
  final String? source;
  final TafsirDebugInfo? debugInfo;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final accent = isError ? tokens.danger : tokens.primary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 6, 2, 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 19),
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
                const SizedBox(height: 3),
                Text(
                  message,
                  style: GoogleFonts.dmSans(
                    color: tokens.textSecondary,
                    height: 1.35,
                    fontSize: 13,
                  ),
                ),
                if (source != null) ...[
                  const SizedBox(height: 8),
                  _SourcePill(
                    tokens: tokens,
                    label: 'Source: $source',
                  ),
                ],
                if (_shouldShowInternalDetails && debugInfo != null) ...[
                  const SizedBox(height: 8),
                  _DebugInfoBox(
                    tokens: tokens,
                    debugInfo: debugInfo!,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DebugInfoBox extends StatelessWidget {
  const _DebugInfoBox({
    required this.tokens,
    required this.debugInfo,
  });

  final QiblaTokens tokens;
  final TafsirDebugInfo debugInfo;

  @override
  Widget build(BuildContext context) {
    final rows = [
      'provider: ${debugInfo.provider ?? 'unknown'}',
      'resourceId: ${debugInfo.resourceId ?? 'unknown'}',
      'url: ${debugInfo.url ?? 'none'}',
      'statusCode: ${debugInfo.statusCode?.toString() ?? 'none'}',
      'fallback: ${debugInfo.fallbackReason}',
      'html: ${debugInfo.receivedHtml ? '${debugInfo.htmlLength} chars' : 'none'}',
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Debug info',
              style: GoogleFonts.dmSans(
                color: tokens.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 6),
            for (final row in rows)
              Text(
                row,
                style: GoogleFonts.dmSans(
                  color: tokens.textSecondary,
                  height: 1.35,
                  fontSize: 10,
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
