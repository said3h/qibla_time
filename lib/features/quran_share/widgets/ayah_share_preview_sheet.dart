import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_theme.dart';
import '../../quran/models/quran_models.dart';
import '../models/ayah_share_data.dart';
import '../models/ayah_share_theme.dart';
import '../services/ayah_share_image_service.dart';
import '../services/ayah_share_service.dart';
import '../services/ayah_share_video_service.dart';
import '../widgets/ayah_share_preview.dart';
import '../../shared_share/widgets/content_share_preview_sheet.dart';

Future<void> showAyahSharePreviewSheet({
  required BuildContext context,
  required SurahSummary summary,
  required SurahAyah ayah,
  required AyahShareService shareService,
  required AyahShareVideoService videoService,
  required QiblaTokens tokens,
}) {
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
      ),
    ),
  );
}

enum _AyahShareAction { text, image, video }

class _AyahSharePreviewSheet extends StatefulWidget {
  const _AyahSharePreviewSheet({
    required this.summary,
    required this.ayah,
    required this.shareService,
    required this.videoService,
    required this.tokens,
  });

  final SurahSummary summary;
  final SurahAyah ayah;
  final AyahShareService shareService;
  final AyahShareVideoService videoService;
  final QiblaTokens tokens;

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hemos podido compartir el texto de esta aleya.'),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No hemos podido generar la imagen de esta aleya.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _activeAction = null);
      }
    }
  }

  Future<void> _shareVideo() async {
    if (_isBusy || (!_includeArabic && !_includeTranslation)) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
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
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'No hay audio disponible para generar el video de esta aleya.',
            ),
          ),
        );
        return;
      }

      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 45),
          content: Text('Generando video de la aleya...'),
        ),
      );

      final file = await widget.videoService.exportVideo(draft);
      if (!mounted) return;

      messenger.hideCurrentSnackBar();
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
    } catch (_) {
      if (!mounted) return;

      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'No hemos podido generar el video de esta aleya.',
          ),
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

    return SharePreviewBottomSheet(
      tokens: tokens,
      title: 'Compartir aleya ${widget.ayah.numberInSurah}',
      subtitle: 'Mantén la misma presentación visual para texto, imagen y video.',
      preview: AyahSharePreview(
        data: _previewData,
        theme: _previewTheme,
        cardOnly: _selectedLayout == SharePreviewLayoutOption.card,
      ),
      sections: [
        ShareOptionSection(
          title: 'Estilo / fondo',
          children: [
            ShareSelectionChip(
              label: 'Tarjeta',
              selected: _selectedLayout == SharePreviewLayoutOption.card,
              onSelected: () {
                setState(() {
                  _selectedLayout = SharePreviewLayoutOption.card;
                });
              },
            ),
            ShareSelectionChip(
              label: 'Historia',
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
          title: 'Contenido',
          children: [
            ShareSelectionChip(
              label: 'Árabe + traducción',
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
              label: 'Solo árabe',
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
              label: 'Solo traducción',
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
        onShareVideo: _shareVideo,
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
  final VoidCallback onShareVideo;

  @override
  Widget build(BuildContext context) {
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
                    'Compartir imagen',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 10),
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
                        'Texto',
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
                        'Video',
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
