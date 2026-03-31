import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';

enum SharePreviewLayoutOption { card, story }

enum SharePreviewContentOption { bilingual, arabicOnly, translationOnly }

extension SharePreviewContentOptionX on SharePreviewContentOption {
  bool isAvailable({
    required bool hasArabic,
    required bool hasTranslation,
  }) {
    switch (this) {
      case SharePreviewContentOption.bilingual:
        return hasArabic && hasTranslation;
      case SharePreviewContentOption.arabicOnly:
        return hasArabic;
      case SharePreviewContentOption.translationOnly:
        return hasTranslation;
    }
  }

  bool includeArabic(bool hasArabic) =>
      this != SharePreviewContentOption.translationOnly && hasArabic;

  bool includeTranslation(bool hasTranslation) =>
      this != SharePreviewContentOption.arabicOnly && hasTranslation;
}

class SharePreviewBottomSheet extends StatelessWidget {
  const SharePreviewBottomSheet({
    super.key,
    required this.tokens,
    required this.title,
    required this.subtitle,
    required this.preview,
    required this.sections,
    required this.footer,
  });

  final QiblaTokens tokens;
  final String title;
  final String subtitle;
  final Widget preview;
  final List<Widget> sections;
  final Widget footer;

  @override
  Widget build(BuildContext context) {
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
                                title,
                                style: GoogleFonts.dmSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: tokens.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                subtitle,
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
                    SharePreviewCanvas(
                      tokens: tokens,
                      height: previewHeight,
                      child: preview,
                    ),
                    for (final section in sections) ...[
                      const SizedBox(height: 16),
                      section,
                    ],
                    const SizedBox(height: 24),
                    footer,
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

class SharePreviewCanvas extends StatelessWidget {
  const SharePreviewCanvas({
    super.key,
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

class ShareOptionSection extends StatelessWidget {
  const ShareOptionSection({
    super.key,
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

class ShareSelectionChip extends StatelessWidget {
  const ShareSelectionChip({
    super.key,
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
