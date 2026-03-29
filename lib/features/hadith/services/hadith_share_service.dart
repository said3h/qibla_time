import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_theme.dart';
import '../../hadith_share/models/hadith_share_data.dart';
import '../../hadith_share/models/hadith_share_theme.dart';
import '../../hadith_share/services/hadith_share_image_service.dart';
import '../models/hadith.dart';

final hadithShareServiceProvider = Provider<HadithShareService>((ref) {
  return HadithShareService();
});

/// Servicio para compartir hadices como texto o imagen
class HadithShareService {
  /// Construye el texto para compartir
  String buildShareText(Hadith hadith) {
    final arabic = hadith.arabic.trim();
    final translation = hadith.translation.trim();
    final reference = hadith.reference.trim();

    final sections = <String>[
      if (arabic.isNotEmpty) arabic,
      if (translation.isNotEmpty) translation,
      if (reference.isNotEmpty) '— $reference',
      'App: Qibla Time',
    ];

    return sections.join('\n\n');
  }

  /// Comparte el hadiz como texto
  Future<void> shareHadithAsText(Hadith hadith) async {
    await Share.share(
      buildShareText(hadith),
      subject: 'Hadiz del día - Qibla Time',
    );
  }

  /// Comparte el hadiz como imagen
  Future<void> shareHadithAsImage(
    Hadith hadith,
    QiblaTokens tokens, {
    HadithShareExportMode mode = HadithShareExportMode.cardOnly,
  }) async {
    final transparentBackground = mode == HadithShareExportMode.cardOnly;
    final file = await HadithShareImageService.savePng(
      data: _buildShareData(hadith),
      theme: HadithShareThemeData.fromTokens(
        tokens,
        transparentBackground: transparentBackground,
      ),
      transparentBackground: transparentBackground,
      mode: mode,
      fileName: 'hadith_${hadith.id}_${DateTime.now().millisecondsSinceEpoch}',
    );

    await Share.shareXFiles(
      [XFile(file.path)],
      text: buildShareText(hadith),
      subject: 'Hadiz compartido desde Qibla Time',
    );
  }

  HadithShareData _buildShareData(Hadith hadith) {
    return HadithShareData(
      arabicText: hadith.arabic,
      translation: hadith.translation,
      reference: hadith.reference,
      branding: 'App: Qibla Time',
    );
  }
}
