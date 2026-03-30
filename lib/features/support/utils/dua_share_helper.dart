import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_theme.dart';
import '../../hadith_share/models/hadith_share_data.dart';
import '../../hadith_share/models/hadith_share_theme.dart';
import '../../hadith_share/services/hadith_share_image_service.dart';
import '../models/dua_model.dart';

Future<void> shareDua(BuildContext context, Dua dua) async {
  final shareText = _buildDuaShareText(dua);

  try {
    final shareData = _buildDuaShareData(dua);
    final file = await HadithShareImageService.savePng(
      data: shareData,
      theme: HadithShareThemeData.fromTokens(
        QiblaThemes.current,
        transparentBackground: false,
      ),
      transparentBackground: false,
      mode: HadithShareExportMode.storyCanvas,
      fileName: 'dua_${dua.id}_${DateTime.now().millisecondsSinceEpoch}',
    );

    await Share.shareXFiles(
      [XFile(file.path)],
      text: shareText,
      subject: dua.title.trim().isEmpty ? 'Dua' : dua.title.trim(),
    );
  } catch (_) {
    try {
      await Share.share(
        shareText,
        subject: dua.title.trim().isEmpty ? 'Dua' : dua.title.trim(),
      );
    } catch (_) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(
          content: Text('No se pudo compartir la dua'),
        ),
      );
    }
  }
}

String _buildDuaShareText(Dua dua) {
  final sections = <String>[
    dua.title.trim(),
    if (dua.arabicText.trim().isNotEmpty) dua.arabicText.trim(),
    if (dua.transliteration.trim().isNotEmpty) dua.transliteration.trim(),
    if (dua.translation.trim().isNotEmpty) dua.translation.trim(),
    if ((dua.reference ?? '').trim().isNotEmpty)
      'Referencia: ${(dua.reference ?? '').trim()}',
    if ((dua.source ?? '').trim().isNotEmpty)
      'Fuente: ${(dua.source ?? '').trim()}',
    'App: Qibla Time',
  ];

  return sections.join('\n\n');
}

HadithShareData _buildDuaShareData(Dua dua) {
  final title = dua.title.trim();
  final reference = (dua.reference ?? '').trim();
  final source = (dua.source ?? '').trim();
  final referenceSections = <String>[
    if (title.isNotEmpty) title,
    if (reference.isNotEmpty) reference,
    if (source.isNotEmpty) source,
  ];

  return HadithShareData(
    arabicText: dua.arabicText.trim().isEmpty ? null : dua.arabicText,
    translation: dua.translation,
    reference: referenceSections.join(' · '),
    branding: 'App: Qibla Time',
  );
}
