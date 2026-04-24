import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/services/logger_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/l10n.dart';
import '../../quran/models/quran_models.dart';
import '../../shared_share/widgets/content_share_preview_sheet.dart';
import '../models/ayah_share_data.dart';
import '../models/ayah_share_theme.dart';
import '../services/ayah_share_image_service.dart';
import '../services/ayah_share_service.dart';
import '../services/ayah_share_video_service.dart';
import '../widgets/ayah_share_preview.dart';

Future<void> showAyahSharePreviewSheet({
  required BuildContext context,
  required SurahSummary summary,
  required SurahAyah ayah,
  required AyahShareService shareService,
  required AyahShareVideoService videoService,
  required QiblaTokens tokens,
}) {
  // El ScaffoldMessenger del bottom sheet está desconectado del Scaffold
  // principal. Se captura aquí, antes de abrir el sheet, para que los
  // snackbars aparezcan en la pantalla real y no se pierdan.
  final rootMessenger = ScaffoldMessenger.of(context);

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => FractionallySizedBox(
      heightFactor: 0.94,
      child: _AyahSharePreviewSheet(
        summary: summary,
        ayah: ayah,
        shareService: shareService,
        videoService: videoService,
        tokens: tokens,
        rootMessenger: rootMessenger,
      ),
    ),
  );
}

enum _AyahShareAction { text, image, video }

enum _VideoExportAction {
  share,
  save,
}

class _AyahSharePreviewSheet extends StatefulWidget {
  const _AyahSharePreviewSheet({
    required this.summary,
    required this.ayah,
    required this.shareService,
    required this.videoService,
    required this.tokens,
    required this.rootMessenger,
  });

  final SurahSummary summary;
  final SurahAyah ayah;
  final AyahShareService shareService;
  final AyahShareVideoService videoService;
  final QiblaTokens tokens;
  final ScaffoldMessengerState rootMessenger;

  @override
  State<_AyahSharePreviewSheet> createState() => _AyahSharePreviewSheetState();
}

class _AyahSharePreviewSheetState extends State<_AyahSharePreviewSheet> {
  SharePreviewLayoutOption _selectedLayout = SharePreviewLayoutOption.card;
  late SharePreviewContentOption _selectedContent;
  _AyahShareAction? _activeAction;

  bool get _hasArabicText => widget.ayah.arabic.trim().isNotEmpty;

  bool get _hasTranslation => widget.ayah.translation.trim().isNotEmpty;

  bool get _isBusy => _activeAction != null;

  bool get _supportsVideoExport =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.android ||
                  defaultTargetPlatform == TargetPlatform.iOS);

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

  AyahShareExportMode get _exportMode =>
      _selectedLayout == SharePreviewLayoutOption.card
          ? AyahShareExportMode.cardOnly
          : AyahShareExportMode.storyCanvas;

  AyahShareThemeData get _previewTheme => AyahShareThemeData.fromTokens(
        widget.tokens,
        transparentBackground: _selectedLayout == SharePreviewLayoutOption.card,
      );

  AyahShareData get _previewData => widget.shareService.buildShareData(
        widget.summary,
        widget.ayah,
        includeArabic: _includeArabic,
        includeTranslation: _includeTranslation,
      );

  Future<void> _shareText() async {
    if (_isBusy || (!_includeArabic && !_includeTranslation)) {
      return;
    }

    setState(() => _activeAction = _AyahShareAction.text);

    try {
      await widget.shareService.shareAyahAsText(
        widget.summary,
        widget.ayah,
        includeArabic: _includeArabic,
        includeTranslation: _includeTranslation,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      widget.rootMessenger.showSnackBar(
        SnackBar(
          content: Text(context.l10n.shareAyahTextError),
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

    setState(() => _activeAction = _AyahShareAction.image);

    try {
      await widget.shareService.shareAyahAsImage(
        widget.summary,
        widget.ayah,
        widget.tokens,
        mode: _exportMode,
        includeArabic: _includeArabic,
        includeTranslation: _includeTranslation,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      widget.rootMessenger.showSnackBar(
        SnackBar(
          content: Text(context.l10n.shareAyahImageError),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _activeAction = null);
      }
    }
  }

  Future<void> _shareVideo() async {
    if (_isBusy) {
      return;
    }

    if (!_includeArabic && !_includeTranslation) {
      await _showVideoExportError(context.l10n.shareAyahVideoError);
      return;
    }

    setState(() => _activeAction = _AyahShareAction.video);

    try {
      final draft = await widget.videoService.prepareDraft(
        summary: widget.summary,
        ayah: widget.ayah,
        includeArabic: _includeArabic,
        includeTranslation: _includeTranslation,
        exportMode: _exportMode,
      );
      if (!mounted) return;

      if (draft == null) {
        await _showVideoExportError(context.l10n.shareAyahVideoNoAudio);
        return;
      }

      final file = await widget.videoService.exportVideo(draft);
      if (!mounted) return;

      // Export done — clear the loading state before the iOS share sheet opens,
      // so the button shows its normal label while the system share UI is on screen.
      setState(() => _activeAction = null);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: widget.shareService.buildShareText(
          widget.summary,
          widget.ayah,
          includeArabic: _includeArabic,
          includeTranslation: _includeTranslation,
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e, stackTrace) {
      AppLogger.error('shareVideo: FAILED — ${e.runtimeType}: $e',
          error: e, stackTrace: stackTrace);
      await _showVideoExportError(e);
    } finally {
      if (mounted) setState(() => _activeAction = null);
    }
  }

  Future<void> _handleVideoAction() async {
    final action = await _chooseVideoExportAction();
    if (!mounted || action == null) return;

    if (action == _VideoExportAction.share) {
      await _shareVideo();
    } else {
      await _saveVideo();
    }
  }

  Future<_VideoExportAction?> _chooseVideoExportAction() {
    final l10n = context.l10n;
    return showModalBottomSheet<_VideoExportAction>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.ios_share_outlined),
                title: Text('${l10n.commonShare} ${l10n.commonVideo}'),
                subtitle: Text(
                  l10n.quranShareVideoSubtitle,
                  style: GoogleFonts.dmSans(fontSize: 12),
                ),
                onTap: () =>
                    Navigator.of(sheetContext).pop(_VideoExportAction.share),
              ),
              ListTile(
                leading: const Icon(Icons.save_outlined),
                title: Text('${l10n.commonSave} ${l10n.commonVideo}'),
                subtitle: Text(
                  l10n.videoSaveToGallerySubtitle,
                  style: GoogleFonts.dmSans(fontSize: 12),
                ),
                onTap: () =>
                    Navigator.of(sheetContext).pop(_VideoExportAction.save),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveVideo() async {
    if (_isBusy) {
      return;
    }

    if (!_includeArabic && !_includeTranslation) {
      widget.rootMessenger.showSnackBar(
        SnackBar(
          content: Text(context.l10n.videoSaveFailed),
        ),
      );
      return;
    }

    setState(() => _activeAction = _AyahShareAction.video);

    try {
      final draft = await widget.videoService.prepareDraft(
        summary: widget.summary,
        ayah: widget.ayah,
        includeArabic: _includeArabic,
        includeTranslation: _includeTranslation,
        exportMode: _exportMode,
      );
      if (!mounted) return;

      if (draft == null) {
        widget.rootMessenger.showSnackBar(
          SnackBar(
            content: Text(context.l10n.videoSaveFailed),
          ),
        );
        return;
      }

      final file = await widget.videoService.exportVideo(draft);
      if (!mounted) return;

      // Export done — clear loading state before the permission/gallery flow.
      setState(() => _activeAction = null);

      await widget.videoService.saveVideoToGallery(file);
      if (!mounted) return;

      widget.rootMessenger.showSnackBar(
        SnackBar(
          content: Text(context.l10n.videoSavedToGallery),
        ),
      );
      Navigator.of(context).pop();
    } catch (e, st) {
      AppLogger.error(
        'saveVideo: FAILED — ${e.runtimeType}: $e',
        error: e,
        stackTrace: st,
      );

      // Determine error message based on error type
      final errorString = e.toString().toLowerCase();
      final message = (errorString.contains('permission') ||
              errorString.contains('denied'))
          ? context.l10n.videoSavePermissionDenied
          : context.l10n.videoSaveFailed;

      widget.rootMessenger.showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
    } finally {
      if (mounted) setState(() => _activeAction = null);
    }
  }

  Future<void> _showVideoExportError(Object error) async {
    if (!mounted) return;

    final l10n = context.l10n;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.shareAyahVideoError),
        content: SingleChildScrollView(
          child: SelectableText(error.toString()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.commonClose),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = widget.tokens;
    final l10n = context.l10n;

    return SharePreviewBottomSheet(
      tokens: tokens,
      title: l10n.shareAyahTitle(widget.ayah.numberInSurah),
      subtitle: l10n.shareAyahSubtitle,
      preview: AyahSharePreview(
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
              selected: _selectedContent == SharePreviewContentOption.bilingual,
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
      footer: _AyahShareFooter(
        tokens: tokens,
        isBusy: _isBusy,
        activeAction: _activeAction,
        onShareText: _shareText,
        onShareImage: _shareImage,
        onShareVideo: _supportsVideoExport ? _handleVideoAction : null,
      ),
    );
  }
}

class _AyahShareFooter extends StatelessWidget {
  const _AyahShareFooter({
    required this.tokens,
    required this.isBusy,
    required this.activeAction,
    required this.onShareText,
    required this.onShareImage,
    required this.onShareVideo,
  });

  final QiblaTokens tokens;
  final bool isBusy;
  final _AyahShareAction? activeAction;
  final VoidCallback onShareText;
  final VoidCallback onShareImage;
  final VoidCallback? onShareVideo;

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
            child: activeAction == _AyahShareAction.image
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
        if (onShareVideo == null)
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
              child: activeAction == _AyahShareAction.text
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation(tokens.primary),
                      ),
                    )
                  : Text(
                      l10n.commonText,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          )
        else
          Row(
            children: [
              Expanded(
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
                  child: activeAction == _AyahShareAction.text
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor: AlwaysStoppedAnimation(tokens.primary),
                          ),
                        )
                      : Text(
                          l10n.commonText,
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: isBusy ? null : onShareVideo,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: tokens.textPrimary,
                    side: BorderSide(color: tokens.borderMed),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: activeAction == _AyahShareAction.video
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor: AlwaysStoppedAnimation(tokens.primary),
                          ),
                        )
                      : Text(
                          l10n.commonVideo,
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
