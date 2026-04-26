import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/l10n.dart';
import '../../quran/models/quran_models.dart';
import '../models/ayah_share_data.dart';
import '../models/ayah_share_theme.dart';
import 'ayah_share_image_service.dart';

final ayahShareServiceProvider = Provider<AyahShareService>((ref) {
  return AyahShareService();
});

class AyahShareService {
  Future<File> exportAyahImagePng(
    SurahSummary summary,
    SurahAyah ayah,
    QiblaTokens tokens, {
    required AyahShareExportMode mode,
    required bool includeArabic,
    required bool includeTranslation,
    Directory? directory,
  }) {
    if (!includeArabic && !includeTranslation) {
      throw ArgumentError(
        'At least one of includeArabic or includeTranslation must be true.',
      );
    }

    final transparentBackground = mode == AyahShareExportMode.cardOnly;
    return AyahShareImageService.savePng(
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
      directory: directory,
    );
  }

  Future<File> exportAyahsImagePng(
    SurahSummary summary,
    List<SurahAyah> ayahs,
    QiblaTokens tokens, {
    required AyahShareExportMode mode,
    required bool includeArabic,
    required bool includeTranslation,
    Directory? directory,
  }) {
    if (!includeArabic && !includeTranslation) {
      throw ArgumentError(
        'At least one of includeArabic or includeTranslation must be true.',
      );
    }
    if (ayahs.isEmpty) {
      throw ArgumentError('At least one ayah is required.');
    }

    final transparentBackground = mode == AyahShareExportMode.cardOnly;
    return AyahShareImageService.savePng(
      data: buildMultiAyahShareData(
        summary,
        ayahs,
        includeArabic: includeArabic,
        includeTranslation: includeTranslation,
      ),
      theme: AyahShareThemeData.fromTokens(
        tokens,
        transparentBackground: transparentBackground,
      ),
      transparentBackground: transparentBackground,
      mode: mode,
      fileName:
          'ayah_${summary.number}_${ayahs.first.numberInSurah}_${ayahs.last.numberInSurah}',
      directory: directory,
    );
  }

  String buildShareText(
    SurahSummary summary,
    SurahAyah ayah, {
    bool includeArabic = true,
    bool includeTranslation = true,
  }) {
    final l10n = appLocalizationsForDevice();
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
      l10n.shareBranding,
    ];

    return sections.join('\n\n');
  }

  String buildMultiAyahShareText(
    SurahSummary summary,
    List<SurahAyah> ayahs, {
    bool includeArabic = true,
    bool includeTranslation = true,
  }) {
    final l10n = appLocalizationsForDevice();
    final shareData = buildMultiAyahShareData(
      summary,
      ayahs,
      includeArabic: includeArabic,
      includeTranslation: includeTranslation,
    );

    final sections = <String>[
      if (shareData.hasArabicText) shareData.arabicText.trim(),
      if (shareData.hasTranslation) shareData.translation!.trim(),
      '- ${shareData.referenceLabel}',
      l10n.shareBranding,
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

  Future<void> shareAyahsAsText(
    SurahSummary summary,
    List<SurahAyah> ayahs, {
    bool includeArabic = true,
    bool includeTranslation = true,
  }) async {
    await Share.share(
      buildMultiAyahShareText(
        summary,
        ayahs,
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
    final file = await exportAyahImagePng(
      summary,
      ayah,
      tokens,
      mode: mode,
      includeArabic: includeArabic,
      includeTranslation: includeTranslation,
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

  Future<void> shareAyahsAsImage(
    SurahSummary summary,
    List<SurahAyah> ayahs,
    QiblaTokens tokens, {
    AyahShareExportMode mode = AyahShareExportMode.cardOnly,
    bool includeArabic = true,
    bool includeTranslation = true,
  }) async {
    final file = await exportAyahsImagePng(
      summary,
      ayahs,
      tokens,
      mode: mode,
      includeArabic: includeArabic,
      includeTranslation: includeTranslation,
    );

    await Share.shareXFiles(
      [XFile(file.path)],
      text: buildMultiAyahShareText(
        summary,
        ayahs,
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
    final l10n = appLocalizationsForDevice();
    return AyahShareData(
      surahNumber: summary.number,
      surahNameLatin: summary.nameLatin,
      surahNameArabic: summary.nameArabic,
      ayahNumber: ayah.numberInSurah,
      arabicText: includeArabic ? ayah.arabic : '',
      translation: includeTranslation ? ayah.translation : null,
      badgeLabel: l10n.shareBadgeQuran,
      branding: l10n.shareBranding,
    );
  }

  AyahShareData buildMultiAyahShareData(
    SurahSummary summary,
    List<SurahAyah> ayahs, {
    bool includeArabic = true,
    bool includeTranslation = true,
  }) {
    if (ayahs.isEmpty) {
      throw ArgumentError('At least one ayah is required.');
    }

    final sortedAyahs = [...ayahs]
      ..sort((a, b) => a.numberInSurah.compareTo(b.numberInSurah));
    final l10n = appLocalizationsForDevice();
    return AyahShareData(
      surahNumber: summary.number,
      surahNameLatin: summary.nameLatin,
      surahNameArabic: summary.nameArabic,
      ayahNumber: sortedAyahs.first.numberInSurah,
      endAyahNumber: sortedAyahs.last.numberInSurah,
      arabicText: includeArabic
          ? sortedAyahs
              .map((ayah) => '${ayah.arabic} ﴿${ayah.numberInSurah}﴾')
              .join(' ')
          : '',
      translation: includeTranslation
          ? sortedAyahs
              .map((ayah) => '${ayah.numberInSurah}. ${ayah.translation}')
              .join('\n\n')
          : null,
      badgeLabel: l10n.shareBadgeQuran,
      branding: l10n.shareBranding,
    );
  }
}
