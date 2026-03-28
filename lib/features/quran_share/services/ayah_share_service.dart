import 'package:cross_file/cross_file.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_theme.dart';
import '../../quran/models/quran_models.dart';
import '../models/ayah_share_data.dart';
import '../models/ayah_share_theme.dart';
import 'ayah_share_image_service.dart';

final ayahShareServiceProvider = Provider<AyahShareService>((ref) {
  return AyahShareService();
});

class AyahShareService {
  String buildShareText(
    SurahSummary summary,
    SurahAyah ayah,
  ) {
    final arabic = ayah.arabic.trim();
    final translation = ayah.translation.trim();

    final sections = <String>[
      if (arabic.isNotEmpty) arabic,
      if (translation.isNotEmpty) translation,
      '\u2014 ${summary.nameLatin} (${summary.number}:${ayah.numberInSurah})',
      'App: Qibla Time',
    ];

    return sections.join('\n\n');
  }

  Future<void> shareAyahAsText(
    SurahSummary summary,
    SurahAyah ayah,
  ) async {
    await Share.share(buildShareText(summary, ayah));
  }

  Future<void> shareAyahAsImage(
    SurahSummary summary,
    SurahAyah ayah,
    QiblaTokens tokens,
  ) async {
    final file = await AyahShareImageService.savePng(
      data: AyahShareData(
        surahNumber: summary.number,
        surahNameLatin: summary.nameLatin,
        surahNameArabic: summary.nameArabic,
        ayahNumber: ayah.numberInSurah,
        arabicText: ayah.arabic,
        translation: ayah.translation,
        branding: 'App: Qibla Time',
      ),
      theme: AyahShareThemeData.fromTokens(
        tokens,
        transparentBackground: true,
      ),
      transparentBackground: true,
      mode: AyahShareExportMode.cardOnly,
      fileName: 'ayah_${summary.number}_${ayah.numberInSurah}',
    );

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Aleya ${ayah.numberInSurah} de ${summary.nameLatin}',
    );
  }
}
