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

  bool _shouldShowSurahChoiceInQiyam(int rakaatNumber) {
    return rakaatNumber <= 2 ||
        _isFinalQiyamRakaah(widget.prayerName, rakaatNumber);
  }

  bool _isFinalQiyamRakaah(PrayerName prayer, int rakaatNumber) {
    switch (prayer) {
      case PrayerName.fajr:
        return false;
      case PrayerName.dhuhr:
      case PrayerName.asr:
      case PrayerName.isha:
        return rakaatNumber == 3 || rakaatNumber == 4;
      case PrayerName.maghrib:
        return rakaatNumber == 3;
    }
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
    final pages = _buildPages(l10n);
    final prayerLabel = _localizedPrayerName(widget.prayerName, languageCode);
    final rakaatSummary = _rakaatsSummary(l10n, widget.prayerName);
    final flowNote = _rakaatFlowNote(l10n, widget.prayerName);
    final currentPageData = pages[_currentPage.clamp(0, pages.length - 1)];

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
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: pages.length,
                onPageChanged: (value) {
                  setState(() => _currentPage = value);
                },
                itemBuilder: (context, index) {
                  final page = pages[index];
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: page.isSeparator
                        ? _PrayerGuideSeparatorPage(
                            rakaatNumber: page.rakaatNumber,
                            pagePosition: index + 1,
                            totalPages: pages.length,
                            showHeader: page.rakaatNumber == 1,
                            prayerLabel: prayerLabel,
                            prayerArabic: widget.prayerName.displayNameArabic,
                            rakaatSummary: rakaatSummary,
                            flowNote: flowNote,
                            overview: l10n.prayerGuideOneRakaatIntro,
                            isArabicOnly: isArabicOnly,
                          )
                        : _PrayerGuideStepPage(
                            step: page.step!,
                            pagePosition: index + 1,
                            totalPages: pages.length,
                            isArabicOnly: isArabicOnly,
                            onOpenFatiha:
                                page.step!.showsOpenFatiha && fatiha != null
                                    ? () => _openSurah(context, fatiha)
                                    : null,
                            onChooseSurah: page.step!.showsChooseSurah
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
                    _pageIndicatorLabel(
                      l10n,
                      currentPageData,
                      _currentPage + 1,
                      pages.length,
                    ),
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: tokens.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 8,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(
                          pages.length,
                          (index) => Padding(
                            padding: EdgeInsets.only(
                              right: index == pages.length - 1 ? 0 : 8,
                            ),
                            child: AnimatedContainer(
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
    final selectableSurahs =
        surahs.where((surah) => surah.number >= 2).toList();
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

  List<_PrayerGuidePageData> _buildPages(AppLocalizations l10n) {
    final pages = <_PrayerGuidePageData>[];
    var stepNumber = 1;

    const atTahiyyatRecitation = _PrayerGuideRecitationData(
      arabic:
          'التَّحِيَّاتُ لِلَّهِ وَالصَّلَوَاتُ وَالطَّيِّبَاتُ، السَّلَامُ عَلَيْكَ أَيُّهَا النَّبِيُّ وَرَحْمَةُ اللَّهِ وَبَرَكَاتُهُ، السَّلَامُ عَلَيْنَا وَعَلَى عِبَادِ اللَّهِ الصَّالِحِينَ، أَشْهَدُ أَنْ لَا إِلَهَ إِلَّا اللَّهُ وَأَشْهَدُ أَنَّ مُحَمَّدًا عَبْدُهُ وَرَسُولُهُ',
      transliteration:
          'At-Tahiyyatu lillahi was-salawatu wat-tayyibat, as-salamu alayka ayyuhan-nabiyyu wa rahmatullahi wa barakatuh, as-salamu alayna wa ala ibadillahis-salihin, ashhadu an la ilaha illa Allah wa ashhadu anna Muhammadan abduhu wa rasuluh',
      translationKey: _PrayerGuideTranslationKey.atTahiyyat,
    );
    const salawatRecitation = _PrayerGuideRecitationData(
      arabic:
          'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ، كَمَا صَلَّيْتَ عَلَى إِبْرَاهِيمَ وَعَلَى آلِ إِبْرَاهِيمَ، إِنَّكَ حَمِيدٌ مَجِيدٌ',
      transliteration:
          'Allahumma salli ala Muhammadin wa ala ali Muhammad, kama sallayta ala Ibrahima wa ala ali Ibrahima, innaka Hamidun Majid',
      translationKey: _PrayerGuideTranslationKey.salawat,
    );

    void addSeparator(int rakaatNumber) {
      pages.add(_PrayerGuidePageData.separator(rakaatNumber: rakaatNumber));
    }

    void addStep({
      required int rakaatNumber,
      required String title,
      required String description,
      required String positionArabicName,
      required String positionTransliteration,
      required String assetPath,
      required String repetitionLabel,
      String? directionLabel,
      String? note,
      List<_PrayerGuideRecitationData> recitations = const [],
      bool showsOpenFatiha = false,
      bool showsChooseSurah = false,
    }) {
      pages.add(
        _PrayerGuidePageData.step(
          rakaatNumber: rakaatNumber,
          step: _PrayerGuideStepData(
            number: stepNumber++,
            rakaatNumber: rakaatNumber,
            title: title,
            description: description,
            positionArabicName: positionArabicName,
            positionTransliteration: positionTransliteration,
            assetPath: assetPath,
            repetitionLabel: repetitionLabel,
            directionLabel: directionLabel,
            note: note,
            recitations: recitations,
            showsOpenFatiha: showsOpenFatiha,
            showsChooseSurah: showsChooseSurah,
          ),
        ),
      );
    }

    void addNiyyah(int rakaatNumber) {
      addStep(
        rakaatNumber: rakaatNumber,
        title: l10n.prayerGuideNiyyah,
        description: l10n.prayerGuideNiyyahDescription,
        positionArabicName: 'النِّيَّة',
        positionTransliteration: 'Niyyah',
        assetPath: 'assets/images/prayer_positions/niyyah.webp',
        repetitionLabel: l10n.prayerGuideTimesHeart,
        note: l10n.prayerGuideNiyyahRecitationNote,
      );
    }

    void addTakbir(int rakaatNumber) {
      addStep(
        rakaatNumber: rakaatNumber,
        title: l10n.prayerGuideTakbir,
        description: l10n.prayerGuideTakbirDescription,
        positionArabicName: 'تكبيرة الإحرام',
        positionTransliteration: 'Takbiratul Ihram',
        assetPath: 'assets/images/prayer_positions/takbir.webp',
        repetitionLabel: l10n.prayerGuideTimesOnce,
        recitations: const [
          _PrayerGuideRecitationData(
            arabic: 'اللَّهُ أَكْبَرُ',
            transliteration: 'Allahu Akbar',
            translationKey: _PrayerGuideTranslationKey.takbir,
          ),
        ],
      );
    }

    void addSubhanaka(int rakaatNumber) {
      addStep(
        rakaatNumber: rakaatNumber,
        title: l10n.prayerGuideSubhanaka,
        description: l10n.prayerGuideSubhanakaDescription,
        positionArabicName: 'دعاء الاستفتاح',
        positionTransliteration: 'Subhanaka',
        assetPath: 'assets/images/prayer_positions/qiyam.webp',
        repetitionLabel: l10n.prayerGuideTimesOnce,
        recitations: const [
          _PrayerGuideRecitationData(
            arabic:
                'سُبْحَانَكَ اللَّهُمَّ وَبِحَمْدِكَ وَتَبَارَكَ اسْمُكَ وَتَعَالَى جَدُّكَ وَلَا إِلَهَ غَيْرُكَ',
            transliteration:
                "Subhanaka Allahumma wa bihamdika wa tabaraka ismuka wa ta'ala jadduka wa la ilaha ghairuk",
            translationKey: _PrayerGuideTranslationKey.subhanaka,
          ),
        ],
      );
    }

    void addQiyam(
      int rakaatNumber, {
      required bool includeAdditionalSurah,
    }) {
      addStep(
        rakaatNumber: rakaatNumber,
        title: l10n.prayerGuideQiyam,
        description: includeAdditionalSurah
            ? l10n.prayerGuideQiyamWithSurahDescription
            : l10n.prayerGuideQiyamFatihaOnlyDescription,
        positionArabicName: 'القيام',
        positionTransliteration: 'Qiyam',
        assetPath: 'assets/images/prayer_positions/qiyam.webp',
        repetitionLabel: l10n.prayerGuideTimesOnce,
        showsOpenFatiha: true,
        showsChooseSurah: includeAdditionalSurah,
      );
    }

    void addRuku(int rakaatNumber) {
      addStep(
        rakaatNumber: rakaatNumber,
        title: l10n.prayerGuideRuku,
        description: l10n.prayerGuideRukuDescription,
        positionArabicName: 'الركوع',
        positionTransliteration: 'Ruku',
        assetPath: 'assets/images/prayer_positions/ruku.webp',
        repetitionLabel: l10n.prayerGuideTimesThree,
        recitations: const [
          _PrayerGuideRecitationData(
            arabic: 'سُبْحَانَ رَبِّيَ الْعَظِيمِ',
            transliteration: 'Subhana Rabbiyal Azim',
            translationKey: _PrayerGuideTranslationKey.ruku,
          ),
        ],
      );
    }

    void addItidal(int rakaatNumber) {
      addStep(
        rakaatNumber: rakaatNumber,
        title: l10n.prayerGuideItidal,
        description: l10n.prayerGuideItidalDescription,
        positionArabicName: 'الاعتدال',
        positionTransliteration: "I'tidal",
        assetPath: 'assets/images/prayer_positions/itidal.webp',
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
      );
    }

    void addSujudOne(int rakaatNumber) {
      addStep(
        rakaatNumber: rakaatNumber,
        title: l10n.prayerGuideSujud,
        description: l10n.prayerGuideSujudDescription,
        positionArabicName: 'السجود',
        positionTransliteration: 'Sujud',
        assetPath: 'assets/images/prayer_positions/sujud.webp',
        repetitionLabel: l10n.prayerGuideTimesThree,
        recitations: const [
          _PrayerGuideRecitationData(
            arabic: 'سُبْحَانَ رَبِّيَ الْأَعْلَى',
            transliteration: "Subhana Rabbiyal A'la",
            translationKey: _PrayerGuideTranslationKey.sujud,
          ),
        ],
      );
    }

    void addJalsa(int rakaatNumber) {
      addStep(
        rakaatNumber: rakaatNumber,
        title: l10n.prayerGuideJalsa,
        description: l10n.prayerGuideJalsaDescription,
        positionArabicName: 'الجلسة',
        positionTransliteration: 'Jalsa',
        assetPath: 'assets/images/prayer_positions/jalsa.webp',
        repetitionLabel: l10n.prayerGuideTimesOneToThree,
        recitations: const [
          _PrayerGuideRecitationData(
            arabic: 'رَبِّ اغْفِرْ لِي',
            transliteration: 'Rabbighfirli',
            translationKey: _PrayerGuideTranslationKey.jalsa,
          ),
        ],
      );
    }

    void addSujudTwo(int rakaatNumber) {
      addStep(
        rakaatNumber: rakaatNumber,
        title: l10n.prayerGuideSujud,
        description: l10n.prayerGuideSecondSujudDescription,
        positionArabicName: 'السجود الثاني',
        positionTransliteration: 'Second sujud',
        assetPath: 'assets/images/prayer_positions/sujud.webp',
        repetitionLabel: l10n.prayerGuideTimesThree,
        recitations: const [
          _PrayerGuideRecitationData(
            arabic: 'سُبْحَانَ رَبِّيَ الْأَعْلَى',
            transliteration: "Subhana Rabbiyal A'la",
            translationKey: _PrayerGuideTranslationKey.sujud,
          ),
        ],
      );
    }

    void addShortTashahhud(int rakaatNumber) {
      addStep(
        rakaatNumber: rakaatNumber,
        title: l10n.prayerGuideTashahhud,
        description: l10n.prayerGuideTashahhudShortDescription,
        positionArabicName: 'التشهد',
        positionTransliteration: 'Tashahhud',
        assetPath: 'assets/images/prayer_positions/tashahhud2.webp',
        repetitionLabel: l10n.prayerGuideTimesOnce,
        recitations: const [atTahiyyatRecitation],
      );
    }

    void addCompleteTashahhud(int rakaatNumber) {
      addStep(
        rakaatNumber: rakaatNumber,
        title: l10n.prayerGuideTashahhud,
        description: l10n.prayerGuideTashahhudCompleteDescription,
        positionArabicName: 'التشهد الأخير',
        positionTransliteration: 'Complete Tashahhud',
        assetPath: 'assets/images/prayer_positions/tashahhud2.webp',
        repetitionLabel: l10n.prayerGuideTimesOnce,
        note: l10n.prayerGuideTashahhudCompleteNote,
        recitations: const [
          atTahiyyatRecitation,
          salawatRecitation,
        ],
      );
    }

    void addTaslims(int rakaatNumber) {
      addStep(
        rakaatNumber: rakaatNumber,
        title: l10n.prayerGuideTaslim,
        description: l10n.prayerGuideTaslimRightDescription,
        positionArabicName: 'التسليم',
        positionTransliteration: 'Taslim',
        assetPath: 'assets/images/prayer_positions/taslim_right.webp',
        repetitionLabel: l10n.prayerGuideTimesOnce,
        directionLabel: l10n.prayerGuideDirectionRight,
        recitations: const [
          _PrayerGuideRecitationData(
            arabic: 'السَّلَامُ عَلَيْكُمْ وَرَحْمَةُ اللَّهِ',
            transliteration: 'As-Salamu Alaykum wa Rahmatullah',
            translationKey: _PrayerGuideTranslationKey.taslim,
          ),
        ],
      );
      addStep(
        rakaatNumber: rakaatNumber,
        title: l10n.prayerGuideTaslim,
        description: l10n.prayerGuideTaslimLeftDescription,
        positionArabicName: 'التسليم',
        positionTransliteration: 'Taslim',
        assetPath: 'assets/images/prayer_positions/taslim_left.webp',
        repetitionLabel: l10n.prayerGuideTimesOnce,
        directionLabel: l10n.prayerGuideDirectionLeft,
        recitations: const [
          _PrayerGuideRecitationData(
            arabic: 'السَّلَامُ عَلَيْكُمْ وَرَحْمَةُ اللَّهِ',
            transliteration: 'As-Salamu Alaykum wa Rahmatullah',
            translationKey: _PrayerGuideTranslationKey.taslim,
          ),
        ],
      );
    }

    void addRakaatCore(
      int rakaatNumber, {
      required bool includeExtraSurah,
      required bool isOpeningRakaat,
    }) {
      if (isOpeningRakaat) {
        addNiyyah(rakaatNumber);
        addTakbir(rakaatNumber);
        addSubhanaka(rakaatNumber);
      }
      addQiyam(
        rakaatNumber,
        includeAdditionalSurah: includeExtraSurah,
      );
      addRuku(rakaatNumber);
      addItidal(rakaatNumber);
      addSujudOne(rakaatNumber);
      addJalsa(rakaatNumber);
      addSujudTwo(rakaatNumber);
    }

    switch (widget.prayerName) {
      case PrayerName.fajr:
        addSeparator(1);
        addRakaatCore(
          1,
          includeExtraSurah: _shouldShowSurahChoiceInQiyam(1),
          isOpeningRakaat: true,
        );
        addSeparator(2);
        addRakaatCore(
          2,
          includeExtraSurah: _shouldShowSurahChoiceInQiyam(2),
          isOpeningRakaat: false,
        );
        addCompleteTashahhud(2);
        addTaslims(2);
      case PrayerName.dhuhr:
        addSeparator(1);
        addRakaatCore(
          1,
          includeExtraSurah: _shouldShowSurahChoiceInQiyam(1),
          isOpeningRakaat: true,
        );
        addSeparator(2);
        addRakaatCore(
          2,
          includeExtraSurah: _shouldShowSurahChoiceInQiyam(2),
          isOpeningRakaat: false,
        );
        addShortTashahhud(2);
        addSeparator(3);
        addRakaatCore(
          3,
          includeExtraSurah: _shouldShowSurahChoiceInQiyam(3),
          isOpeningRakaat: false,
        );
        addSeparator(4);
        addRakaatCore(
          4,
          includeExtraSurah: _shouldShowSurahChoiceInQiyam(4),
          isOpeningRakaat: false,
        );
        addCompleteTashahhud(4);
        addTaslims(4);
      case PrayerName.asr:
      case PrayerName.isha:
        addSeparator(1);
        addRakaatCore(
          1,
          includeExtraSurah: _shouldShowSurahChoiceInQiyam(1),
          isOpeningRakaat: true,
        );
        addSeparator(2);
        addRakaatCore(
          2,
          includeExtraSurah: _shouldShowSurahChoiceInQiyam(2),
          isOpeningRakaat: false,
        );
        addShortTashahhud(2);
        addSeparator(3);
        addRakaatCore(
          3,
          includeExtraSurah: _shouldShowSurahChoiceInQiyam(3),
          isOpeningRakaat: false,
        );
        addSeparator(4);
        addRakaatCore(
          4,
          includeExtraSurah: _shouldShowSurahChoiceInQiyam(4),
          isOpeningRakaat: false,
        );
        addCompleteTashahhud(4);
        addTaslims(4);
      case PrayerName.maghrib:
        addSeparator(1);
        addRakaatCore(
          1,
          includeExtraSurah: _shouldShowSurahChoiceInQiyam(1),
          isOpeningRakaat: true,
        );
        addSeparator(2);
        addRakaatCore(
          2,
          includeExtraSurah: _shouldShowSurahChoiceInQiyam(2),
          isOpeningRakaat: false,
        );
        addShortTashahhud(2);
        addSeparator(3);
        addRakaatCore(
          3,
          includeExtraSurah: _shouldShowSurahChoiceInQiyam(3),
          isOpeningRakaat: false,
        );
        addCompleteTashahhud(3);
        addTaslims(3);
    }

    return pages;
  }

  String _pageIndicatorLabel(
    AppLocalizations l10n,
    _PrayerGuidePageData page,
    int pagePosition,
    int totalPages,
  ) {
    final primaryLabel = page.isSeparator
        ? l10n.prayerGuideRakaatTitle(page.rakaatNumber)
        : '${l10n.prayerGuideStep} ${page.step!.number}';
    return '$primaryLabel · $pagePosition / $totalPages';
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

class _PrayerGuideSeparatorPage extends StatelessWidget {
  const _PrayerGuideSeparatorPage({
    required this.rakaatNumber,
    required this.pagePosition,
    required this.totalPages,
    required this.showHeader,
    required this.prayerLabel,
    required this.prayerArabic,
    required this.rakaatSummary,
    required this.flowNote,
    required this.overview,
    required this.isArabicOnly,
  });

  final int rakaatNumber;
  final int pagePosition;
  final int totalPages;
  final bool showHeader;
  final String prayerLabel;
  final String prayerArabic;
  final String rakaatSummary;
  final String flowNote;
  final String overview;
  final bool isArabicOnly;

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
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showHeader) ...[
              _PrayerGuideHeader(
                prayerLabel: prayerLabel,
                prayerArabic: prayerArabic,
                rakaatSummary: rakaatSummary,
                flowNote: flowNote,
                overview: overview,
                isArabicOnly: isArabicOnly,
              ),
              const SizedBox(height: 16),
            ],
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '$pagePosition/$totalPages',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: tokens.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
              decoration: BoxDecoration(
                color: tokens.primaryBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: tokens.primaryBorder),
              ),
              child: Column(
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: tokens.bgSurface,
                      shape: BoxShape.circle,
                      border: Border.all(color: tokens.primaryBorder),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$rakaatNumber',
                      style: GoogleFonts.dmSans(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: tokens.primaryLight,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    l10n.prayerGuideRakaatTitle(rakaatNumber),
                    textAlign: TextAlign.center,
                    style: isArabicOnly
                        ? GoogleFonts.amiri(
                            fontSize: 34,
                            fontWeight: FontWeight.w700,
                            color: tokens.primaryLight,
                          )
                        : GoogleFonts.dmSerifDisplay(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            color: tokens.primaryLight,
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
}

class _PrayerGuideStepPage extends StatelessWidget {
  const _PrayerGuideStepPage({
    required this.step,
    required this.pagePosition,
    required this.totalPages,
    required this.isArabicOnly,
    this.onOpenFatiha,
    this.onChooseSurah,
  });

  final _PrayerGuideStepData step;
  final int pagePosition;
  final int totalPages;
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
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _StepChip(text: '${l10n.prayerGuideStep} ${step.number}'),
                      _StepChip(
                        text: l10n.prayerGuideRakaatTitle(step.rakaatNumber),
                        usePrimary: false,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$pagePosition/$totalPages',
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
              style: tokens.transliterationTextStyle(
                fontSize: 13,
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
            if (step.showsOpenFatiha || step.showsChooseSurah) ...[
              const SizedBox(height: 4),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  if (step.showsOpenFatiha)
                    FilledButton.icon(
                      onPressed: onOpenFatiha,
                      icon: const Icon(Icons.menu_book_rounded),
                      label: Text(l10n.prayerGuideOpenFatiha),
                    ),
                  if (step.showsChooseSurah)
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
            style: tokens.transliterationTextStyle(
              fontSize: 13,
              height: 1.55,
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
      _PrayerGuideTranslationKey.subhanaka => l10n.prayerGuideQiyamMeaning,
      _PrayerGuideTranslationKey.ruku => l10n.prayerGuideRukuMeaning,
      _PrayerGuideTranslationKey.itidalRise =>
        l10n.prayerGuideItidalRiseMeaning,
      _PrayerGuideTranslationKey.itidalStand =>
        l10n.prayerGuideItidalStandMeaning,
      _PrayerGuideTranslationKey.sujud => l10n.prayerGuideSujudMeaning,
      _PrayerGuideTranslationKey.jalsa => l10n.prayerGuideJalsaMeaning,
      _PrayerGuideTranslationKey.atTahiyyat => l10n.prayerGuideTashahhudMeaning,
      _PrayerGuideTranslationKey.salawat => l10n.prayerGuideSalawatMeaning,
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
  subhanaka,
  ruku,
  itidalRise,
  itidalStand,
  sujud,
  jalsa,
  atTahiyyat,
  salawat,
  taslim,
}

enum _PrayerGuideLabelKey {
  whileRising,
  whenStanding,
}

class _PrayerGuidePageData {
  const _PrayerGuidePageData.separator({
    required this.rakaatNumber,
  }) : step = null;

  const _PrayerGuidePageData.step({
    required this.rakaatNumber,
    required this.step,
  });

  final int rakaatNumber;
  final _PrayerGuideStepData? step;

  bool get isSeparator => step == null;
}

class _PrayerGuideStepData {
  const _PrayerGuideStepData({
    required this.number,
    required this.rakaatNumber,
    required this.title,
    required this.description,
    required this.positionArabicName,
    required this.positionTransliteration,
    required this.assetPath,
    required this.repetitionLabel,
    this.directionLabel,
    this.note,
    this.recitations = const [],
    this.showsOpenFatiha = false,
    this.showsChooseSurah = false,
  });

  final int number;
  final int rakaatNumber;
  final String title;
  final String description;
  final String positionArabicName;
  final String positionTransliteration;
  final String assetPath;
  final String repetitionLabel;
  final String? directionLabel;
  final String? note;
  final List<_PrayerGuideRecitationData> recitations;
  final bool showsOpenFatiha;
  final bool showsChooseSurah;
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
