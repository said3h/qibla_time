import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/localization/locale_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/l10n.dart';
import '../../prayer_times/domain/entities/prayer_name.dart';

class PrayerGuideScreen extends StatelessWidget {
  const PrayerGuideScreen({
    super.key,
    required this.prayerName,
  });

  final PrayerName prayerName;

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);
    final languageCode = AppLocaleController.effectiveLanguageCode(locale);
    final isArabicOnly = languageCode == 'ar';
    final prayerLabel = _localizedPrayerName(prayerName, languageCode);
    final prayerArabic = prayerName.displayNameArabic;
    final steps = _buildSteps(l10n);

    return Scaffold(
      backgroundColor: tokens.bgPage,
      appBar: AppBar(
        title: Text(
          l10n.prayerGuideTitle,
          style: isArabicOnly
              ? GoogleFonts.amiri(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: tokens.primary,
                )
              : GoogleFonts.dmSerifDisplay(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: tokens.primary,
                ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: tokens.bgSurface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: tokens.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prayerLabel,
                  textAlign: isArabicOnly ? TextAlign.right : TextAlign.left,
                  style: isArabicOnly
                      ? GoogleFonts.amiri(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: tokens.primaryLight,
                        )
                      : GoogleFonts.dmSans(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: tokens.primaryLight,
                        ),
                ),
                if (!isArabicOnly) ...[
                  const SizedBox(height: 4),
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      prayerArabic,
                      style: GoogleFonts.amiri(
                        fontSize: 20,
                        color: tokens.textSecondary,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: tokens.primaryBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: tokens.primaryBorder),
                  ),
                  child: Text(
                    _rakaatsSummary(l10n, prayerName),
                    textAlign: isArabicOnly ? TextAlign.right : TextAlign.left,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      height: 1.6,
                      fontWeight: FontWeight.w600,
                      color: tokens.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ...steps.map(
            (step) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _PrayerGuideStepCard(
                step: step,
                isArabicOnly: isArabicOnly,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<_PrayerGuideStepData> _buildSteps(AppLocalizations l10n) {
    return [
      _PrayerGuideStepData(
        number: 1,
        title: l10n.prayerGuideNiyyah,
        description: l10n.prayerGuideNiyyahDescription,
        arabicName: 'النية',
        transliteration: 'Niyyah',
        assetPath: 'assets/images/prayer_positions/niyyah.png',
      ),
      _PrayerGuideStepData(
        number: 2,
        title: l10n.prayerGuideTakbir,
        description: l10n.prayerGuideTakbirDescription,
        arabicName: 'تكبيرة الإحرام',
        transliteration: 'Takbiratul Ihram',
        assetPath: 'assets/images/prayer_positions/takbir.png',
      ),
      _PrayerGuideStepData(
        number: 3,
        title: l10n.prayerGuideQiyam,
        description: l10n.prayerGuideQiyamDescription,
        arabicName: 'القيام',
        transliteration: 'Qiyam',
        assetPath: 'assets/images/prayer_positions/qiyam.png',
      ),
      _PrayerGuideStepData(
        number: 4,
        title: l10n.prayerGuideRuku,
        description: l10n.prayerGuideRukuDescription,
        arabicName: 'الركوع',
        transliteration: 'Ruku',
        assetPath: 'assets/images/prayer_positions/ruku.png',
      ),
      _PrayerGuideStepData(
        number: 5,
        title: l10n.prayerGuideItidal,
        description: l10n.prayerGuideItidalDescription,
        arabicName: 'الاعتدال',
        transliteration: "I'tidal",
        assetPath: 'assets/images/prayer_positions/itidal.png',
      ),
      _PrayerGuideStepData(
        number: 6,
        title: l10n.prayerGuideSujud,
        description: l10n.prayerGuideSujudDescription,
        arabicName: 'السجود',
        transliteration: 'Sujud',
        assetPath: 'assets/images/prayer_positions/sujud.png',
      ),
      _PrayerGuideStepData(
        number: 7,
        title: l10n.prayerGuideJalsa,
        description: l10n.prayerGuideJalsaDescription,
        arabicName: 'الجلسة',
        transliteration: 'Jalsa',
        assetPath: 'assets/images/prayer_positions/jalsa.png',
      ),
      _PrayerGuideStepData(
        number: 8,
        title: l10n.prayerGuideSujud,
        description: l10n.prayerGuideSecondSujudDescription,
        arabicName: 'السجود الثاني',
        transliteration: 'Second sujud',
        assetPath: 'assets/images/prayer_positions/sujud.png',
      ),
      _PrayerGuideStepData(
        number: 9,
        title: l10n.prayerGuideTashahhud,
        description: l10n.prayerGuideTashahhudDescription,
        arabicName: 'التشهد',
        transliteration: 'Tashahhud',
        assetPath: 'assets/images/prayer_positions/tashahhud.png',
      ),
      _PrayerGuideStepData(
        number: 10,
        title: l10n.prayerGuideTaslim,
        description: l10n.prayerGuideTaslimRightDescription,
        arabicName: 'السلام يمينًا',
        transliteration: 'Taslim yaminan',
        assetPath: 'assets/images/prayer_positions/taslim_right.png',
      ),
      _PrayerGuideStepData(
        number: 11,
        title: l10n.prayerGuideTaslim,
        description: l10n.prayerGuideTaslimLeftDescription,
        arabicName: 'السلام يسارًا',
        transliteration: 'Taslim yasaran',
        assetPath: 'assets/images/prayer_positions/taslim_left.png',
      ),
    ];
  }

  String _localizedPrayerName(PrayerName prayer, String languageCode) {
    return switch (languageCode) {
      'de' => switch (prayer) {
          PrayerName.fajr => 'Fadschr',
          PrayerName.dhuhr => 'Zuhr',
          PrayerName.asr => 'Asr',
          PrayerName.maghrib => 'Maghrib',
          PrayerName.isha => 'Ischa',
        },
      'id' => switch (prayer) {
          PrayerName.fajr => 'Subuh',
          PrayerName.dhuhr => 'Dzuhur',
          PrayerName.asr => 'Ashar',
          PrayerName.maghrib => 'Maghrib',
          PrayerName.isha => 'Isya',
        },
      'nl' => switch (prayer) {
          PrayerName.fajr => 'Fajr',
          PrayerName.dhuhr => 'Dhoehr',
          PrayerName.asr => 'Asr',
          PrayerName.maghrib => 'Maghrib',
          PrayerName.isha => 'Isja',
        },
      'ru' => prayer.displayNameRussian,
      _ => prayer.localizedDisplayName(languageCode),
    };
  }

  String _rakaatsSummary(AppLocalizations l10n, PrayerName prayer) {
    return switch (prayer) {
      PrayerName.fajr => l10n.prayerGuideRakaatsFajr,
      PrayerName.dhuhr => l10n.prayerGuideRakaatsDhuhr,
      PrayerName.asr => l10n.prayerGuideRakaatsAsr,
      PrayerName.maghrib => l10n.prayerGuideRakaatsMaghrib,
      PrayerName.isha => l10n.prayerGuideRakaatsIsha,
    };
  }
}

class _PrayerGuideStepCard extends StatelessWidget {
  const _PrayerGuideStepCard({
    required this.step,
    required this.isArabicOnly,
  });

  final _PrayerGuideStepData step;
  final bool isArabicOnly;

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;
    final l10n = context.l10n;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tokens.bgSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: tokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: tokens.primaryBg,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: tokens.primaryBorder),
            ),
            child: Text(
              '${l10n.prayerGuideStep} ${step.number}',
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: tokens.primaryLight,
                letterSpacing: 0.4,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            height: 200,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: tokens.bgSurface2,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: tokens.border),
            ),
            child: Image.asset(
              step.assetPath,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            step.title,
            textAlign: isArabicOnly ? TextAlign.right : TextAlign.left,
            style: GoogleFonts.dmSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: tokens.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              step.arabicName,
              style: GoogleFonts.amiri(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: tokens.primaryLight,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            step.transliteration,
            textAlign: isArabicOnly ? TextAlign.right : TextAlign.left,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: tokens.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            step.description,
            textAlign: isArabicOnly ? TextAlign.right : TextAlign.left,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              height: 1.65,
              color: tokens.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrayerGuideStepData {
  const _PrayerGuideStepData({
    required this.number,
    required this.title,
    required this.description,
    required this.arabicName,
    required this.transliteration,
    required this.assetPath,
  });

  final int number;
  final String title;
  final String description;
  final String arabicName;
  final String transliteration;
  final String assetPath;
}
