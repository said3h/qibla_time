import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hijri/hijri_calendar.dart';

import '../../../core/localization/locale_controller.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/spanish_date_labels.dart';
import '../../../l10n/l10n.dart';
import '../../calendar/screens/calendar_screen.dart';
import '../../dhikr/screens/dhikr_screen.dart';
import '../../dhikr/services/dhikr_service.dart';
import '../../focus/screens/focus_mode_screen.dart';
import '../../hadith/screens/hadith_library_screen.dart';
import '../../hadith/widgets/daily_hadith_widget.dart';
import '../../library/screens/islamic_books_screen.dart';
import '../../library/widgets/daily_book_widget.dart';
import '../../prayer/screens/prayer_guide_screen.dart';
import '../../quran/models/quran_models.dart';
import '../../quran/screens/quran_screen.dart';
import '../../quran/services/quran_reading_service.dart';
import '../../support/screens/settings_screen.dart';
import '../../support/screens/purification_guide_screen.dart';
import '../../tracking/models/tracking_models.dart';
import '../../tracking/screens/analytics_screen.dart';
import '../../tracking/services/tracking_service.dart';
import '../domain/entities/home_insight.dart';
import '../domain/entities/next_prayer_info.dart';
import '../domain/entities/prayer_name.dart';
import '../domain/entities/prayer_location_diagnostic.dart';
import '../domain/entities/prayer_schedule.dart';
import '../domain/entities/ramadan_status.dart';
import '../domain/entities/resolved_prayer_schedule.dart';
import '../domain/usecases/generate_home_insights.dart';
import '../presentation/providers/ramadan_providers.dart';
import '../presentation/providers/prayer_times_providers.dart';
import '../../period/services/period_mode_service.dart';
import '../services/adhan_manager.dart';
import '../services/travel_mode_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const _weekdaysArabic = [
    'الاثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
    'الأحد',
  ];
  static const _generateHomeInsights = GenerateHomeInsightsUseCase();

  late DateTime _selectedDate;
  late final ScrollController _calendarController;

  @override
  void initState() {
    super.initState();
    _selectedDate = _dateOnly(DateTime.now());
    _calendarController = ScrollController(initialScrollOffset: 6 * 62.0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adhanManagerProvider).scheduleTodayAdhans();
    });
  }

  @override
  void dispose() {
    _calendarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;
    final today = _dateOnly(DateTime.now());
    final isSelectedToday = _isSameDay(_selectedDate, today);
    final prayerScheduleAsync = ref.watch(prayerScheduleProvider);
    final selectedPrayerScheduleAsync = isSelectedToday
        ? prayerScheduleAsync
        : ref.watch(prayerScheduleForDateProvider(_selectedDate));
    final nextPrayerInfo = ref.watch(nextPrayerInfoProvider);
    final countdownAsync = ref.watch(prayerCountdownProvider);
    final bannerAsync = ref.watch(travelBannerProvider);
    final connectivityAsync = ref.watch(connectivityStatusProvider);
    final locationLabelAsync = ref.watch(lastLocationLabelProvider);
    final locationDiagnosticAsync = ref.watch(prayerLocationDiagnosticProvider);
    final ramadanStatusAsync = ref.watch(ramadanStatusProvider);
    final lastReadingAsync = ref.watch(lastReadingProvider);
    final dhikrSnapshotAsync = ref.watch(dhikrSnapshotProvider);
    final tracking = ref.watch(prayerTrackingProvider);
    final streak = tracking.currentStreak;
    final selectedCompletedPrayers = tracking.completedPrayersFor(_selectedDate);
    final selectedNextPrayerInfo = isSelectedToday ? nextPrayerInfo : null;
    final selectedCountdown = isSelectedToday ? countdownAsync.value : null;

    return Scaffold(
      backgroundColor: tokens.bgPage,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _blend(tokens.primary, tokens.bgPage, _isLightTheme(tokens) ? 0.03 : 0.06),
              tokens.bgPage,
              _blend(tokens.accent, tokens.bgApp, _isLightTheme(tokens) ? 0.02 : 0.04),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(prayerScheduleProvider);
              ref.invalidate(nextPrayerInfoProvider);
              ref.invalidate(prayerCountdownProvider);
              ref.invalidate(prayerScheduleForDateProvider(_selectedDate));
            },
            color: tokens.primary,
            backgroundColor: tokens.bgSurface,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildHeader(
                  context,
                  tokens,
                  locationLabelAsync.valueOrNull,
                  connectivityAsync.valueOrNull ?? true,
                ),
                _buildPeriodModeBanner(context, tokens),
                _buildCalendarStrip(tokens),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: selectedPrayerScheduleAsync.when(
                    data: (resolvedSchedule) => _buildHeroSection(
                      resolvedSchedule,
                      selectedNextPrayerInfo,
                      selectedCountdown,
                      tokens,
                      streak,
                      locationDiagnosticAsync.valueOrNull,
                      _selectedDate,
                    ),
                    loading: () => _buildLoadingHero(tokens),
                    error: (_, __) => _buildFallbackHero(
                      tokens,
                      locationDiagnosticAsync.valueOrNull,
                    ),
                  ),
                ),
                selectedPrayerScheduleAsync.when(
                  data: (resolvedSchedule) => _buildPremiumPrayerSection(
                    resolvedSchedule?.schedule,
                    selectedNextPrayerInfo,
                    selectedCompletedPrayers,
                    _selectedDate,
                    tokens,
                  ),
                  loading: () => _buildPremiumPrayerSkeleton(tokens),
                  error: (_, __) => _buildPremiumPrayerFallback(
                    tokens,
                    locationDiagnosticAsync.valueOrNull,
                  ),
                ),
                bannerAsync.when(
                  data: (banner) => banner == null
                      ? const SizedBox.shrink()
                      : _buildTravelBanner(tokens, banner),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const DailyHadithWidget(),
                const DailyBookWidget(),
                _buildRamadanCard(
                  tokens,
                  prayerScheduleAsync.valueOrNull?.schedule,
                  ramadanStatusAsync.valueOrNull,
                ),
                _buildRamadanGoalsCard(
                  context,
                  tokens,
                  prayerScheduleAsync.valueOrNull?.schedule,
                  ramadanStatusAsync.valueOrNull,
                  tracking,
                  lastReadingAsync.valueOrNull,
                  dhikrSnapshotAsync.valueOrNull,
                ),
                _buildQuickActions(tokens),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    QiblaTokens tokens,
    String? locationLabel,
    bool isOnline,
  ) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _blend(tokens.primary, tokens.bgSurface, _isLightTheme(tokens) ? 0.08 : 0.14),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _blend(tokens.primary, tokens.border, 0.18)),
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 18,
              color: tokens.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Qibla Time',
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: tokens.primary,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.homeHeaderStatusLine(
                    isOnline ? l10n.homeHeaderOnline : l10n.homeHeaderOffline,
                    locationLabel ?? l10n.homeHeaderLocationUnavailable,
                  ),
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    color: tokens.textSecondary,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: _blend(tokens.bgSurface2, tokens.bgSurface, _isLightTheme(tokens) ? 0.7 : 0.88),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _blend(tokens.primary, tokens.border, 0.12)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(_isLightTheme(tokens) ? 0.04 : 0.16),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: IconButton(
              tooltip: l10n.settingsTitle,
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
              icon: Icon(Icons.tune, size: 18, color: tokens.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodModeBanner(BuildContext context, QiblaTokens tokens) {
    final periodEnabledAsync = ref.watch(periodModeEnabledProvider);
    final isEnabled = periodEnabledAsync.valueOrNull ?? false;
    if (!isEnabled) return const SizedBox.shrink();

    final l10n = context.l10n;
    final color = const Color(0xFFD17B8A);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SettingsScreen()),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: color.withOpacity(0.10),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.30)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.pause_circle_outline, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                l10n.periodModeActive,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTravelBanner(QiblaTokens tokens, String message) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: tokens.primaryBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: tokens.primaryBorder),
        ),
        child: Row(
          children: [
            Icon(Icons.flight_takeoff, color: tokens.primary, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: tokens.textPrimary,
                ),
              ),
            ),
            IconButton(
              onPressed: () async {
                await ref.read(travelModeServiceProvider).clearPendingBanner();
                ref.invalidate(travelBannerProvider);
              },
              icon: Icon(Icons.close, size: 16, color: tokens.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarStrip(QiblaTokens tokens) {
    final l10n = context.l10n;
    final today = _dateOnly(DateTime.now());
    final dates =
        List.generate(15, (index) => today.subtract(Duration(days: 6 - index)));

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.homeCalendarStripTitle,
                  style: GoogleFonts.dmSans(
                    fontSize: 9,
                    letterSpacing: 1.6,
                    color: tokens.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                _formatCompactDate(_selectedDate),
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  color: tokens.primaryLight,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 104,
            child: ListView.separated(
              controller: _calendarController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: dates.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, index) {
                final date = dates[index];
                final hijri = HijriCalendar.fromDate(date);
                final isToday = _isSameDay(date, today);
                final isSelected = _isSameDay(date, _selectedDate);
                final hasEvent = hijri.hDay == 1 || hijri.hDay == 15;

                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedDate = _dateOnly(date);
                    });
                  },
                  borderRadius: BorderRadius.circular(22),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    width: 78,
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isSelected
                            ? [
                                _blend(tokens.primary, tokens.bgSurface, 0.22),
                                _blend(tokens.primary, tokens.bgSurface, 0.08),
                              ]
                            : [
                                _blend(tokens.bgSurface2, tokens.bgSurface, 0.86),
                                tokens.bgSurface,
                              ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isSelected
                            ? tokens.primary.withOpacity(0.35)
                            : isToday
                                ? tokens.primaryBorder
                                : tokens.border,
                        width: isSelected ? 1.4 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected
                              ? tokens.primary.withOpacity(0.16)
                              : Colors.black.withOpacity(0.08),
                          blurRadius: isSelected ? 18 : 10,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          SpanishDateLabels.shortWeekday(date),
                          style: GoogleFonts.dmSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? tokens.primaryLight : tokens.textSecondary,
                          ),
                        ),
                        SizedBox(
                          height: 14,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              _weekdaysArabic[date.weekday - 1],
                              style: GoogleFonts.amiri(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isSelected ? tokens.primary : tokens.textMuted,
                                height: 1,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${date.day}',
                          style: GoogleFonts.dmSans(
                            fontSize: 19,
                            fontWeight: FontWeight.w500,
                            color: tokens.textPrimary,
                          ),
                        ),
                        Text(
                          '${hijri.hDay} ${hijri.getShortMonthName()}',
                          style: GoogleFonts.dmSans(
                            fontSize: 8,
                            color: isSelected ? tokens.primaryLight : tokens.textMuted,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        if (isSelected)
                          Container(
                            width: 22,
                            height: 4,
                            decoration: BoxDecoration(
                              color: tokens.primary,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          )
                        else if (hasEvent)
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: tokens.primary,
                              shape: BoxShape.circle,
                            ),
                          )
                        else
                          const SizedBox(height: 5),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(
    ResolvedPrayerSchedule? resolvedSchedule,
    NextPrayerInfo? nextPrayerInfo,
    Duration? remaining,
    QiblaTokens tokens,
    int streak,
    PrayerLocationDiagnostic? locationDiagnostic,
    DateTime selectedDate,
  ) {
    final l10n = context.l10n;
    final prayerSchedule = resolvedSchedule?.schedule;
    if (prayerSchedule == null) {
      return _buildFallbackHero(tokens, locationDiagnostic);
    }

    final isToday = _isSameDay(selectedDate, _dateOnly(DateTime.now()));
    if (!isToday || nextPrayerInfo == null) {
      return _buildSelectedDateHero(
        tokens,
        selectedDate,
        resolvedSchedule?.fromCache == true,
      );
    }

    final hero = tokens.getHero(nextPrayerInfo.prayer.key);
    final names = _prayerName(nextPrayerInfo.prayer);
    final nextPrayerSubtitle = context.l10n.homeNextPrayerStartsAt(
      _formatTime(nextPrayerInfo.time),
    );

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        color: _blend(hero.bg, tokens.bgSurface, 0.78),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: _blend(tokens.primary, tokens.borderMed, 0.22)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _blend(hero.bg, tokens.bgSurface, 0.82),
            _blend(hero.tint, tokens.bgSurface, 0.9),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: 6,
              right: -18,
              child: IgnorePointer(
                child: Icon(
                  Icons.mosque_rounded,
                  size: 118,
                  color: tokens.primary.withOpacity(0.045),
                ),
              ),
            ),
            Positioned(
              top: 30,
              right: 18,
              child: IgnorePointer(
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        tokens.primary.withOpacity(0.08),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
              Text(
                l10n.homeHeroNextPrayer,
                style: GoogleFonts.dmSans(
                  fontSize: 9,
                  color: tokens.primary.withOpacity(0.65),
                  letterSpacing: 1.8,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                names.$1,
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSerifDisplay(
                  fontSize: 42,
                  color: tokens.primary,
                  height: 1.0,
                ),
              ),
              if (names.$2.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  names.$2,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.amiri(
                    fontSize: 24,
                    color: tokens.primaryLight,
                    height: 1.05,
                  ),
                ),
              ],
              const SizedBox(height: 4),
              Text(
                _selectedDate == _dateOnly(DateTime.now())
                    ? l10n.homeHeroTodayOverview
                    : _formatHeroDate(_selectedDate),
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: tokens.textSecondary,
                ),
              ),
              if (resolvedSchedule?.fromCache == true) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: tokens.primaryBg,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: tokens.primaryBorder),
                  ),
                  child: Text(
                    l10n.homeHeroUsingSavedLocation,
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      color: tokens.textPrimary,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              _buildCountdown(tokens, remaining, names.$1),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _blend(tokens.primary, tokens.bgSurface, 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: _blend(tokens.primary, tokens.borderMed, 0.2)),
                ),
                child: Text(
                  nextPrayerSubtitle,
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    color: tokens.primary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
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

  Widget _buildSelectedDateHero(
    QiblaTokens tokens,
    DateTime selectedDate,
    bool fromCache,
  ) {
    final l10n = context.l10n;
    final isToday = _isSameDay(selectedDate, _dateOnly(DateTime.now()));
    final hijri = HijriCalendar.fromDate(selectedDate);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        color: tokens.bgSurface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: _blend(tokens.primary, tokens.border, 0.12)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _blend(tokens.primary, tokens.bgSurface, _isLightTheme(tokens) ? 0.06 : 0.1),
            _blend(tokens.bgSurface2, tokens.bgSurface, 0.9),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            isToday ? l10n.homeSelectedDateToday : l10n.homeSelectedDateCustom,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 9,
              color: tokens.textSecondary,
              letterSpacing: 1.8,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _formatHeroDateLong(selectedDate),
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSerifDisplay(
              fontSize: 30,
              color: tokens.primary,
              height: 1.08,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${hijri.hDay} ${hijri.toFormat("MMMM")} ${hijri.hYear} AH',
            textAlign: TextAlign.center,
            style: GoogleFonts.amiri(
              fontSize: 18,
              color: tokens.primaryLight,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 3,
            decoration: BoxDecoration(
              color: tokens.primary.withOpacity(0.45),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isToday
                ? l10n.homeSelectedDateTodayBody
                : l10n.homeSelectedDateCustomBody,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              height: 1.55,
              color: tokens.textPrimary,
            ),
          ),
          if (fromCache) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: tokens.primaryBg,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: tokens.primaryBorder),
              ),
                  child: Text(
                    l10n.homeHeroUsingSavedLocation,
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  color: tokens.textPrimary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingHero(QiblaTokens tokens) {
    final l10n = context.l10n;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tokens.bgSurface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: tokens.border),
      ),
      child: Column(
        children: [
          Text(
            l10n.homeLoadingScheduleTitle,
            style: GoogleFonts.dmSerifDisplay(
              fontSize: 24,
              color: tokens.primary,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 172,
            height: 172,
            child: Center(
              child: CircularProgressIndicator(
                color: tokens.primary,
                backgroundColor: tokens.bgSurface2,
                strokeWidth: 4,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.homeLoadingScheduleBody,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              color: tokens.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackHero(
    QiblaTokens tokens,
    PrayerLocationDiagnostic? diagnostic,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
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
            _locationDiagnosticTitle(diagnostic),
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: tokens.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _locationDiagnosticBody(diagnostic),
            style: GoogleFonts.dmSans(
              fontSize: 12,
              height: 1.5,
              color: tokens.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationStatusCard(
    QiblaTokens tokens,
    bool? systemPermissionGranted,
    bool? prayerNotificationsEnabled,
  ) {
    final l10n = context.l10n;
    if (systemPermissionGranted == null || prayerNotificationsEnabled == null) {
      return const SizedBox.shrink();
    }
    if (systemPermissionGranted && prayerNotificationsEnabled) {
      return const SizedBox.shrink();
    }

    final text = !systemPermissionGranted
        ? l10n.homeNotificationPermissionPending
        : l10n.homeNotificationPaused;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: tokens.primaryBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: tokens.primaryBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.notifications_off_outlined, color: tokens.primary, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  height: 1.5,
                  color: tokens.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRamadanCard(
    QiblaTokens tokens,
    PrayerSchedule? schedule,
    RamadanStatus? ramadanStatus,
  ) {
    final l10n = context.l10n;
    if (schedule == null || ramadanStatus == null || !ramadanStatus.isEnabled) {
      return const SizedBox.shrink();
    }

    final now = DateTime.now();
    final imsakTime = schedule.fajr;
    final beforeImsak = now.isBefore(imsakTime);
    final beforeIftar = now.isBefore(schedule.maghrib);
    final nextImsak = DateTime(
      now.year,
      now.month,
      now.day + 1,
      imsakTime.hour,
      imsakTime.minute,
    );
    final targetTime = beforeImsak
        ? imsakTime
        : beforeIftar
            ? schedule.maghrib
            : nextImsak;
    final countdownValue = _formatRamadanCountdown(targetTime.difference(now));
    final countdownLabel = beforeImsak
        ? l10n.homeRamadanCountdownImsak(countdownValue)
        : beforeIftar
        ? l10n.homeRamadanCountdownIftar(countdownValue)
        : l10n.homeRamadanCountdownTomorrowImsak(countdownValue);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: tokens.primaryBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: tokens.primaryBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.homeRamadanModeTitle,
                    style: GoogleFonts.dmSans(
                      fontSize: 9,
                      color: tokens.textSecondary,
                      letterSpacing: 1.4,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: tokens.bgSurface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: tokens.border),
                  ),
                  child: Text(
                    ramadanStatus.headerLabel,
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      color: tokens.primaryLight,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              countdownLabel,
              style: GoogleFonts.dmSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: tokens.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              ramadanStatus.blessingMessage,
              style: GoogleFonts.dmSans(
                fontSize: 11,
                height: 1.5,
                color: tokens.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _summaryMetric(
                    tokens,
                    _formatTime(imsakTime),
                    'Imsak',
                  ),
                ),
                Expanded(
                  child: _summaryMetric(
                    tokens,
                    _formatTime(schedule.maghrib),
                    'Iftar',
                  ),
                ),
                Expanded(
                  child: _summaryMetric(
                    tokens,
                    beforeImsak
                        ? l10n.homeRamadanSuhoorLabel
                        : beforeIftar
                            ? l10n.homeRamadanFastingLabel
                            : l10n.homeRamadanNightLabel,
                    beforeImsak
                        ? l10n.homeRamadanClosingSoon
                        : beforeIftar
                            ? l10n.homeRamadanUntilIftar
                            : l10n.homeRamadanNextFocus,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              ramadanStatus.dailySuggestion,
              style: GoogleFonts.dmSans(
                fontSize: 11,
                height: 1.5,
                color: tokens.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeInsightCard(
    QiblaTokens tokens,
    HomeInsightBundle bundle,
  ) {
    final l10n = context.l10n;
    final primary = bundle.primary;
    final secondary = bundle.secondary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: tokens.bgSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: tokens.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: tokens.primaryBg,
                    shape: BoxShape.circle,
                    border: Border.all(color: tokens.primaryBorder),
                  ),
                  child: Icon(
                    _insightIcon(primary.kind),
                    size: 18,
                    color: tokens.primaryLight,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.homeInsightTodayLabel,
                        style: GoogleFonts.dmSans(
                          fontSize: 9,
                          color: tokens.textSecondary,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        primary.title,
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: tokens.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              primary.message,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                height: 1.5,
                color: tokens.textPrimary,
              ),
            ),
            if (secondary != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: tokens.bgSurface2,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: tokens.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      _insightIcon(secondary.kind),
                      size: 16,
                      color: tokens.textMuted,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        secondary.message,
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
                          height: 1.45,
                          color: tokens.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklySummaryCard(QiblaTokens tokens, WeeklySummary summary) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: tokens.bgSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: tokens.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.analyticsWeeklySummaryTitle,
                    style: GoogleFonts.dmSans(
                      fontSize: 9,
                      color: tokens.textSecondary,
                      letterSpacing: 1.4,
                    ),
                  ),
                ),
                Text(
                  '${summary.prayersCompleted}/${summary.maxPossible}',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: tokens.primaryLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _summaryMetric(
                    tokens,
                    '${summary.fullDays}',
                    l10n.analyticsFullDaysLabel,
                  ),
                ),
                Expanded(
                  child: _summaryMetric(
                    tokens,
                    '${summary.currentStreak}',
                    l10n.analyticsCurrentStreakLabel,
                  ),
                ),
                Expanded(
                  child: _summaryMetric(
                    tokens,
                    summary.strongestDay.shortLabel,
                    l10n.homeWeeklyBestDayHelper(
                      summary.strongestDay.completed,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              summary.interpretation,
              style: GoogleFonts.dmSans(
                fontSize: 11,
                height: 1.5,
                color: tokens.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryMetric(QiblaTokens tokens, String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: GoogleFonts.dmSans(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: tokens.primaryLight,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 10,
            color: tokens.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildRamadanGoalsCard(
    BuildContext context,
    QiblaTokens tokens,
    PrayerSchedule? schedule,
    RamadanStatus? ramadanStatus,
    TrackingState tracking,
    QuranReadingPoint? lastReading,
    DhikrSnapshot? dhikrSnapshot,
  ) {
    if (schedule == null || ramadanStatus == null || !ramadanStatus.isEnabled) {
      return const SizedBox.shrink();
    }

    final now = DateTime.now();
    final prayerCount = tracking.completedCountFor(now);
    final quranGoal = _buildQuranGoal(lastReading, now);
    final dhikrGoal = _buildDhikrGoal(dhikrSnapshot);
    final fastingGoal = _buildFastingGoal(schedule, now);
    final l10n = context.l10n;
    final items = <_RamadanGoalItem>[
      _RamadanGoalItem(
        title: l10n.commonPrayers,
        description: l10n.homeRamadanPrayerGoal(prayerCount),
        icon: Icons.mosque_outlined,
        state: prayerCount >= 5
            ? _RamadanGoalState.completed
            : prayerCount > 0
            ? _RamadanGoalState.inProgress
            : _RamadanGoalState.pending,
      ),
      quranGoal,
      dhikrGoal,
      fastingGoal,
    ];
    final completedCount = items
        .where((item) => item.state == _RamadanGoalState.completed)
        .length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: tokens.bgSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: tokens.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.homeRamadanGoalsTitle,
                    style: GoogleFonts.dmSans(
                      fontSize: 9,
                      color: tokens.textSecondary,
                      letterSpacing: 1.4,
                    ),
                  ),
                ),
                Text(
                  l10n.homeRamadanGoalsReady(completedCount, items.length),
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: tokens.primaryLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...items.map((item) => _buildRamadanGoalRow(context, tokens, item)),
            const SizedBox(height: 8),
            Text(
              completedCount == items.length
                  ? l10n.homeRamadanGoalsCompleteMessage
                  : completedCount >= 2
                  ? l10n.homeRamadanGoalsProgressMessage
                  : l10n.homeRamadanGoalsStartMessage,
              style: GoogleFonts.dmSans(
                fontSize: 11,
                height: 1.5,
                color: tokens.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRamadanGoalRow(
    BuildContext context,
    QiblaTokens tokens,
    _RamadanGoalItem item,
  ) {
    final (iconColor, chipLabel, chipBg, chipBorder) = _goalStyle(tokens, item.state);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: tokens.bgSurface2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tokens.border),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: chipBg,
              shape: BoxShape.circle,
              border: Border.all(color: chipBorder),
            ),
            child: Icon(item.icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: tokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.description,
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    height: 1.4,
                    color: tokens.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (item.destination != null)
            IconButton(
              tooltip: item.actionLabel ?? context.l10n.commonOpen,
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => item.destination!),
                );
                ref.invalidate(lastReadingProvider);
                ref.invalidate(dhikrSnapshotProvider);
              },
              icon: Icon(Icons.arrow_forward, size: 18, color: tokens.textMuted),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: chipBg,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: chipBorder),
            ),
            child: Text(
              chipLabel,
              style: GoogleFonts.dmSans(
                fontSize: 10,
                color: iconColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  _RamadanGoalItem _buildQuranGoal(
    QuranReadingPoint? lastReading,
    DateTime now,
  ) {
    final l10n = context.l10n;
    if (lastReading == null) {
      return _RamadanGoalItem(
        title: l10n.commonQuran,
        description: l10n.homeRamadanQuranStartBody,
        icon: Icons.menu_book_outlined,
        state: _RamadanGoalState.pending,
        destination: const QuranScreen(),
        actionLabel: l10n.homeRamadanOpenQuran,
      );
    }

    final daysSince = now
        .difference(
          DateTime(
            lastReading.savedAt.year,
            lastReading.savedAt.month,
            lastReading.savedAt.day,
          ),
        )
        .inDays;

    if (daysSince <= 0) {
      return _RamadanGoalItem(
        title: l10n.commonQuran,
        description: l10n.homeRamadanQuranSavedToday(
          lastReading.surahNameLatin,
          lastReading.ayahNumber,
        ),
        icon: Icons.menu_book_outlined,
        state: _RamadanGoalState.completed,
        destination: const QuranScreen(),
        actionLabel: l10n.homeRamadanContinueReading,
      );
    }

    if (daysSince <= 3) {
      return _RamadanGoalItem(
        title: l10n.commonQuran,
        description: l10n.homeRamadanQuranRecentProgress(
          lastReading.surahNameLatin,
          lastReading.ayahNumber,
        ),
        icon: Icons.menu_book_outlined,
        state: _RamadanGoalState.inProgress,
        destination: const QuranScreen(),
        actionLabel: l10n.homeRamadanContinueReading,
      );
    }

    return _RamadanGoalItem(
      title: l10n.commonQuran,
      description: l10n.homeRamadanQuranReturnBody(
        lastReading.surahNameLatin,
        lastReading.ayahNumber,
      ),
      icon: Icons.menu_book_outlined,
      state: _RamadanGoalState.pending,
      destination: const QuranScreen(),
      actionLabel: l10n.homeRamadanOpenQuran,
    );
  }

  _RamadanGoalItem _buildDhikrGoal(DhikrSnapshot? snapshot) {
    final l10n = context.l10n;
    if (snapshot == null) {
      return _RamadanGoalItem(
        title: 'Dhikr',
        description: l10n.homeRamadanDhikrPreparingBody,
        icon: Icons.auto_awesome_outlined,
        state: _RamadanGoalState.pending,
        destination: const DhikrScreen(),
        actionLabel: l10n.homeRamadanOpenTasbih,
      );
    }

    if (snapshot.dailyGoalReached) {
      return _RamadanGoalItem(
        title: 'Dhikr',
        description: l10n.homeRamadanDhikrCompletedBody(
          snapshot.todayCount,
          snapshot.dailyGoal,
        ),
        icon: Icons.auto_awesome_outlined,
        state: _RamadanGoalState.completed,
        destination: const DhikrScreen(),
        actionLabel: l10n.commonContinue,
      );
    }

    if (snapshot.todayCount > 0) {
      return _RamadanGoalItem(
        title: 'Dhikr',
        description: l10n.homeRamadanDhikrInProgressBody(
          snapshot.todayCount,
          snapshot.dailyGoal,
        ),
        icon: Icons.auto_awesome_outlined,
        state: _RamadanGoalState.inProgress,
        destination: const DhikrScreen(),
        actionLabel: l10n.commonContinue,
      );
    }

    return _RamadanGoalItem(
      title: 'Dhikr',
      description: l10n.homeRamadanDhikrStartBody(snapshot.dailyGoal),
      icon: Icons.auto_awesome_outlined,
      state: _RamadanGoalState.pending,
      destination: const DhikrScreen(),
      actionLabel: l10n.homeRamadanStartAction,
    );
  }

  _RamadanGoalItem _buildFastingGoal(
    PrayerSchedule schedule,
    DateTime now,
  ) {
    final l10n = context.l10n;
    if (now.isBefore(schedule.maghrib)) {
      return _RamadanGoalItem(
        title: l10n.homeRamadanFastingTitle,
        description: l10n.homeRamadanFastingInProgress(
          _formatTime(schedule.maghrib),
        ),
        icon: Icons.wb_sunny_outlined,
        state: _RamadanGoalState.inProgress,
      );
    }

    return _RamadanGoalItem(
      title: l10n.homeRamadanFastingTitle,
      description: l10n.homeRamadanFastingCompleted(
        _formatTime(schedule.maghrib),
      ),
      icon: Icons.nightlight_round,
      state: _RamadanGoalState.completed,
    );
  }

  (Color, String, Color, Color) _goalStyle(
    QiblaTokens tokens,
    _RamadanGoalState state,
  ) {
    final l10n = context.l10n;
    switch (state) {
      case _RamadanGoalState.completed:
        return (
          tokens.accent,
          l10n.homeGoalCompleted,
          tokens.primaryBg,
          tokens.primaryBorder,
        );
      case _RamadanGoalState.inProgress:
        return (
          tokens.primaryLight,
          l10n.homeGoalInProgress,
          tokens.activeBg,
          tokens.activeBorder,
        );
      case _RamadanGoalState.pending:
        return (
          tokens.textMuted,
          l10n.commonPending,
          tokens.bgSurface,
          tokens.border,
        );
    }
  }

  String _locationDiagnosticTitle(PrayerLocationDiagnostic? diagnostic) {
    final l10n = context.l10n;
    if (diagnostic == null) {
      return l10n.homeLocationPreparingTitle;
    }
    if (!diagnostic.serviceEnabled) {
      return l10n.homeLocationEnableDeviceLocation;
    }
    if (diagnostic.permissionStatus ==
        PrayerLocationPermissionStatus.deniedForever) {
      return l10n.homeLocationPermissionBlocked;
    }
    if (diagnostic.permissionStatus == PrayerLocationPermissionStatus.denied) {
      return l10n.homeLocationPermissionNeeded;
    }
    return l10n.homeLocationPreparingTitle;
  }

  String _locationDiagnosticBody(PrayerLocationDiagnostic? diagnostic) {
    final l10n = context.l10n;
    if (diagnostic == null) {
      return l10n.homeLocationPendingBody;
    }
    if (!diagnostic.serviceEnabled) {
      return l10n.homeLocationGpsDisabledBody;
    }
    if (diagnostic.permissionStatus ==
        PrayerLocationPermissionStatus.deniedForever) {
      return l10n.homeLocationPermissionBlockedBody;
    }
    if (diagnostic.permissionStatus == PrayerLocationPermissionStatus.denied) {
      return l10n.homeLocationPermissionNeededBody;
    }
    if (diagnostic.hasCachedLocation) {
      return l10n.homeLocationCachedBody;
    }
    return l10n.homeLocationPendingBody;
  }

  Widget _buildCountdown(
    QiblaTokens tokens,
    Duration? remaining,
    String? nextPrayerLabel,
  ) {
    final l10n = context.l10n;
    if (remaining == null) {
      return Container(
        width: 188,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.18),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          l10n.homeCountdownUnavailable,
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: tokens.textPrimary,
          ),
        ),
      );
    }

    final countdownDisplay = _formatHeroCountdown(remaining);
    final clampedMinutes = remaining.inMinutes.clamp(0, 360);
    final progress = (1 - (clampedMinutes / 360)).clamp(0.08, 0.96).toDouble();
    final contextLabel = nextPrayerLabel == null
        ? l10n.homeCountdownActive
        : l10n.homeCountdownUntil(nextPrayerLabel);

    return SizedBox(
      width: 188,
      height: 188,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 188,
            height: 188,
            child: CustomPaint(
              painter: _CountdownRingPainter(
                trackColor: _blend(tokens.bgSurface2, Colors.black, 0.7),
                progressColor: tokens.primary,
                progress: progress,
              ),
            ),
          ),
          Container(
            width: 154,
            height: 154,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _blend(tokens.bgSurface, Colors.black, 0.82),
              border: Border.all(
                color: _blend(tokens.primary, tokens.borderMed, 0.12),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  l10n.homeCountdownLabelUppercase,
                  style: GoogleFonts.dmSans(
                    fontSize: 9,
                    color: tokens.textSecondary,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      countdownDisplay.$1,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(
                        fontSize: countdownDisplay.$3 ? 26 : 30,
                        fontWeight: FontWeight.w600,
                        color: tokens.textPrimary,
                        letterSpacing: -0.7,
                      ),
                    ),
                  ),
                ),
                if (countdownDisplay.$2 != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    countdownDisplay.$2!,
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: tokens.primaryLight,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  contextLabel,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    color: tokens.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerSection(
    PrayerSchedule? prayerSchedule,
    NextPrayerInfo? nextPrayerInfo,
    List<String> completed,
    DateTime date,
    QiblaTokens tokens,
  ) {
    final l10n = context.l10n;
    if (prayerSchedule == null) {
      return _buildPrayerFallback(tokens, null);
    }

    final languageCode = AppLocaleController.effectiveLanguageCode();
    final isArabicOnly = languageCode == 'ar';
    final prayers = [
      (
        PrayerName.fajr,
        _localizedPrayerPrimaryName(PrayerName.fajr, languageCode),
        isArabicOnly ? '' : PrayerName.fajr.displayNameArabic,
        prayerSchedule.fajr,
      ),
      (
        PrayerName.dhuhr,
        _localizedPrayerPrimaryName(PrayerName.dhuhr, languageCode),
        isArabicOnly ? '' : PrayerName.dhuhr.displayNameArabic,
        prayerSchedule.dhuhr,
      ),
      (
        PrayerName.asr,
        _localizedPrayerPrimaryName(PrayerName.asr, languageCode),
        isArabicOnly ? '' : PrayerName.asr.displayNameArabic,
        prayerSchedule.asr,
      ),
      (
        PrayerName.maghrib,
        _localizedPrayerPrimaryName(PrayerName.maghrib, languageCode),
        isArabicOnly ? '' : PrayerName.maghrib.displayNameArabic,
        prayerSchedule.maghrib,
      ),
      (
        PrayerName.isha,
        _localizedPrayerPrimaryName(PrayerName.isha, languageCode),
        isArabicOnly ? '' : PrayerName.isha.displayNameArabic,
        prayerSchedule.isha,
      ),
    ];
    final nextPrayerName = nextPrayerInfo?.prayer.key;
    final isToday = _isSameDay(date, _dateOnly(DateTime.now()));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  (isToday
                          ? l10n.homePrayerSectionToday
                          : l10n.homePrayerSectionForDate(_formatCompactDate(date)))
                      .toUpperCase(),
                  style: GoogleFonts.dmSans(
                    fontSize: 9,
                    color: tokens.textSecondary,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              Text(
                isToday
                    ? l10n.homePrayerSectionWorshipDay(
                        SpanishDateLabels.longWeekday(date),
                      )
                    : l10n.homePrayerSectionMarkedCount(completed.length),
                style: GoogleFonts.dmSans(fontSize: 10, color: tokens.primaryLight),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...prayers.map((prayer) {
            final isCurrent = prayer.$1.key == nextPrayerName;
            final isDone = _isPrayerDone(completed, prayer.$1.key);
            return GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PrayerGuideScreen(prayerName: prayer.$1),
                  ),
                );
              },
              child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isCurrent
                    ? _blend(tokens.primary, tokens.bgSurface, 0.12)
                    : isDone
                        ? _blend(tokens.bgSurface, tokens.bgPage, 0.9)
                        : tokens.bgSurface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isCurrent
                      ? _blend(tokens.primary, tokens.primaryBorder, 0.18)
                      : tokens.border,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isCurrent
                        ? tokens.primary.withOpacity(0.12)
                        : Colors.black.withOpacity(0.06),
                    blurRadius: isCurrent ? 18 : 10,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isCurrent ? tokens.primary.withOpacity(0.14) : tokens.bgSurface2,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _prayerIcon(prayer.$1),
                      size: 18,
                      color: isCurrent ? tokens.primary : tokens.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          prayer.$2,
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w600,
                            color: isCurrent ? tokens.primary : tokens.textPrimary,
                          ),
                        ),
                        if (prayer.$3.isNotEmpty)
                          Text(
                            prayer.$3,
                            style: GoogleFonts.amiri(
                              fontSize: 13,
                              color: tokens.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    _formatTime(prayer.$4),
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                      color: isCurrent
                          ? tokens.primary
                          : tokens.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => ref
                        .read(prayerTrackingProvider.notifier)
                        .togglePrayer(prayer.$2, date: date),
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDone ? tokens.accent : Colors.transparent,
                        border: Border.all(
                          color: isDone ? tokens.accent : tokens.textMuted,
                          width: 1.5,
                        ),
                      ),
                      child: isDone
                          ? Icon(Icons.check, size: 12, color: tokens.bgPage)
                          : null,
                    ),
                  ),
                ],
              ),
            ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPrayerSkeleton(QiblaTokens tokens) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: List.generate(
          3,
          (_) => Container(
            height: 58,
            margin: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(
              color: tokens.bgSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: tokens.border),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrayerFallback(
    QiblaTokens tokens,
    PrayerLocationDiagnostic? diagnostic,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: tokens.bgSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: tokens.border),
        ),
        child: Text(
          _locationDiagnosticBody(diagnostic),
          style: GoogleFonts.dmSans(fontSize: 12, color: tokens.textSecondary),
        ),
      ),
    );
  }

  Widget _buildPremiumPrayerSection(
    PrayerSchedule? prayerSchedule,
    NextPrayerInfo? nextPrayerInfo,
    List<String> completed,
    DateTime date,
    QiblaTokens tokens,
  ) {
    final l10n = context.l10n;
    if (prayerSchedule == null) {
      return _buildPremiumPrayerFallback(tokens, null);
    }

    final languageCode = AppLocaleController.effectiveLanguageCode();
    final isArabicOnly = languageCode == 'ar';
    final prayers = <(PrayerName, String, String, DateTime)>[
      (
        PrayerName.fajr,
        _localizedPrayerPrimaryName(PrayerName.fajr, languageCode),
        isArabicOnly ? '' : PrayerName.fajr.displayNameArabic,
        prayerSchedule.fajr,
      ),
      (
        PrayerName.dhuhr,
        _localizedPrayerPrimaryName(PrayerName.dhuhr, languageCode),
        isArabicOnly ? '' : PrayerName.dhuhr.displayNameArabic,
        prayerSchedule.dhuhr,
      ),
      (
        PrayerName.asr,
        _localizedPrayerPrimaryName(PrayerName.asr, languageCode),
        isArabicOnly ? '' : PrayerName.asr.displayNameArabic,
        prayerSchedule.asr,
      ),
      (
        PrayerName.maghrib,
        _localizedPrayerPrimaryName(PrayerName.maghrib, languageCode),
        isArabicOnly ? '' : PrayerName.maghrib.displayNameArabic,
        prayerSchedule.maghrib,
      ),
      (
        PrayerName.isha,
        _localizedPrayerPrimaryName(PrayerName.isha, languageCode),
        isArabicOnly ? '' : PrayerName.isha.displayNameArabic,
        prayerSchedule.isha,
      ),
    ];
    final now = DateTime.now();
    final nextPrayerName = nextPrayerInfo?.prayer.key;
    final isToday = _isSameDay(date, _dateOnly(now));

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isToday
                          ? l10n.homePrayerSectionTodayTitle
                          : l10n.homePrayerSectionSelectedDayTitle,
                      style: GoogleFonts.dmSans(
                        fontSize: 9,
                        color: tokens.textSecondary,
                        letterSpacing: 1.6,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isToday
                          ? l10n.homePrayerSectionTodaySubtitle
                          : l10n.homePrayerSectionSelectedDaySubtitle(
                              _formatCompactDate(date),
                            ),
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: tokens.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _blend(tokens.primary, tokens.bgSurface, 0.1),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: _blend(tokens.primary, tokens.borderMed, 0.18),
                  ),
                ),
                child: Text(
                  isToday
                      ? l10n.homePrayerSectionMarkedCount(completed.length)
                      : SpanishDateLabels.longWeekday(date),
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    color: tokens.primaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...List.generate(prayers.length, (index) {
            final prayer = prayers[index];
            final isNext = isToday && prayer.$1.key == nextPrayerName;
            final isDone = _isPrayerDone(completed, prayer.$1.key);
            final isNow =
                isToday &&
                !isNext &&
                !isDone &&
                _isPremiumCurrentPrayerWindow(prayers, index, now);
            final tone = _premiumPrayerCardTone(
              isNow: isNow,
              isNext: isNext,
              isDone: isDone,
              isToday: isToday,
              prayerTime: prayer.$4,
              now: now,
            );
            final style = _premiumPrayerCardStyle(tokens, tone);

            return GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PrayerGuideScreen(prayerName: prayer.$1),
                  ),
                );
              },
              child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
              decoration: BoxDecoration(
                color: style.surfaceColor,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: style.borderColor),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _blend(style.surfaceColor, tokens.bgSurface2, 0.22),
                    style.surfaceColor,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: style.shadowColor,
                    blurRadius: tone == _PremiumPrayerCardTone.idle ? 10 : 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: style.iconBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _blend(style.iconColor, tokens.border, 0.14),
                      ),
                    ),
                    child: Icon(
                      _prayerIcon(prayer.$1),
                      size: 20,
                      color: style.iconColor,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                prayer.$2,
                                style: GoogleFonts.dmSans(
                                  fontSize: 15,
                                  fontWeight: tone == _PremiumPrayerCardTone.idle
                                      ? FontWeight.w600
                                      : FontWeight.w700,
                                  color: tone == _PremiumPrayerCardTone.next
                                      ? tokens.primary
                                      : tokens.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            _buildPremiumPrayerStatusChip(style),
                          ],
                        ),
                        if (prayer.$3.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Directionality(
                            textDirection: TextDirection.rtl,
                            child: Text(
                              prayer.$3,
                              style: GoogleFonts.amiri(
                                fontSize: 15,
                                color: tone == _PremiumPrayerCardTone.now
                                    ? style.iconColor
                                    : tokens.textSecondary,
                                height: 1.1,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Text(
                          isDone
                              ? l10n.homePrayerDescriptionCompleted
                              : isNow
                              ? l10n.homePrayerDescriptionNow
                              : isNext
                              ? l10n.homePrayerDescriptionNext
                              : isToday
                              ? l10n.homePrayerDescriptionPendingToday
                              : l10n.homePrayerDescriptionReviewDate,
                          style: GoogleFonts.dmSans(
                            fontSize: 10,
                            color: tokens.textSecondary,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: style.timeBackground,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: _blend(style.timeColor, tokens.border, 0.12),
                          ),
                        ),
                        child: Text(
                          _formatTime(prayer.$4),
                          style: GoogleFonts.dmSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: style.timeColor,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => ref
                            .read(prayerTrackingProvider.notifier)
                            .togglePrayer(prayer.$1.key, date: date),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: isDone
                                ? tokens.accent
                                : _blend(tokens.bgSurface2, tokens.bgSurface, 0.82),
                            border: Border.all(
                              color: isDone
                                  ? tokens.accent
                                  : _blend(tokens.textMuted, tokens.border, 0.22),
                              width: 1.4,
                            ),
                          ),
                          child: Icon(
                            isDone
                                ? Icons.check_rounded
                                : Icons.add_task_rounded,
                            size: 16,
                            color: isDone ? tokens.bgPage : tokens.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPremiumPrayerSkeleton(QiblaTokens tokens) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: Column(
        children: List.generate(
          3,
          (_) => Container(
            height: 92,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: _blend(tokens.bgSurface2, tokens.bgSurface, 0.86),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: tokens.border),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumPrayerFallback(
    QiblaTokens tokens,
    PrayerLocationDiagnostic? diagnostic,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _blend(tokens.bgSurface2, tokens.bgSurface, 0.86),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: tokens.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _blend(tokens.primary, tokens.bgSurface, 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.schedule_rounded,
                color: tokens.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _locationDiagnosticBody(diagnostic),
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  height: 1.5,
                  color: tokens.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(QiblaTokens tokens) {
    final l10n = context.l10n;
    final actions = <({IconData icon, String label, Widget destination})>[
      (
        icon: Icons.auto_stories_outlined,
        label: l10n.commonHadiths,
        destination: const HadithLibraryScreen(),
      ),
      (
        icon: Icons.library_books_outlined,
        label: l10n.commonBooks,
        destination: const IslamicBooksScreen(),
      ),
      (
        icon: Icons.water_drop_outlined,
        label: l10n.homeQuickActionPurification,
        destination: const PurificationGuideScreen(),
      ),
      (
        icon: Icons.self_improvement_rounded,
        label: 'Rakaha',
        destination: const FocusModeScreen(),
      ),
      (
        icon: Icons.calendar_month_outlined,
        label: l10n.calendarTitle,
        destination: const CalendarScreen(),
      ),
      (
        icon: Icons.insights_outlined,
        label: l10n.commonStatistics,
        destination: const AnalyticsScreen(),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.homeQuickActionsTitle,
            style: GoogleFonts.dmSans(
              fontSize: 9,
              color: tokens.textSecondary,
              letterSpacing: 1.6,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: actions.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.14,
            ),
            itemBuilder: (_, index) {
              final action = actions[index];
              return InkWell(
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => action.destination),
                  );
                  ref.invalidate(lastReadingProvider);
                  ref.invalidate(dhikrSnapshotProvider);
                },
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  decoration: BoxDecoration(
                    color: _blend(tokens.bgSurface2, tokens.bgSurface, 0.88),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: _blend(tokens.primary, tokens.border, 0.08)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: _blend(tokens.primary, tokens.bgSurface, 0.14),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(action.icon, size: 20, color: tokens.primary),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        action.label,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
                          color: tokens.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  bool _isPrayerDone(List<String> completed, String prayerName) {
    return completed.contains(prayerName.toLowerCase());
  }

  bool _isPremiumCurrentPrayerWindow(
    List<(PrayerName, String, String, DateTime)> prayers,
    int index,
    DateTime now,
  ) {
    final prayerTime = prayers[index].$4;
    if (now.isBefore(prayerTime)) {
      return false;
    }

    if (index == prayers.length - 1) {
      return true;
    }

    return now.isBefore(prayers[index + 1].$4);
  }

  _PremiumPrayerCardTone _premiumPrayerCardTone({
    required bool isNow,
    required bool isNext,
    required bool isDone,
    required bool isToday,
    required DateTime prayerTime,
    required DateTime now,
  }) {
    if (isDone) {
      return _PremiumPrayerCardTone.completed;
    }
    if (isNow) {
      return _PremiumPrayerCardTone.now;
    }
    if (isNext) {
      return _PremiumPrayerCardTone.next;
    }
    if (isToday && prayerTime.isAfter(now)) {
      return _PremiumPrayerCardTone.upcoming;
    }
    return _PremiumPrayerCardTone.idle;
  }

  _PremiumPrayerCardStyle _premiumPrayerCardStyle(
    QiblaTokens tokens,
    _PremiumPrayerCardTone tone,
  ) {
    final l10n = context.l10n;
    switch (tone) {
      case _PremiumPrayerCardTone.now:
        return _PremiumPrayerCardStyle(
          label: l10n.homePrayerStatusNow,
          surfaceColor: _blend(tokens.accent, tokens.bgSurface, 0.16),
          borderColor: _blend(tokens.accent, tokens.borderMed, 0.22),
          shadowColor: tokens.accent.withOpacity(0.12),
          iconBackground: _blend(tokens.accent, tokens.bgSurface2, 0.2),
          iconColor: tokens.accent,
          timeBackground: _blend(tokens.accent, tokens.bgSurface, 0.14),
          timeColor: tokens.textPrimary,
          badgeBackground: _blend(tokens.accent, tokens.bgSurface, 0.18),
          badgeBorder: _blend(tokens.accent, tokens.borderMed, 0.18),
          badgeForeground: tokens.accent,
        );
      case _PremiumPrayerCardTone.next:
        return _PremiumPrayerCardStyle(
          label: l10n.homePrayerStatusNext,
          surfaceColor: _blend(tokens.primary, tokens.bgSurface, 0.14),
          borderColor: _blend(tokens.primary, tokens.primaryBorder, 0.2),
          shadowColor: tokens.primary.withOpacity(0.12),
          iconBackground: _blend(tokens.primary, tokens.bgSurface2, 0.18),
          iconColor: tokens.primary,
          timeBackground: _blend(tokens.primary, tokens.bgSurface, 0.12),
          timeColor: tokens.primaryLight,
          badgeBackground: _blend(tokens.primary, tokens.bgSurface, 0.16),
          badgeBorder: _blend(tokens.primary, tokens.borderMed, 0.18),
          badgeForeground: tokens.primaryLight,
        );
      case _PremiumPrayerCardTone.completed:
        return _PremiumPrayerCardStyle(
          label: l10n.homePrayerStatusCompleted,
          surfaceColor: _blend(tokens.bgSurface, tokens.bgPage, 0.9),
          borderColor: tokens.border,
          shadowColor: Colors.black.withOpacity(0.06),
          iconBackground: _blend(tokens.accent, tokens.bgSurface, 0.1),
          iconColor: tokens.accent,
          timeBackground: _blend(tokens.bgSurface2, tokens.bgSurface, 0.88),
          timeColor: tokens.textSecondary,
          badgeBackground: _blend(tokens.accent, tokens.bgSurface, 0.14),
          badgeBorder: _blend(tokens.accent, tokens.border, 0.12),
          badgeForeground: tokens.accent,
        );
      case _PremiumPrayerCardTone.upcoming:
        return _PremiumPrayerCardStyle(
          label: l10n.homePrayerStatusUpcoming,
          surfaceColor: _blend(tokens.bgSurface2, tokens.bgSurface, 0.84),
          borderColor: _blend(tokens.primary, tokens.border, 0.08),
          shadowColor: Colors.black.withOpacity(0.07),
          iconBackground: _blend(tokens.primary, tokens.bgSurface, 0.08),
          iconColor: tokens.textSecondary,
          timeBackground: _blend(tokens.bgSurface, tokens.bgPage, 0.82),
          timeColor: tokens.textPrimary,
          badgeBackground: _blend(tokens.bgSurface2, tokens.bgSurface, 0.92),
          badgeBorder: tokens.border,
          badgeForeground: tokens.textSecondary,
        );
      case _PremiumPrayerCardTone.idle:
        return _PremiumPrayerCardStyle(
          label: l10n.commonPending,
          surfaceColor: tokens.bgSurface,
          borderColor: tokens.border,
          shadowColor: Colors.black.withOpacity(0.06),
          iconBackground: tokens.bgSurface2,
          iconColor: tokens.textSecondary,
          timeBackground: _blend(tokens.bgSurface2, tokens.bgSurface, 0.88),
          timeColor: tokens.textPrimary,
          badgeBackground: _blend(tokens.bgSurface2, tokens.bgSurface, 0.92),
          badgeBorder: tokens.border,
          badgeForeground: tokens.textSecondary,
        );
    }
  }

  Widget _buildPremiumPrayerStatusChip(_PremiumPrayerCardStyle style) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: style.badgeBackground,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: style.badgeBorder),
      ),
      child: Text(
        style.label,
        style: GoogleFonts.dmSans(
          fontSize: 9,
          color: style.badgeForeground,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  (String, String) _prayerName(PrayerName prayer) {
    final languageCode = AppLocaleController.effectiveLanguageCode();
    final primary = _localizedPrayerPrimaryName(prayer, languageCode);
    final secondary = languageCode == 'ar' ? '' : prayer.displayNameArabic;
    return (primary, secondary);
  }

  String _localizedPrayerPrimaryName(
    PrayerName prayer,
    String languageCode,
  ) {
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
      'ru' => switch (prayer) {
          PrayerName.fajr => 'Фаджр',
          PrayerName.dhuhr => 'Зухр',
          PrayerName.asr => 'Аср',
          PrayerName.maghrib => 'Магриб',
          PrayerName.isha => 'Иша',
        },
      _ => prayer.localizedDisplayName(languageCode),
    };
  }

  IconData _prayerIcon(PrayerName prayer) {
    switch (prayer) {
      case PrayerName.fajr:
        return Icons.wb_twilight_rounded;
      case PrayerName.dhuhr:
        return Icons.wb_sunny_rounded;
      case PrayerName.asr:
        return Icons.light_mode_rounded;
      case PrayerName.maghrib:
        return Icons.nightlight_round;
      case PrayerName.isha:
        return Icons.dark_mode_rounded;
    }
  }

  bool _isLightTheme(QiblaTokens tokens) {
    return ThemeData.estimateBrightnessForColor(tokens.bgPage) == Brightness.light;
  }

  Color _blend(Color foreground, Color background, double amount) {
    return Color.lerp(background, foreground, amount.clamp(0.0, 1.0))!;
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatCompactDate(DateTime date) {
    return SpanishDateLabels.compactDate(date);
  }

  String _formatHeroDate(DateTime date) {
    return '${SpanishDateLabels.longWeekday(date)} ${date.day}/${date.month}';
  }

  String _formatHeroDateLong(DateTime date) {
    return SpanishDateLabels.fullDate(date);
  }

  String _formatRemaining(Duration? remaining) {
    final l10n = context.l10n;
    if (remaining == null) {
      return l10n.homeCountdownUnavailable.toLowerCase();
    }
    return l10n.homeDurationUntil(
      remaining.inHours,
      remaining.inMinutes.remainder(60),
    );
  }

  String _formatRamadanCountdown(Duration remaining) {
    final l10n = context.l10n;
    final safe = remaining.isNegative ? Duration.zero : remaining;
    final hours = safe.inHours;
    final minutes = safe.inMinutes.remainder(60);
    return l10n.homeDurationHoursMinutes(
      hours,
      minutes.toString().padLeft(2, '0'),
    );
  }

  (String, String?, bool) _formatHeroCountdown(Duration remaining) {
    final l10n = context.l10n;
    final safe = remaining.isNegative ? Duration.zero : remaining;
    final hours = safe.inHours;
    final minutes = safe.inMinutes.remainder(60);
    final seconds = safe.inSeconds.remainder(60);

    if (hours > 0) {
      return (
        l10n.homeDurationHoursMinutes(
          hours,
          minutes.toString().padLeft(2, '0'),
        ),
        null,
        true,
      );
    }

    if (safe.inMinutes > 0) {
      return (
        l10n.homeDurationMinutes(minutes),
        l10n.homeDurationSeconds(seconds.toString().padLeft(2, '0')),
        false,
      );
    }

    return (l10n.homeDurationSeconds(seconds.toString()), null, false);
  }

  IconData _insightIcon(HomeInsightKind kind) {
    switch (kind) {
      case HomeInsightKind.progress:
        return Icons.check_circle_outline;
      case HomeInsightKind.streak:
        return Icons.local_fire_department_outlined;
      case HomeInsightKind.improvement:
        return Icons.trending_up;
      case HomeInsightKind.prayerPattern:
        return Icons.insights_outlined;
      case HomeInsightKind.dhikr:
        return Icons.auto_awesome_outlined;
      case HomeInsightKind.ramadan:
        return Icons.nightlight_round;
      case HomeInsightKind.guidance:
        return Icons.lightbulb_outline;
    }
  }
}

enum _RamadanGoalState {
  pending,
  inProgress,
  completed,
}

enum _PremiumPrayerCardTone {
  now,
  next,
  completed,
  upcoming,
  idle,
}

class _RamadanGoalItem {
  const _RamadanGoalItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.state,
    this.destination,
    this.actionLabel,
  });

  final String title;
  final String description;
  final IconData icon;
  final _RamadanGoalState state;
  final Widget? destination;
  final String? actionLabel;
}

class _PremiumPrayerCardStyle {
  const _PremiumPrayerCardStyle({
    required this.label,
    required this.surfaceColor,
    required this.borderColor,
    required this.shadowColor,
    required this.iconBackground,
    required this.iconColor,
    required this.timeBackground,
    required this.timeColor,
    required this.badgeBackground,
    required this.badgeBorder,
    required this.badgeForeground,
  });

  final String label;
  final Color surfaceColor;
  final Color borderColor;
  final Color shadowColor;
  final Color iconBackground;
  final Color iconColor;
  final Color timeBackground;
  final Color timeColor;
  final Color badgeBackground;
  final Color badgeBorder;
  final Color badgeForeground;
}

class _CountdownRingPainter extends CustomPainter {
  const _CountdownRingPainter({
    required this.trackColor,
    required this.progressColor,
    required this.progress,
  });

  final Color trackColor;
  final Color progressColor;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = 4.0;
    final rect = Offset.zero & size;
    final circleRect = rect.deflate(stroke / 2);

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(circleRect, 0, 6.283185307179586, false, trackPaint);
    canvas.drawArc(
      circleRect,
      -1.5707963267948966,
      6.283185307179586 * progress.clamp(0.0, 1.0),
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CountdownRingPainter oldDelegate) {
    return oldDelegate.trackColor != trackColor ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.progress != progress;
  }
}
