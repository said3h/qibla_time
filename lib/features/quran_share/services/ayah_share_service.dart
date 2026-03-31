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
    SurahAyah ayah, {
    bool includeArabic = true,
    bool includeTranslation = true,
  }) {
    final shareData = buildShareData(
      summary,
      ayah,
      includeArabic: includeArabic,
      includeTranslation: includeTranslation,
    );

    final sections = <String>[
      if (shareData.hasArabicText) shareData.arabicText.trim(),
      if (shareData.hasTranslation) shareData.translation!.trim(),
      '- ${shareData.referenceLabel}',
      'App: Qibla Time',
    ];

    return sections.join('\n\n');
  }

  Future<void> shareAyahAsText(
    SurahSummary summary,
    SurahAyah ayah, {
    bool includeArabic = true,
    bool includeTranslation = true,
  }) async {
    await Share.share(
      buildShareText(
        summary,
        ayah,
        includeArabic: includeArabic,
        includeTranslation: includeTranslation,
      ),
    );
  }

  Future<void> shareAyahAsImage(
    SurahSummary summary,
    SurahAyah ayah,
    QiblaTokens tokens, {
    AyahShareExportMode mode = AyahShareExportMode.cardOnly,
    bool includeArabic = true,
    bool includeTranslation = true,
  }) async {
    if (!includeArabic && !includeTranslation) {
      throw ArgumentError(
        'At least one of includeArabic or includeTranslation must be true.',
      );
    }

    final transparentBackground = mode == AyahShareExportMode.cardOnly;
    final file = await AyahShareImageService.savePng(
      data: buildShareData(
        summary,
        ayah,
        includeArabic: includeArabic,
        includeTranslation: includeTranslation,
      ),
      theme: AyahShareThemeData.fromTokens(
        tokens,
        transparentBackground: transparentBackground,
      ),
      transparentBackground: transparentBackground,
      mode: mode,
      fileName: 'ayah_${summary.number}_${ayah.numberInSurah}',
    );

    await Share.shareXFiles(
      [XFile(file.path)],
      text: buildShareText(
        summary,
        ayah,
        includeArabic: includeArabic,
        includeTranslation: includeTranslation,
      ),
    );
  }

  AyahShareData buildShareData(
    SurahSummary summary,
    SurahAyah ayah, {
    bool includeArabic = true,
    bool includeTranslation = true,
  }) {
    return AyahShareData(
      surahNumber: summary.number,
      surahNameLatin: summary.nameLatin,
      surahNameArabic: summary.nameArabic,
      ayahNumber: ayah.numberInSurah,
      arabicText: includeArabic ? ayah.arabic : '',
      translation: includeTranslation ? ayah.translation : null,
      branding: 'App: Qibla Time',
    );
  }
}
