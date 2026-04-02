import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/l10n.dart';
import '../../hadith_share/models/hadith_share_theme.dart';
import '../../hadith_share/services/hadith_share_image_service.dart';
import '../../hadith_share/widgets/hadith_share_preview.dart';
import '../../shared_share/widgets/content_share_preview_sheet.dart';
import '../models/dua_model.dart';
import '../services/dua_share_service.dart';

Future<void> showDuaSharePreviewSheet({
  required BuildContext context,
  required Dua dua,
  required DuaShareService shareService,
  required QiblaTokens tokens,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => FractionallySizedBox(
      heightFactor: 0.94,
      child: _DuaSharePreviewSheet(
        dua: dua,
        shareService: shareService,
        tokens: tokens,
      ),
    ),
  );
}

enum _DuaShareAction { text, image }

class _DuaSharePreviewSheet extends StatefulWidget {
  const _DuaSharePreviewSheet({
    required this.dua,
    required this.shareService,
    required this.tokens,
  });

  final Dua dua;
  final DuaShareService shareService;
  final QiblaTokens tokens;

  @override
  State<_DuaSharePreviewSheet> createState() => _DuaSharePreviewSheetState();
}

class _DuaSharePreviewSheetState extends State<_DuaSharePreviewSheet> {
  SharePreviewLayoutOption _selectedLayout = SharePreviewLayoutOption.story;
  late SharePreviewContentOption _selectedContent;
  _DuaShareAction? _activeAction;

  bool get _hasArabicText => widget.dua.arabicText.trim().isNotEmpty;

  bool get _hasTranslation => widget.dua.translation.trim().isNotEmpty;

  bool get _isBusy => _activeAction != null;

  @override
  void initState() {
    super.initState();
    _selectedContent = _defaultContentOption();
  }

  SharePreviewContentOption _defaultContentOption() {
    if (_hasArabicText && _hasTranslation) {
      return SharePreviewContentOption.bilingual;
    }
    if (_hasArabicText) {
      return SharePreviewContentOption.arabicOnly;
    }
    return SharePreviewContentOption.translationOnly;
  }

  bool get _includeArabic => _selectedContent.includeArabic(_hasArabicText);

  bool get _includeTranslation =>
      _selectedContent.includeTranslation(_hasTranslation);

  HadithShareExportMode get _exportMode =>
      _selectedLayout == SharePreviewLayoutOption.card
          ? HadithShareExportMode.cardOnly
          : HadithShareExportMode.storyCanvas;

  HadithShareThemeData get _previewTheme => HadithShareThemeData.fromTokens(
        widget.tokens,
        transparentBackground: _selectedLayout == SharePreviewLayoutOption.card,
      );

  Future<void> _shareText() async {
    if (_isBusy || (!_includeArabic && !_includeTranslation)) {
      return;
    }

    setState(() => _activeAction = _DuaShareAction.text);

    try {
      await widget.shareService.shareDuaAsText(
        widget.dua,
        includeArabic: _includeArabic,
        includeTranslation: _includeTranslation,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.shareDuaTextError),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _activeAction = null);
      }
    }
  }

  Future<void> _shareImage() async {
    if (_isBusy || (!_includeArabic && !_includeTranslation)) {
      return;
    }

    setState(() => _activeAction = _DuaShareAction.image);

    try {
      await widget.shareService.shareDuaAsImage(
        widget.dua,
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
        SnackBar(
          content: Text(context.l10n.shareDuaImageError),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _activeAction = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = widget.tokens;
    final l10n = context.l10n;
    final previewData = widget.shareService.buildShareData(
      widget.dua,
      includeArabic: _includeArabic,
      includeTranslation: _includeTranslation,
    );

    return SharePreviewBottomSheet(
      tokens: tokens,
      title: widget.dua.title.trim().isEmpty
          ? l10n.shareDuaTitle
          : l10n.shareDuaTitleNamed(widget.dua.title.trim()),
      subtitle: l10n.shareDuaSubtitle,
      preview: HadithSharePreview(
        data: previewData,
        theme: _previewTheme,
        cardOnly: _selectedLayout == SharePreviewLayoutOption.card,
      ),
      sections: [
        ShareOptionSection(
          title: l10n.shareSectionStyle,
          children: [
            ShareSelectionChip(
              label: l10n.shareLayoutCard,
              selected: _selectedLayout == SharePreviewLayoutOption.card,
              onSelected: () {
                setState(() {
                  _selectedLayout = SharePreviewLayoutOption.card;
                });
              },
            ),
            ShareSelectionChip(
              label: l10n.shareLayoutStory,
              selected: _selectedLayout == SharePreviewLayoutOption.story,
              onSelected: () {
                setState(() {
                  _selectedLayout = SharePreviewLayoutOption.story;
                });
              },
            ),
          ],
        ),
        ShareOptionSection(
          title: l10n.shareSectionContent,
          children: [
            ShareSelectionChip(
              label: l10n.shareContentBilingual,
              selected:
                  _selectedContent == SharePreviewContentOption.bilingual,
              enabled: SharePreviewContentOption.bilingual.isAvailable(
                hasArabic: _hasArabicText,
                hasTranslation: _hasTranslation,
              ),
              onSelected: () {
                setState(() {
                  _selectedContent = SharePreviewContentOption.bilingual;
                });
              },
            ),
            ShareSelectionChip(
              label: l10n.shareContentArabicOnly,
              selected:
                  _selectedContent == SharePreviewContentOption.arabicOnly,
              enabled: SharePreviewContentOption.arabicOnly.isAvailable(
                hasArabic: _hasArabicText,
                hasTranslation: _hasTranslation,
              ),
              onSelected: () {
                setState(() {
                  _selectedContent = SharePreviewContentOption.arabicOnly;
                });
              },
            ),
            ShareSelectionChip(
              label: l10n.shareContentTranslationOnly,
              selected:
                  _selectedContent == SharePreviewContentOption.translationOnly,
              enabled: SharePreviewContentOption.translationOnly.isAvailable(
                hasArabic: _hasArabicText,
                hasTranslation: _hasTranslation,
              ),
              onSelected: () {
                setState(() {
                  _selectedContent = SharePreviewContentOption.translationOnly;
                });
              },
            ),
          ],
        ),
      ],
      footer: _DuaShareFooter(
        tokens: tokens,
        isBusy: _isBusy,
        activeAction: _activeAction,
        onShareText: _shareText,
        onShareImage: _shareImage,
      ),
    );
  }
}

class _DuaShareFooter extends StatelessWidget {
  const _DuaShareFooter({
    required this.tokens,
    required this.isBusy,
    required this.activeAction,
    required this.onShareText,
    required this.onShareImage,
  });

  final QiblaTokens tokens;
  final bool isBusy;
  final _DuaShareAction? activeAction;
  final VoidCallback onShareText;
  final VoidCallback onShareImage;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isBusy ? null : onShareImage,
            style: ElevatedButton.styleFrom(
              backgroundColor: tokens.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: activeAction == _DuaShareAction.image
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : Text(
                    l10n.shareActionShareImage,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: isBusy ? null : onShareText,
            style: OutlinedButton.styleFrom(
              foregroundColor: tokens.textPrimary,
              side: BorderSide(color: tokens.borderMed),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: activeAction == _DuaShareAction.text
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation(tokens.primary),
                    ),
                  )
                : Text(
                    l10n.shareActionShareText,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
