import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/localization/locale_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/l10n.dart';
import '../../prayer_times/domain/entities/prayer_name.dart';
import '../../quran/models/quran_models.dart';
import '../../quran/screens/quran_screen.dart';
import '../../quran/services/quran_service.dart';

class PrayerGuideScreen extends ConsumerStatefulWidget {
  const PrayerGuideScreen({
    super.key,
    required this.prayerName,
  });

  final PrayerName prayerName;

  @override
  ConsumerState<PrayerGuideScreen> createState() => _PrayerGuideScreenState();
}

class _PrayerGuideScreenState extends ConsumerState<PrayerGuideScreen> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);
    final languageCode = AppLocaleController.effectiveLanguageCode(locale);
    final isArabicOnly = languageCode == 'ar';
    final surahs = ref.watch(quranSurahsProvider);
    final fatiha = _findSurahByNumber(surahs, 1);
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
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _PrayerGuideHeader(
                prayerLabel: _localizedPrayerName(widget.prayerName, languageCode),
                prayerArabic: widget.prayerName.displayNameArabic,
                rakaatSummary: _rakaatsSummary(l10n, widget.prayerName),
                flowNote: _rakaatFlowNote(l10n, widget.prayerName),
                overview: l10n.prayerGuideOneRakaatIntro,
                isArabicOnly: isArabicOnly,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: steps.length,
                onPageChanged: (value) {
                  setState(() => _currentPage = value);
                },
                itemBuilder: (context, index) {
                  final step = steps[index];
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: _PrayerGuideStepPage(
                      step: step,
                      totalSteps: steps.length,
                      isArabicOnly: isArabicOnly,
                      onOpenFatiha: step.showsSurahActions && fatiha != null
                          ? () => _openSurah(context, fatiha)
                          : null,
                      onChooseSurah: step.showsSurahActions
                          ? () => _showSurahPicker(
                                context,
                                surahs,
                                isArabicOnly,
                              )
                          : null,
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
              child: Column(
                children: [
                  Text(
                    '${l10n.prayerGuideStep} ${_currentPage + 1} / ${steps.length}',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: tokens.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(
                      steps.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        width: index == _currentPage ? 22 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: index == _currentPage
                              ? tokens.primaryLight
                              : tokens.border,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  SurahSummary? _findSurahByNumber(List<SurahSummary> surahs, int number) {
    for (final surah in surahs) {
      if (surah.number == number) {
        return surah;
      }
    }
    return null;
  }

  Future<void> _showSurahPicker(
    BuildContext context,
    List<SurahSummary> surahs,
    bool isArabicOnly,
  ) async {
    final selectableSurahs = surahs.where((surah) => surah.number >= 2).toList();
    if (selectableSurahs.isEmpty) {
      return;
    }

    final l10n = context.l10n;
    final tokens = QiblaThemes.current;
    final selectedSurah = await showModalBottomSheet<SurahSummary>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: tokens.bgSurface,
      builder: (sheetContext) {
        return SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * 0.72,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.prayerGuideChooseSurahTitle,
                      style: GoogleFonts.dmSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: tokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.prayerGuideChooseSurahSubtitle,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        height: 1.5,
                        color: tokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: selectableSurahs.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: tokens.border,
                  ),
                  itemBuilder: (context, index) {
                    final surah = selectableSurahs[index];
                    return ListTile(
                      onTap: () => Navigator.of(sheetContext).pop(surah),
                      title: Text(
                        isArabicOnly ? surah.nameArabic : surah.nameLatin,
                        style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.w700,
                          color: tokens.textPrimary,
                        ),
                      ),
                      subtitle: isArabicOnly
                          ? Text(
                              surah.nameLatin,
                              style: GoogleFonts.dmSans(
                                color: tokens.textSecondary,
                              ),
                            )
                          : Directionality(
                              textDirection: TextDirection.rtl,
                              child: Text(
                                surah.nameArabic,
                                style: GoogleFonts.amiri(
                                  fontSize: 18,
                                  color: tokens.textSecondary,
                                ),
                              ),
                            ),
                      trailing: CircleAvatar(
                        radius: 16,
                        backgroundColor: tokens.primaryBg,
                        foregroundColor: tokens.primaryLight,
                        child: Text(
                          '${surah.number}',
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );

    if (!context.mounted || selectedSurah == null) {
      return;
    }

    _openSurah(context, selectedSurah);
  }

  void _openSurah(BuildContext context, SurahSummary surah) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuranDetailScreen(summary: surah),
      ),
    );
  }

  List<_PrayerGuideStepData> _buildSteps(AppLocalizations l10n) {
    return [
      _PrayerGuideStepData(
        number: 1,
        title: l10n.prayerGuideNiyyah,
        description: l10n.prayerGuideNiyyahDescription,
        positionArabicName: 'النِّيَّة',
        positionTransliteration: 'Niyyah',
        assetPath: 'assets/images/prayer_positions/niyyah.png',
        repetitionLabel: l10n.prayerGuideTimesHeart,
        note: l10n.prayerGuideNiyyahRecitationNote,
      ),
      _PrayerGuideStepData(
        number: 2,
        title: l10n.prayerGuideTakbir,
        description: l10n.prayerGuideTakbirDescription,
        positionArabicName: 'تكبيرة الإحرام',
        positionTransliteration: 'Takbiratul Ihram',
        assetPath: 'assets/images/prayer_positions/takbir.png',
        repetitionLabel: l10n.prayerGuideTimesOnce,
        recitations: const [
          _PrayerGuideRecitationData(
            arabic: 'اللَّهُ أَكْبَرُ',
            transliteration: 'Allahu Akbar',
            translationKey: _PrayerGuideTranslationKey.takbir,
          ),
        ],
      ),
      _PrayerGuideStepData(
        number: 3,
        title: l10n.prayerGuideQiyam,
        description: l10n.prayerGuideQiyamDescription,
        positionArabicName: 'القيام',
        positionTransliteration: 'Qiyam',
        assetPath: 'assets/images/prayer_positions/qiyam.png',
        repetitionLabel: l10n.prayerGuideTimesOnce,
        showsSurahActions: true,
        recitations: const [
          _PrayerGuideRecitationData(
            arabic:
                'سُبْحَانَكَ اللَّهُمَّ وَبِحَمْدِكَ وَتَبَارَكَ اسْمُكَ وَتَعَالَى جَدُّكَ وَلَا إِلَهَ غَيْرُكَ',
            transliteration:
                "Subhanaka Allahumma wa bihamdika wa tabaraka ismuka wa ta'ala jadduka wa la ilaha ghairuk",
            translationKey: _PrayerGuideTranslationKey.qiyam,
          ),
        ],
      ),
      _PrayerGuideStepData(
        number: 4,
        title: l10n.prayerGuideRuku,
        description: l10n.prayerGuideRukuDescription,
        positionArabicName: 'الركوع',
        positionTransliteration: 'Ruku',
        assetPath: 'assets/images/prayer_positions/ruku.png',
        repetitionLabel: l10n.prayerGuideTimesThree,
        recitations: const [
          _PrayerGuideRecitationData(
            arabic: 'سُبْحَانَ رَبِّيَ الْعَظِيمِ',
            transliteration: 'Subhana Rabbiyal Azim',
            translationKey: _PrayerGuideTranslationKey.ruku,
          ),
        ],
      ),
      _PrayerGuideStepData(
        number: 5,
        title: l10n.prayerGuideItidal,
        description: l10n.prayerGuideItidalDescription,
        positionArabicName: 'الاعتدال',
        positionTransliteration: "I'tidal",
        assetPath: 'assets/images/prayer_positions/itidal.png',
        repetitionLabel: l10n.prayerGuideTimesOnce,
        recitations: const [
          _PrayerGuideRecitationData(
            labelKey: _PrayerGuideLabelKey.whileRising,
            arabic: 'سَمِعَ اللَّهُ لِمَنْ حَمِدَهُ',
            transliteration: 'Sami Allahu liman hamidah',
            translationKey: _PrayerGuideTranslationKey.itidalRise,
          ),
          _PrayerGuideRecitationData(
            labelKey: _PrayerGuideLabelKey.whenStanding,
            arabic: 'رَبَّنَا وَلَكَ الْحَمْدُ',
            transliteration: 'Rabbana wa lakal hamd',
            translationKey: _PrayerGuideTranslationKey.itidalStand,
          ),
        ],
      ),
      _PrayerGuideStepData(
        number: 6,
        title: l10n.prayerGuideSujud,
        description: l10n.prayerGuideSujudDescription,
        positionArabicName: 'السجود',
        positionTransliteration: 'Sujud',
        assetPath: 'assets/images/prayer_positions/sujud.png',
        repetitionLabel: l10n.prayerGuideTimesThree,
        recitations: const [
          _PrayerGuideRecitationData(
            arabic: 'سُبْحَانَ رَبِّيَ الْأَعْلَى',
            transliteration: "Subhana Rabbiyal A'la",
            translationKey: _PrayerGuideTranslationKey.sujud,
          ),
        ],
      ),
      _PrayerGuideStepData(
        number: 7,
        title: l10n.prayerGuideJalsa,
        description: l10n.prayerGuideJalsaDescription,
        positionArabicName: 'الجلسة',
        positionTransliteration: 'Jalsa',
        assetPath: 'assets/images/prayer_positions/jalsa.png',
        repetitionLabel: l10n.prayerGuideTimesOneToThree,
        recitations: const [
          _PrayerGuideRecitationData(
            arabic: 'رَبِّ اغْفِرْ لِي',
            transliteration: 'Rabbighfirli',
            translationKey: _PrayerGuideTranslationKey.jalsa,
          ),
        ],
      ),
      _PrayerGuideStepData(
        number: 8,
        title: l10n.prayerGuideSujud,
        description: l10n.prayerGuideSecondSujudDescription,
        positionArabicName: 'السجود الثاني',
        positionTransliteration: 'Second sujud',
        assetPath: 'assets/images/prayer_positions/sujud.png',
        repetitionLabel: l10n.prayerGuideTimesThree,
        recitations: const [
          _PrayerGuideRecitationData(
            arabic: 'سُبْحَانَ رَبِّيَ الْأَعْلَى',
            transliteration: "Subhana Rabbiyal A'la",
            translationKey: _PrayerGuideTranslationKey.sujud,
          ),
        ],
      ),
      _PrayerGuideStepData(
        number: 9,
        title: l10n.prayerGuideTashahhud,
        description: l10n.prayerGuideTashahhudDescription,
        positionArabicName: 'التشهد',
        positionTransliteration: 'Tashahhud',
        assetPath: 'assets/images/prayer_positions/tashahhud.png',
        repetitionLabel: l10n.prayerGuideTimesOnce,
        recitations: const [
          _PrayerGuideRecitationData(
            arabic:
                'التَّحِيَّاتُ لِلَّهِ وَالصَّلَوَاتُ وَالطَّيِّبَاتُ، السَّلَامُ عَلَيْكَ أَيُّهَا النَّبِيُّ وَرَحْمَةُ اللَّهِ وَبَرَكَاتُهُ، السَّلَامُ عَلَيْنَا وَعَلَى عِبَادِ اللَّهِ الصَّالِحِينَ، أَشْهَدُ أَنْ لَا إِلَهَ إِلَّا اللَّهُ وَأَشْهَدُ أَنَّ مُحَمَّدًا عَبْدُهُ وَرَسُولُهُ',
            transliteration:
                'At-Tahiyyatu lillahi was-salawatu wat-tayyibat... Ashhadu an la ilaha illa Allah wa ashhadu anna Muhammadan abduhu wa rasuluh',
            translationKey: _PrayerGuideTranslationKey.tashahhud,
          ),
        ],
      ),
      _PrayerGuideStepData(
        number: 10,
        title: l10n.prayerGuideTaslim,
        description: l10n.prayerGuideTaslimRightDescription,
        positionArabicName: 'التسليم',
        positionTransliteration: 'Taslim',
        assetPath: 'assets/images/prayer_positions/taslim_right.png',
        repetitionLabel: l10n.prayerGuideTimesOnce,
        directionLabel: l10n.prayerGuideDirectionRight,
        recitations: const [
          _PrayerGuideRecitationData(
            arabic: 'السَّلَامُ عَلَيْكُمْ وَرَحْمَةُ اللَّهِ',
            transliteration: 'As-Salamu Alaykum wa Rahmatullah',
            translationKey: _PrayerGuideTranslationKey.taslim,
          ),
        ],
      ),
      _PrayerGuideStepData(
        number: 11,
        title: l10n.prayerGuideTaslim,
        description: l10n.prayerGuideTaslimLeftDescription,
        positionArabicName: 'التسليم',
        positionTransliteration: 'Taslim',
        assetPath: 'assets/images/prayer_positions/taslim_left.png',
        repetitionLabel: l10n.prayerGuideTimesOnce,
        directionLabel: l10n.prayerGuideDirectionLeft,
        recitations: const [
          _PrayerGuideRecitationData(
            arabic: 'السَّلَامُ عَلَيْكُمْ وَرَحْمَةُ اللَّهِ',
            transliteration: 'As-Salamu Alaykum wa Rahmatullah',
            translationKey: _PrayerGuideTranslationKey.taslim,
          ),
        ],
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

  String _rakaatFlowNote(AppLocalizations l10n, PrayerName prayer) {
    return switch (prayer) {
      PrayerName.fajr => l10n.prayerGuideCycleFajr,
      PrayerName.dhuhr => l10n.prayerGuideCycleDhuhr,
      PrayerName.asr => l10n.prayerGuideCycleAsr,
      PrayerName.maghrib => l10n.prayerGuideCycleMaghrib,
      PrayerName.isha => l10n.prayerGuideCycleIsha,
    };
  }
}

class _PrayerGuideHeader extends StatelessWidget {
  const _PrayerGuideHeader({
    required this.prayerLabel,
    required this.prayerArabic,
    required this.rakaatSummary,
    required this.flowNote,
    required this.overview,
    required this.isArabicOnly,
  });

  final String prayerLabel;
  final String prayerArabic;
  final String rakaatSummary;
  final String flowNote;
  final String overview;
  final bool isArabicOnly;

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tokens.bgSurface,
        borderRadius: BorderRadius.circular(26),
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
          _HeaderHighlight(text: rakaatSummary),
          const SizedBox(height: 10),
          _HeaderNote(text: overview),
          const SizedBox(height: 10),
          _HeaderNote(text: flowNote),
        ],
      ),
    );
  }
}

class _HeaderHighlight extends StatelessWidget {
  const _HeaderHighlight({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: tokens.primaryBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.primaryBorder),
      ),
      child: Text(
        text,
        style: GoogleFonts.dmSans(
          fontSize: 13,
          height: 1.55,
          fontWeight: FontWeight.w700,
          color: tokens.textPrimary,
        ),
      ),
    );
  }
}

class _HeaderNote extends StatelessWidget {
  const _HeaderNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: tokens.bgSurface2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.border),
      ),
      child: Text(
        text,
        style: GoogleFonts.dmSans(
          fontSize: 13,
          height: 1.6,
          color: tokens.textPrimary,
        ),
      ),
    );
  }
}

class _PrayerGuideStepPage extends StatelessWidget {
  const _PrayerGuideStepPage({
    required this.step,
    required this.totalSteps,
    required this.isArabicOnly,
    this.onOpenFatiha,
    this.onChooseSurah,
  });

  final _PrayerGuideStepData step;
  final int totalSteps;
  final bool isArabicOnly;
  final VoidCallback? onOpenFatiha;
  final VoidCallback? onChooseSurah;

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;
    final l10n = context.l10n;

    return Container(
      decoration: BoxDecoration(
        color: tokens.bgSurface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: tokens.border),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
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
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${step.number}/$totalSteps',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: tokens.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              height: 200,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: tokens.bgSurface2,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: tokens.border),
              ),
              child: Image.asset(
                step.assetPath,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              step.title,
              textAlign: isArabicOnly ? TextAlign.right : TextAlign.left,
              style: GoogleFonts.dmSans(
                fontSize: 21,
                fontWeight: FontWeight.w700,
                color: tokens.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                step.positionArabicName,
                style: GoogleFonts.amiri(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: tokens.primaryLight,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              step.positionTransliteration,
              textAlign: isArabicOnly ? TextAlign.right : TextAlign.left,
              style: GoogleFonts.dmSans(
                fontSize: 13,
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
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StepChip(text: step.repetitionLabel),
                if (step.directionLabel != null)
                  _StepChip(
                    text: step.directionLabel!,
                    usePrimary: false,
                  ),
              ],
            ),
            if (step.note != null) ...[
              const SizedBox(height: 14),
              _StepInfoCard(text: step.note!),
            ],
            if (step.recitations.isNotEmpty) ...[
              const SizedBox(height: 14),
              ...step.recitations.map(
                (recitation) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _PrayerRecitationCard(recitation: recitation),
                ),
              ),
            ],
            if (step.showsSurahActions) ...[
              const SizedBox(height: 4),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  FilledButton.icon(
                    onPressed: onOpenFatiha,
                    icon: const Icon(Icons.menu_book_rounded),
                    label: Text(l10n.prayerGuideOpenFatiha),
                  ),
                  OutlinedButton.icon(
                    onPressed: onChooseSurah,
                    icon: const Icon(Icons.auto_stories_rounded),
                    label: Text(l10n.prayerGuideChooseSurah),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PrayerRecitationCard extends StatelessWidget {
  const _PrayerRecitationCard({
    required this.recitation,
  });

  final _PrayerGuideRecitationData recitation;

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;
    final l10n = context.l10n;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.bgSurface2,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (recitation.labelKey != null) ...[
            _StepChip(
              text: _labelFor(l10n, recitation.labelKey!),
              usePrimary: false,
            ),
            const SizedBox(height: 12),
          ],
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              recitation.arabic,
              style: GoogleFonts.amiri(
                fontSize: 27,
                height: 1.7,
                fontWeight: FontWeight.w700,
                color: tokens.primaryLight,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            recitation.transliteration,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              height: 1.55,
              fontStyle: FontStyle.italic,
              color: tokens.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _translationFor(l10n, recitation.translationKey),
            style: GoogleFonts.dmSans(
              fontSize: 13,
              height: 1.6,
              color: tokens.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  String _labelFor(AppLocalizations l10n, _PrayerGuideLabelKey key) {
    return switch (key) {
      _PrayerGuideLabelKey.whileRising => l10n.prayerGuideWhileRising,
      _PrayerGuideLabelKey.whenStanding => l10n.prayerGuideWhenStanding,
    };
  }

  String _translationFor(
    AppLocalizations l10n,
    _PrayerGuideTranslationKey key,
  ) {
    return switch (key) {
      _PrayerGuideTranslationKey.takbir => l10n.prayerGuideTakbirMeaning,
      _PrayerGuideTranslationKey.qiyam => l10n.prayerGuideQiyamMeaning,
      _PrayerGuideTranslationKey.ruku => l10n.prayerGuideRukuMeaning,
      _PrayerGuideTranslationKey.itidalRise =>
        l10n.prayerGuideItidalRiseMeaning,
      _PrayerGuideTranslationKey.itidalStand =>
        l10n.prayerGuideItidalStandMeaning,
      _PrayerGuideTranslationKey.sujud => l10n.prayerGuideSujudMeaning,
      _PrayerGuideTranslationKey.jalsa => l10n.prayerGuideJalsaMeaning,
      _PrayerGuideTranslationKey.tashahhud =>
        l10n.prayerGuideTashahhudMeaning,
      _PrayerGuideTranslationKey.taslim => l10n.prayerGuideTaslimMeaning,
    };
  }
}

class _StepInfoCard extends StatelessWidget {
  const _StepInfoCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: tokens.primaryBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tokens.primaryBorder),
      ),
      child: Text(
        text,
        style: GoogleFonts.dmSans(
          fontSize: 13,
          height: 1.6,
          color: tokens.textPrimary,
        ),
      ),
    );
  }
}

class _StepChip extends StatelessWidget {
  const _StepChip({
    required this.text,
    this.usePrimary = true,
  });

  final String text;
  final bool usePrimary;

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: usePrimary ? tokens.primaryBg : tokens.bgSurface2,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: usePrimary ? tokens.primaryBorder : tokens.border,
        ),
      ),
      child: Text(
        text,
        style: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: usePrimary ? tokens.primaryLight : tokens.textSecondary,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

enum _PrayerGuideTranslationKey {
  takbir,
  qiyam,
  ruku,
  itidalRise,
  itidalStand,
  sujud,
  jalsa,
  tashahhud,
  taslim,
}

enum _PrayerGuideLabelKey {
  whileRising,
  whenStanding,
}

class _PrayerGuideStepData {
  const _PrayerGuideStepData({
    required this.number,
    required this.title,
    required this.description,
    required this.positionArabicName,
    required this.positionTransliteration,
    required this.assetPath,
    required this.repetitionLabel,
    this.directionLabel,
    this.note,
    this.recitations = const [],
    this.showsSurahActions = false,
  });

  final int number;
  final String title;
  final String description;
  final String positionArabicName;
  final String positionTransliteration;
  final String assetPath;
  final String repetitionLabel;
  final String? directionLabel;
  final String? note;
  final List<_PrayerGuideRecitationData> recitations;
  final bool showsSurahActions;
}

class _PrayerGuideRecitationData {
  const _PrayerGuideRecitationData({
    required this.arabic,
    required this.transliteration,
    required this.translationKey,
    this.labelKey,
  });

  final String arabic;
  final String transliteration;
  final _PrayerGuideTranslationKey translationKey;
  final _PrayerGuideLabelKey? labelKey;
}
