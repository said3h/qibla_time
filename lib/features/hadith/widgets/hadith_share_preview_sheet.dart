import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/l10n.dart';
import '../../hadith/models/hadith.dart';
import '../../hadith/services/hadith_share_service.dart';
import '../../hadith_share/models/hadith_share_data.dart';
import '../../hadith_share/models/hadith_share_theme.dart';
import '../../hadith_share/services/hadith_share_image_service.dart';
import '../../hadith_share/widgets/hadith_share_preview.dart';
import '../../shared_share/widgets/content_share_preview_sheet.dart';

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

enum _HadithShareAction { text, image }

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
  SharePreviewLayoutOption _selectedLayout = SharePreviewLayoutOption.card;
  late SharePreviewContentOption _selectedContent;
  _HadithShareAction? _activeAction;

  bool get _hasArabicText => widget.hadith.arabic.trim().isNotEmpty;

  bool get _hasTranslation => widget.hadith.translation.trim().isNotEmpty;

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

  HadithShareData get _previewData => widget.shareService.buildShareData(
        widget.hadith,
        includeArabic: _includeArabic,
        includeTranslation: _includeTranslation,
      );

  Future<void> _shareText() async {
    if (_isBusy || (!_includeArabic && !_includeTranslation)) {
      return;
    }

    setState(() => _activeAction = _HadithShareAction.text);

    try {
      await widget.shareService.shareHadithAsText(
        widget.hadith,
        includeArabic: _includeArabic,
        includeTranslation: _includeTranslation,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.shareHadithTextError),
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

    setState(() => _activeAction = _HadithShareAction.image);

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
        SnackBar(
          content: Text(context.l10n.shareHadithImageError),
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

    return SharePreviewBottomSheet(
      tokens: tokens,
      title: l10n.shareHadithTitle,
      subtitle: l10n.shareHadithSubtitle,
      preview: HadithSharePreview(
        data: _previewData,
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
      footer: _ShareFooter(
        tokens: tokens,
        isBusy: _isBusy,
        onShareText: _shareText,
        onShareImage: _shareImage,
        activeAction: _activeAction,
      ),
    );
  }
}

class _ShareFooter extends StatelessWidget {
  const _ShareFooter({
    required this.tokens,
    required this.isBusy,
    required this.onShareText,
    required this.onShareImage,
    required this.activeAction,
  });

  final QiblaTokens tokens;
  final bool isBusy;
  final VoidCallback onShareText;
  final VoidCallback onShareImage;
  final _HadithShareAction? activeAction;

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
            child: activeAction == _HadithShareAction.image
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
            child: activeAction == _HadithShareAction.text
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
