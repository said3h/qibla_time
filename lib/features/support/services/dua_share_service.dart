import 'package:cross_file/cross_file.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/religious_reference_formatter.dart';
import '../../hadith_share/models/hadith_share_data.dart';
import '../../hadith_share/models/hadith_share_theme.dart';
import '../../hadith_share/services/hadith_share_image_service.dart';
import '../models/dua_model.dart';

class DuaShareService {
  const DuaShareService();

  String buildShareText(
    Dua dua, {
    bool includeArabic = true,
    bool includeTranslation = true,
  }) {
    final shareData = buildShareData(
      dua,
      includeArabic: includeArabic,
      includeTranslation: includeTranslation,
    );

    final sections = <String>[
      if (dua.title.trim().isNotEmpty) dua.title.trim(),
      if (shareData.hasArabicText) shareData.arabicText!.trim(),
      if (shareData.hasTranslation) shareData.translation.trim(),
      if (shareData.reference.trim().isNotEmpty)
        'Referencia: ${shareData.reference.trim()}',
      shareData.branding.trim(),
    ];

    return sections.join('\n\n');
  }

  Future<void> shareDuaAsText(
    Dua dua, {
    bool includeArabic = true,
    bool includeTranslation = true,
  }) async {
    await Share.share(
      buildShareText(
        dua,
        includeArabic: includeArabic,
        includeTranslation: includeTranslation,
      ),
      subject: dua.title.trim().isEmpty ? 'Dua' : dua.title.trim(),
    );
  }

  Future<void> shareDuaAsImage(
    Dua dua,
    QiblaTokens tokens, {
    HadithShareExportMode mode = HadithShareExportMode.storyCanvas,
    bool includeArabic = true,
    bool includeTranslation = true,
  }) async {
    if (!includeArabic && !includeTranslation) {
      throw ArgumentError(
        'At least one of includeArabic or includeTranslation must be true.',
      );
    }

    final transparentBackground = mode == HadithShareExportMode.cardOnly;
    final file = await HadithShareImageService.savePng(
      data: buildShareData(
        dua,
        includeArabic: includeArabic,
        includeTranslation: includeTranslation,
      ),
      theme: HadithShareThemeData.fromTokens(
        tokens,
        transparentBackground: transparentBackground,
      ),
      transparentBackground: transparentBackground,
      mode: mode,
      fileName: 'dua_${dua.id}_${DateTime.now().millisecondsSinceEpoch}',
    );

    await Share.shareXFiles(
      [XFile(file.path)],
      text: buildShareText(
        dua,
        includeArabic: includeArabic,
        includeTranslation: includeTranslation,
      ),
      subject: dua.title.trim().isEmpty ? 'Dua' : dua.title.trim(),
    );
  }

  HadithShareData buildShareData(
    Dua dua, {
    bool includeArabic = true,
    bool includeTranslation = true,
  }) {
    final title = dua.title.trim();
    final reference = (dua.reference ?? '').trim();
    final source = (dua.source ?? '').trim();
    final arabicReference = (dua.reference ?? '').trim().isEmpty
        ? null
        : ReligiousReferenceFormatter.buildArabicReference(dua.reference!);
    final arabicCategoryLabel = _duaCategoryArabicLabel(dua.category);
    final referenceSections = <String>[
      if (title.isNotEmpty) title,
      if (reference.isNotEmpty) reference,
      if (source.isNotEmpty) source,
    ];

    return HadithShareData(
      arabicText: includeArabic && dua.arabicText.trim().isNotEmpty
          ? dua.arabicText
          : null,
      translation: includeTranslation ? dua.translation : '',
      reference: referenceSections.join(' · '),
      arabicReference: arabicReference ?? arabicCategoryLabel,
      badgeLabel: 'DUA',
      branding: 'App: Qibla Time',
    );
  }

  String? _duaCategoryArabicLabel(String category) {
    return switch (category) {
      'morning' => 'الصباح',
      'night' => 'المساء',
      'sleep' => 'النوم',
      'travel' => 'السفر',
      'food' => 'الطعام',
      'sickness' => 'المرض',
      'protection' => 'التحصين',
      'repentance' => 'التوبة',
      'mosque' => 'المسجد',
      'rain' => 'المطر',
      'stress' => 'الكرب',
      'gratitude' => 'الشكر',
      'wudu' => 'الوضوء',
      'after_prayer' => 'بعد الصلاة',
      'zikr' => 'الذكر',
      'parents' => 'العائلة',
      'hajj' => 'الحج',
      _ => null,
    };
  }
}
