import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../hadith/models/hadith.dart';
import '../../hadith/services/hadith_share_service.dart';
import '../../hadith_share/models/hadith_share_data.dart';
import '../../hadith_share/models/hadith_share_theme.dart';
import '../../hadith_share/services/hadith_share_image_service.dart';
import '../../hadith_share/widgets/hadith_share_preview.dart';

Future<void> showHadithSharePreviewSheet({
  required BuildContext context,
  required Hadith hadith,
  required HadithShareService shareService,
  required QiblaTokens tokens,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => FractionallySizedBox(
      heightFactor: 0.94,
      child: _HadithSharePreviewSheet(
        hadith: hadith,
        shareService: shareService,
        tokens: tokens,
      ),
    ),
  );
}

enum _HadithShareLayoutOption { card, story }

enum _HadithShareContentOption { bilingual, arabicOnly, translationOnly }

class _HadithSharePreviewSheet extends StatefulWidget {
  const _HadithSharePreviewSheet({
    required this.hadith,
    required this.shareService,
    required this.tokens,
  });

  final Hadith hadith;
  final HadithShareService shareService;
  final QiblaTokens tokens;

  @override
  State<_HadithSharePreviewSheet> createState() =>
      _HadithSharePreviewSheetState();
}

class _HadithSharePreviewSheetState extends State<_HadithSharePreviewSheet> {
  _HadithShareLayoutOption _selectedLayout = _HadithShareLayoutOption.card;
  late _HadithShareContentOption _selectedContent;
  bool _isSharing = false;

  bool get _hasArabicText => widget.hadith.arabic.trim().isNotEmpty;

  bool get _hasTranslation => widget.hadith.translation.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _selectedContent = _defaultContentOption();
  }

  _HadithShareContentOption _defaultContentOption() {
    if (_hasArabicText && _hasTranslation) {
      return _HadithShareContentOption.bilingual;
    }
    if (_hasArabicText) {
      return _HadithShareContentOption.arabicOnly;
    }
    return _HadithShareContentOption.translationOnly;
  }

  bool _canUseContentOption(_HadithShareContentOption option) {
    switch (option) {
      case _HadithShareContentOption.bilingual:
        return _hasArabicText && _hasTranslation;
      case _HadithShareContentOption.arabicOnly:
        return _hasArabicText;
      case _HadithShareContentOption.translationOnly:
        return _hasTranslation;
    }
  }

  bool get _includeArabic =>
      _selectedContent != _HadithShareContentOption.translationOnly &&
      _hasArabicText;

  bool get _includeTranslation =>
      _selectedContent != _HadithShareContentOption.arabicOnly &&
      _hasTranslation;

  HadithShareExportMode get _exportMode =>
      _selectedLayout == _HadithShareLayoutOption.card
          ? HadithShareExportMode.cardOnly
          : HadithShareExportMode.storyCanvas;

  HadithShareThemeData get _previewTheme => HadithShareThemeData.fromTokens(
        widget.tokens,
        transparentBackground:
            _selectedLayout == _HadithShareLayoutOption.card,
      );

  HadithShareData get _previewData => HadithShareData(
        arabicText: _includeArabic ? widget.hadith.arabic : null,
        translation: _includeTranslation ? widget.hadith.translation : '',
        reference: widget.hadith.reference,
        branding: 'App: Qibla Time',
      );

  Future<void> _shareImage() async {
    if (_isSharing || (!_includeArabic && !_includeTranslation)) {
      return;
    }

    setState(() => _isSharing = true);

    try {
      await widget.shareService.shareHadithAsImage(
        widget.hadith,
        widget.tokens,
        mode: _exportMode,
        includeArabic: _includeArabic,
        includeTranslation: _includeTranslation,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo generar la imagen del hadiz ahora mismo.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = widget.tokens;
    final previewHeight = (MediaQuery.sizeOf(context).height * 0.4)
        .clamp(280.0, 420.0)
        .toDouble();

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: tokens.bgPage,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: tokens.borderMed,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Preview de imagen',
                                style: GoogleFonts.dmSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: tokens.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Elige layout y contenido antes de compartir.',
                                style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  color: tokens.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                          tooltip: 'Cerrar',
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _PreviewCanvas(
                      tokens: tokens,
                      height: previewHeight,
                      child: HadithSharePreview(
                        data: _previewData,
                        theme: _previewTheme,
                        cardOnly:
                            _selectedLayout == _HadithShareLayoutOption.card,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _OptionSection(
                      title: 'Estilo / fondo',
                      children: [
                        _SelectionChip(
                          label: 'Card',
                          selected:
                              _selectedLayout == _HadithShareLayoutOption.card,
                          onSelected: () {
                            setState(() {
                              _selectedLayout = _HadithShareLayoutOption.card;
                            });
                          },
                        ),
                        _SelectionChip(
                          label: 'Story',
                          selected:
                              _selectedLayout == _HadithShareLayoutOption.story,
                          onSelected: () {
                            setState(() {
                              _selectedLayout = _HadithShareLayoutOption.story;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _OptionSection(
                      title: 'Contenido',
                      children: [
                        _SelectionChip(
                          label: 'Árabe + traducción',
                          selected: _selectedContent ==
                              _HadithShareContentOption.bilingual,
                          enabled: _canUseContentOption(
                            _HadithShareContentOption.bilingual,
                          ),
                          onSelected: () {
                            setState(() {
                              _selectedContent =
                                  _HadithShareContentOption.bilingual;
                            });
                          },
                        ),
                        _SelectionChip(
                          label: 'Solo árabe',
                          selected: _selectedContent ==
                              _HadithShareContentOption.arabicOnly,
                          enabled: _canUseContentOption(
                            _HadithShareContentOption.arabicOnly,
                          ),
                          onSelected: () {
                            setState(() {
                              _selectedContent =
                                  _HadithShareContentOption.arabicOnly;
                            });
                          },
                        ),
                        _SelectionChip(
                          label: 'Solo traducción',
                          selected: _selectedContent ==
                              _HadithShareContentOption.translationOnly,
                          enabled: _canUseContentOption(
                            _HadithShareContentOption.translationOnly,
                          ),
                          onSelected: () {
                            setState(() {
                              _selectedContent =
                                  _HadithShareContentOption.translationOnly;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSharing || (!_includeArabic && !_includeTranslation)
                            ? null
                            : _shareImage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: tokens.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isSharing
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  valueColor: const AlwaysStoppedAnimation(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(
                                'Compartir imagen',
                                style: GoogleFonts.dmSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewCanvas extends StatelessWidget {
  const _PreviewCanvas({
    required this.tokens,
    required this.height,
    required this.child,
  });

  final QiblaTokens tokens;
  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.bgSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: tokens.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: tokens.bgPage,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.contain,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionSection extends StatelessWidget {
  const _OptionSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: tokens.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: children,
        ),
      ],
    );
  }
}

class _SelectionChip extends StatelessWidget {
  const _SelectionChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    this.enabled = true,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: enabled ? (_) => onSelected() : null,
      backgroundColor: tokens.bgSurface,
      disabledColor: tokens.bgSurface.withOpacity(0.65),
      selectedColor: tokens.primary.withOpacity(0.14),
      side: BorderSide(
        color: selected ? tokens.primary : tokens.border,
      ),
      labelStyle: GoogleFonts.dmSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: enabled
            ? (selected ? tokens.primary : tokens.textPrimary)
            : tokens.textMuted,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    );
  }
}
