import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../models/tafsir_entry.dart';
import '../providers/tafsir_provider.dart';

class TafsirDebugScreen extends ConsumerStatefulWidget {
  const TafsirDebugScreen({super.key});

  static const routeName = '/debug/tafsir';

  @override
  ConsumerState<TafsirDebugScreen> createState() => _TafsirDebugScreenState();
}

class _TafsirDebugScreenState extends ConsumerState<TafsirDebugScreen> {
  final _surahController = TextEditingController(text: '2');
  final _ayahController = TextEditingController(text: '255');
  final _tafsirIdController = TextEditingController(text: '169');
  final _languageController = TextEditingController(text: 'es');

  TafsirRequest? _request;

  @override
  void dispose() {
    _surahController.dispose();
    _ayahController.dispose();
    _tafsirIdController.dispose();
    _languageController.dispose();
    super.dispose();
  }

  void _runLookup() {
    final surahNumber = int.tryParse(_surahController.text.trim());
    final ayahNumber = int.tryParse(_ayahController.text.trim());
    final tafsirId = _tafsirIdController.text.trim();
    final languageCode = _languageController.text.trim();

    if (surahNumber == null || ayahNumber == null) {
      setState(() {
        _request = null;
      });
      return;
    }

    setState(() {
      _request = TafsirRequest(
        surahNumber: surahNumber,
        ayahNumber: ayahNumber,
        languageCode: languageCode.isEmpty ? 'es' : languageCode,
        tafsirId: tafsirId.isEmpty ? null : tafsirId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;
    final request = _request;

    return Scaffold(
      backgroundColor: tokens.bgPage,
      appBar: AppBar(
        backgroundColor: tokens.bgApp,
        foregroundColor: tokens.textPrimary,
        elevation: 0,
        title: Text(
          'Tafsir Debug',
          style: GoogleFonts.dmSans(
            fontWeight: FontWeight.w700,
            color: tokens.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _DebugNotice(tokens: tokens),
            const SizedBox(height: 18),
            _InputCard(
              tokens: tokens,
              surahController: _surahController,
              ayahController: _ayahController,
              tafsirIdController: _tafsirIdController,
              languageController: _languageController,
              onRun: _runLookup,
            ),
            const SizedBox(height: 18),
            if (request == null)
              _EmptyState(tokens: tokens)
            else
              _TafsirResultCard(
                tokens: tokens,
                request: request,
              ),
          ],
        ),
      ),
    );
  }
}

class _DebugNotice extends StatelessWidget {
  const _DebugNotice({required this.tokens});

  final QiblaTokens tokens;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      tokens: tokens,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.science_rounded, color: tokens.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Temporary isolated screen for tafsir provider testing. '
              'TODO: connect only after source rights, API configuration, '
              'cache policy, and Quran reader UX are approved.',
              style: GoogleFonts.dmSans(
                color: tokens.textSecondary,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InputCard extends StatelessWidget {
  const _InputCard({
    required this.tokens,
    required this.surahController,
    required this.ayahController,
    required this.tafsirIdController,
    required this.languageController,
    required this.onRun,
  });

  final QiblaTokens tokens;
  final TextEditingController surahController;
  final TextEditingController ayahController;
  final TextEditingController tafsirIdController;
  final TextEditingController languageController;
  final VoidCallback onRun;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      tokens: tokens,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Manual lookup',
            style: GoogleFonts.dmSans(
              color: tokens.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _DebugTextField(
                  tokens: tokens,
                  controller: surahController,
                  label: 'Surah',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DebugTextField(
                  tokens: tokens,
                  controller: ayahController,
                  label: 'Ayah',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _DebugTextField(
                  tokens: tokens,
                  controller: tafsirIdController,
                  label: 'Tafsir ID',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DebugTextField(
                  tokens: tokens,
                  controller: languageController,
                  label: 'Lang',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRun,
            icon: const Icon(Icons.search_rounded),
            label: const Text('Load tafsir'),
            style: FilledButton.styleFrom(
              backgroundColor: tokens.primary,
              foregroundColor: _foregroundFor(tokens.primary),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TafsirResultCard extends ConsumerWidget {
  const _TafsirResultCard({
    required this.tokens,
    required this.request,
  });

  final QiblaTokens tokens;
  final TafsirRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultAsync = ref.watch(tafsirEntryProvider(request));

    return resultAsync.when(
      loading: () => _StateCard(
        tokens: tokens,
        icon: Icons.hourglass_top_rounded,
        title: 'Loading tafsir',
        message: 'Checking the configured tafsir source.',
      ),
      error: (_, __) => _StateCard(
        tokens: tokens,
        icon: Icons.info_outline_rounded,
        title: 'Tafsir unavailable',
        message: 'The tafsir could not be loaded safely.',
        isError: true,
      ),
      data: (result) {
        if (result.hasEntry) {
          return _SuccessCard(
            tokens: tokens,
            result: result,
          );
        }

        return _StateCard(
          tokens: tokens,
          icon: Icons.info_outline_rounded,
          title: 'No tafsir available',
          message: _safeMessageFor(result),
          source: _sourceLabel(result.source),
          isError: result.errorCode != null,
        );
      },
    );
  }

  String _safeMessageFor(TafsirLoadResult result) {
    return switch (result.errorCode) {
      'tafsir_not_configured' =>
        'No tafsir source is configured for this isolated test yet.',
      'missing_tafsir_id' => 'Enter a numeric tafsir resource ID to test.',
      'invalid_ayah_reference' => 'Check the surah and ayah numbers.',
      'empty_tafsir_text' => 'The response did not contain usable tafsir text.',
      'invalid_tafsir_text' =>
        'The response was rejected because it was not safe to display.',
      'invalid_verse_alignment' =>
        'The response did not match the requested ayah.',
      _ => 'Tafsir is not available for this request yet.',
    };
  }
}

class _SuccessCard extends StatelessWidget {
  const _SuccessCard({
    required this.tokens,
    required this.result,
  });

  final QiblaTokens tokens;
  final TafsirLoadResult result;

  @override
  Widget build(BuildContext context) {
    final entry = result.entry!;

    return _SurfaceCard(
      tokens: tokens,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StatusPill(
            tokens: tokens,
            label: 'Source: ${_sourceLabel(result.source)}',
            icon: Icons.check_circle_rounded,
          ),
          const SizedBox(height: 16),
          Text(
            '${entry.resourceName} • ${entry.verseKey}',
            style: GoogleFonts.dmSans(
              color: tokens.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            entry.text,
            style: GoogleFonts.dmSans(
              color: tokens.textSecondary,
              height: 1.55,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.tokens});

  final QiblaTokens tokens;

  @override
  Widget build(BuildContext context) {
    return _StateCard(
      tokens: tokens,
      icon: Icons.menu_book_rounded,
      title: 'Ready to test',
      message: 'Enter surah, ayah, and tafsir ID, then load tafsir.',
    );
  }
}

class _StateCard extends StatelessWidget {
  const _StateCard({
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

    return _SurfaceCard(
      tokens: tokens,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 30),
          const SizedBox(height: 14),
          Text(
            title,
            style: GoogleFonts.dmSans(
              color: tokens.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: GoogleFonts.dmSans(
              color: tokens.textSecondary,
              height: 1.45,
            ),
          ),
          if (source != null) ...[
            const SizedBox(height: 14),
            _StatusPill(
              tokens: tokens,
              label: 'Source: $source',
              icon: Icons.route_rounded,
            ),
          ],
        ],
      ),
    );
  }
}

class _DebugTextField extends StatelessWidget {
  const _DebugTextField({
    required this.tokens,
    required this.controller,
    required this.label,
    this.keyboardType,
  });

  final QiblaTokens tokens;
  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.dmSans(
        color: tokens.textPrimary,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.dmSans(color: tokens.textMuted),
        filled: true,
        fillColor: tokens.bgSurface2,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: tokens.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: tokens.primaryBorder),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.tokens,
    required this.label,
    required this.icon,
  });

  final QiblaTokens tokens;
  final String label;
  final IconData icon;

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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: tokens.primary),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.dmSans(
                  color: tokens.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({
    required this.tokens,
    required this.child,
  });

  final QiblaTokens tokens;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.bgSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: tokens.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: child,
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

Color _foregroundFor(Color color) {
  return ThemeData.estimateBrightnessForColor(color) == Brightness.dark
      ? Colors.white
      : Colors.black;
}
