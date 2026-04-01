import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/religious_reference_formatter.dart';
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
  String buildShareText(
    Hadith hadith, {
    bool includeArabic = true,
    bool includeTranslation = true,
  }) {
    final shareData = buildShareData(
      hadith,
      includeArabic: includeArabic,
      includeTranslation: includeTranslation,
    );

    final sections = <String>[
      if (shareData.hasArabicText) shareData.arabicText!.trim(),
      if (shareData.hasTranslation) shareData.translation.trim(),
      if (shareData.reference.trim().isNotEmpty)
        '- ${shareData.reference.trim()}',
      'App: Qibla Time',
    ];

    return sections.join('\n\n');
  }

  /// Comparte el hadiz como texto
  Future<void> shareHadithAsText(
    Hadith hadith, {
    bool includeArabic = true,
    bool includeTranslation = true,
  }) async {
    await Share.share(
      buildShareText(
        hadith,
        includeArabic: includeArabic,
        includeTranslation: includeTranslation,
      ),
      subject: 'Hadiz del día - Qibla Time',
    );
  }

  /// Comparte el hadiz como imagen
  Future<void> shareHadithAsImage(
    Hadith hadith,
    QiblaTokens tokens, {
    HadithShareExportMode mode = HadithShareExportMode.cardOnly,
    bool includeArabic = true,
    bool includeTranslation = true,
  }) async {
    if (!includeArabic && !includeTranslation) {
      throw ArgumentError(
        'At least one of includeArabic or includeTranslation must be true.',
      );
    }

    final transparentBackground = mode == HadithShareExportMode.cardOnly;
    final shareData = buildShareData(
      hadith,
      includeArabic: includeArabic,
      includeTranslation: includeTranslation,
    );
    final file = await HadithShareImageService.savePng(
      data: shareData,
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
      text: buildShareText(
        hadith,
        includeArabic: includeArabic,
        includeTranslation: includeTranslation,
      ),
      subject: 'Hadiz compartido desde Qibla Time',
    );
  }

  HadithShareData buildShareData(
    Hadith hadith, {
    bool includeArabic = true,
    bool includeTranslation = true,
  }) {
    return HadithShareData(
      arabicText: includeArabic ? hadith.arabic : null,
      translation: includeTranslation ? hadith.translation : '',
      reference: hadith.reference,
      arabicReference: _buildArabicHadithReference(hadith.reference),
      badgeLabel: 'HADITH',
      branding: 'App: Qibla Time',
    );
  }

  String? _buildArabicHadithReference(String reference) {
    final formatted = ReligiousReferenceFormatter.buildArabicReference(reference);
    if (formatted != null) {
      return formatted;
    }

    final normalized = reference.trim().toLowerCase();
    if (normalized.isEmpty) {
      return null;
    }

    final matches = <({int index, String label})>[];
    final entries = <({List<String> aliases, String arabicLabel})>[
      (
        aliases: ['bujari', 'bukhari', 'al-bukhari', 'al bukhari'],
        arabicLabel: 'البخاري',
      ),
      (
        aliases: ['muslim'],
        arabicLabel: 'مسلم',
      ),
      (
        aliases: ['al-tirmidhi', 'tirmidhi', 'at-tirmidhi'],
        arabicLabel: 'الترمذي',
      ),
      (
        aliases: ['abu-dawud', 'abu dawud', 'abudawud'],
        arabicLabel: 'أبو داود',
      ),
      (
        aliases: ['an-nsaai', 'an-nsaa\'i', 'an-nsaa’i', 'nasai', 'al-nasai'],
        arabicLabel: 'النسائي',
      ),
      (
        aliases: ['ibn mayah', 'ibn majah', 'ibnmajah'],
        arabicLabel: 'ابن ماجه',
      ),
      (
        aliases: ['muwatta', 'malik'],
        arabicLabel: 'مالك',
      ),
      (
        aliases: ['ahmad'],
        arabicLabel: 'أحمد',
      ),
      (
        aliases: ['ibn hibban'],
        arabicLabel: 'ابن حبان',
      ),
      (
        aliases: ['al-hakim', 'al hakim'],
        arabicLabel: 'الحاكم',
      ),
      (
        aliases: ['ad-darimi', 'ad darimi', 'darimi'],
        arabicLabel: 'الدارمي',
      ),
      (
        aliases: ['at-tabarani', 'at tabarani', 'tabarani'],
        arabicLabel: 'الطبراني',
      ),
    ];

    for (final entry in entries) {
      for (final alias in entry.aliases) {
        final index = normalized.indexOf(alias);
        if (index == -1) continue;
        matches.add((index: index, label: entry.arabicLabel));
        break;
      }
    }

    if (matches.isEmpty) {
      return null;
    }

    matches.sort((a, b) => a.index.compareTo(b.index));
    final orderedLabels = <String>[];
    for (final match in matches) {
      if (!orderedLabels.contains(match.label)) {
        orderedLabels.add(match.label);
      }
    }

    return orderedLabels.join('، ');
  }
}
