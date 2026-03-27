import 'package:cross_file/cross_file.dart';
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

class HadithShareService {
  String buildShareText(Hadith hadith) {
    final arabic = hadith.arabic.trim();
    final translation = hadith.translation.trim();
    final reference = hadith.reference.trim();

    final sections = <String>[
      if (arabic.isNotEmpty) arabic,
      if (translation.isNotEmpty) translation,
      if (reference.isNotEmpty) '\u2014 $reference',
      'Qibla',
    ];

    return sections.join('\n\n');
  }

  Future<void> shareHadithAsText(Hadith hadith) async {
    await Share.share(buildShareText(hadith));
  }

  Future<void> shareHadithAsImage(
    Hadith hadith,
    QiblaTokens tokens,
  ) async {
    final file = await HadithShareImageService.savePng(
      data: HadithShareData(
        arabicText: hadith.arabic,
        translation: hadith.translation,
        reference: hadith.reference,
        branding: 'Qibla',
      ),
      theme: HadithShareThemeData.fromTokens(
        tokens,
        transparentBackground: true,
      ),
      transparentBackground: true,
      mode: HadithShareExportMode.cardOnly,
      fileName: 'hadith_${hadith.id}',
    );

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Hadith diario de Qibla',
    );
  }
}
