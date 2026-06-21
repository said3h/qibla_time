import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:qibla_time/core/theme/local_fonts.dart';
import 'package:hijri/hijri_calendar.dart';

import '../../../core/localization/locale_controller.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/qibla_snackbar.dart';
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
import '../../support/screens/support_screen.dart';
import '../../support/screens/settings_screen.dart';
import '../../support/screens/purification_guide_screen.dart';
import '../../tracking/models/tracking_models.dart';
import '../../tracking/screens/analytics_screen.dart';
import '../../tracking/services/tracking_service.dart';
import '../domain/entities/manual_prayer_location.dart';
import '../domain/entities/next_prayer_info.dart';
import '../domain/entities/offline_prayer_city.dart';
import '../domain/entities/prayer_name.dart';
import '../domain/entities/prayer_location_diagnostic.dart';
import '../domain/entities/prayer_schedule.dart';
import '../domain/entities/ramadan_status.dart';
import '../domain/entities/resolved_prayer_schedule.dart';
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

@visibleForTesting
bool shouldRefreshPrayerTimesIfStale({
  required ResolvedPrayerSchedule? resolvedSchedule,
  required DateTime now,
  required DateTime? lastRefreshAt,
  Duration staleAfter = const Duration(hours: 4),
}) {
  if (resolvedSchedule == null) {
    return true;
  }

  final scheduleDate = resolvedSchedule.schedule.date;
  if (scheduleDate.year != now.year ||
      scheduleDate.month != now.month ||
      scheduleDate.day != now.day) {
    return true;
  }

  if (lastRefreshAt == null) {
    return resolvedSchedule.fromCache;
  }

  return now.difference(lastRefreshAt) >= staleAfter;
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  static const _prayerRefreshStaleAfter = Duration(hours: 4);
  static const _prayerRefreshDebounce = Duration(minutes: 2);
  static const _sujudIconAsset =
      'assets/images/prayer_positions/sujud_icon.svg';

  static const _weekdaysArabic = [
    'الاثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
    'الأحد',
  ];
  late DateTime _selectedDate;
  late final ScrollController _scrollController;
  late final ScrollController _calendarController;
  DateTime? _lastPrayerRefreshAt;
  DateTime? _lastPrayerRefreshAttemptAt;
  bool _isRefreshingPrayerTimes = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _selectedDate = _dateOnly(DateTime.now());
    _scrollController = ScrollController();
    _calendarController = ScrollController(initialScrollOffset: 6 * 62.0);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _refreshPrayerTimesIfStale();
      await ref.read(adhanManagerProvider).scheduleTodayAdhans();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    _calendarController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshPrayerTimesIfStale();
    }
  }

  Future<void> _refreshPrayerTimesIfStale() async {
    if (!mounted || _isRefreshingPrayerTimes) {
      return;
    }

    final now = DateTime.now();
    final lastAttempt = _lastPrayerRefreshAttemptAt;
    if (lastAttempt != null &&
        now.difference(lastAttempt) < _prayerRefreshDebounce) {
      return;
    }
    _lastPrayerRefreshAttemptAt = now;

    final resolvedSchedule = ref.read(prayerScheduleProvider).valueOrNull;
    if (!shouldRefreshPrayerTimesIfStale(
      resolvedSchedule: resolvedSchedule,
      now: now,
      lastRefreshAt: _lastPrayerRefreshAt,
      staleAfter: _prayerRefreshStaleAfter,
    )) {
      return;
    }

    _isRefreshingPrayerTimes = true;
    try {
      final today = _dateOnly(now);
      if (_selectedDate.isBefore(today) && mounted) {
        setState(() => _selectedDate = today);
      }

      await _primePrayerLocationForRefresh();
      final refreshedSchedule = await _reloadPrayerTimes();
      if (refreshedSchedule != null) {
        _lastPrayerRefreshAt = DateTime.now();
        await ref.read(adhanManagerProvider).scheduleTodayAdhans();
      }
    } finally {
      _isRefreshingPrayerTimes = false;
    }
  }

  Future<void> _forceRefreshPrayerTimes() async {
    if (!mounted || _isRefreshingPrayerTimes) {
      return;
    }
    _isRefreshingPrayerTimes = true;
    try {
      await _primePrayerLocationForRefresh();
      final refreshedSchedule = await _reloadPrayerTimes();
      if (refreshedSchedule != null) {
        _lastPrayerRefreshAt = DateTime.now();
        await ref.read(adhanManagerProvider).scheduleTodayAdhans();
      }
    } finally {
      _isRefreshingPrayerTimes = false;
    }
  }

  Future<void> _primePrayerLocationForRefresh() async {
    try {
      final hasManualLocation =
          await ref.read(prayerLocationDataSourceProvider).hasManualLocation();
      if (hasManualLocation) {
        return;
      }
      await ref.read(prayerLocationDataSourceProvider).getLocation(
            allowCachedFallbackWhenUnavailable: false,
          );
    } catch (_) {
      // Keep the home screen usable; the schedule provider can still fall back
      // to the last cached location when live GPS is not immediately available.
    }
  }

  Future<ResolvedPrayerSchedule?> _reloadPrayerTimes() async {
    ref.invalidate(manualPrayerLocationProvider);
    ref.invalidate(prayerLocationProvider);
    ref.invalidate(prayerLocationDiagnosticProvider);
    ref.invalidate(lastLocationLabelProvider);
    ref.invalidate(recentLocationsProvider);
    ref.invalidate(travelBannerProvider);
    ref.invalidate(prayerScheduleProvider);
    ref.invalidate(nextPrayerInfoProvider);
    ref.invalidate(prayerCountdownProvider);
    ref.invalidate(prayerScheduleForDateProvider(_selectedDate));

    final resolvedSchedule = await ref.read(prayerScheduleProvider.future);
    ref.invalidate(nextPrayerInfoProvider);
    ref.invalidate(prayerCountdownProvider);
    ref.invalidate(prayerScheduleForDateProvider(_selectedDate));
    return resolvedSchedule;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(homeScrollToTopSignalProvider, (_, __) {
      if (!_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
      );
    });

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
    final manualLocationAsync = ref.watch(manualPrayerLocationProvider);
    final ramadanStatusAsync = ref.watch(ramadanStatusProvider);
    final lastReadingAsync = ref.watch(lastReadingProvider);
    final dhikrSnapshotAsync = ref.watch(dhikrSnapshotProvider);
    final tracking = ref.watch(prayerTrackingProvider);
    final streak = tracking.currentStreak;
    final selectedCompletedPrayers =
        tracking.completedPrayersFor(_selectedDate);
    final selectedNextPrayerInfo = isSelectedToday ? nextPrayerInfo : null;
    final selectedCountdown = isSelectedToday ? countdownAsync.value : null;

    return Scaffold(
      backgroundColor: tokens.bgPage,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _blend(tokens.primary, tokens.bgPage,
                  _isLightTheme(tokens) ? 0.03 : 0.06),
              tokens.bgPage,
              _blend(tokens.accent, tokens.bgApp,
                  _isLightTheme(tokens) ? 0.02 : 0.04),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _forceRefreshPrayerTimes,
            color: tokens.primary,
            backgroundColor: tokens.bgSurface,
            child: ListView(
              controller: _scrollController,
              padding: EdgeInsets.zero,
              children: [
                _buildHeader(
                  context,
                  tokens,
                  locationLabelAsync.valueOrNull,
                  locationDiagnosticAsync.valueOrNull,
                  manualLocationAsync.valueOrNull,
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
                  data: (resolvedSchedule) => _buildPrayerTimeline(
                    resolvedSchedule?.schedule,
                    _selectedDate,
                    ramadanStatusAsync.valueOrNull,
                    tokens,
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
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
    PrayerLocationDiagnostic? locationDiagnostic,
    ManualPrayerLocation? manualLocation,
    bool isOnline,
  ) {
    final l10n = context.l10n;
    final statusLine = _buildHeaderLocationStatus(
      l10n,
      locationLabel,
      locationDiagnostic,
      manualLocation,
      isOnline,
    );
    final isGpsLocation = manualLocation == null &&
        locationLabel != null &&
        locationLabel.trim().isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkResponse(
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SupportScreen()),
              );
            },
            radius: 26,
            child: SvgPicture.asset(
              'assets/images/app/logo.svg',
              width: 40,
              height: 40,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.appTitle,
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: tokens.primary,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _showLocationModeDialog(
                    manualLocation: manualLocation,
                    isGpsLocation: isGpsLocation,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          statusLine,
                          style: GoogleFonts.dmSans(
                            fontSize: 10,
                            color: tokens.textSecondary,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.expand_more_rounded,
                        size: 13,
                        color: tokens.textSecondary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: _blend(tokens.bgSurface2, tokens.bgSurface,
                  _isLightTheme(tokens) ? 0.7 : 0.88),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                  color: _blend(tokens.primary, tokens.border, 0.12)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black
                      .withValues(alpha: _isLightTheme(tokens) ? 0.04 : 0.16),
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

  String _buildHeaderLocationStatus(
    AppLocalizations l10n,
    String? locationLabel,
    PrayerLocationDiagnostic? locationDiagnostic,
    ManualPrayerLocation? manualLocation,
    bool isOnline,
  ) {
    if (manualLocation != null) {
      return l10n.homeUsingSelectedCity(manualLocation.city);
    }

    final visibleLocation = locationLabel?.trim();
    if (visibleLocation != null && visibleLocation.isNotEmpty) {
      return l10n.homeHeaderStatusLine(
        isOnline ? l10n.homeHeaderOnline : l10n.homeHeaderOffline,
        visibleLocation,
      );
    }

    if (locationDiagnostic?.hasCachedLocation == true) {
      return l10n.homeHeroUsingSavedLocation;
    }

    return l10n.homeHeaderLocationUnavailable;
  }

  Widget _buildPeriodModeBanner(BuildContext context, QiblaTokens tokens) {
    final periodEnabledAsync = ref.watch(periodModeEnabledProvider);
    final isEnabled = periodEnabledAsync.valueOrNull ?? false;
    if (!isEnabled) return const SizedBox.shrink();

    final l10n = context.l10n;
    const color = Color(0xFFD17B8A);
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
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.30)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.pause_circle_outline, size: 14, color: color),
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
                    padding:
                        const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isSelected
                            ? [
                                _blend(tokens.primary, tokens.bgSurface, 0.22),
                                _blend(tokens.primary, tokens.bgSurface, 0.08),
                              ]
                            : [
                                _blend(
                                    tokens.bgSurface2, tokens.bgSurface, 0.86),
                                tokens.bgSurface,
                              ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isSelected
                            ? tokens.primary.withValues(alpha: 0.35)
                            : isToday
                                ? tokens.primaryBorder
                                : tokens.border,
                        width: isSelected ? 1.4 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected
                              ? tokens.primary.withValues(alpha: 0.16)
                              : Colors.black.withValues(alpha: 0.08),
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
                            color: isSelected
                                ? tokens.primaryLight
                                : tokens.textSecondary,
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
                                color: isSelected
                                    ? tokens.primary
                                    : tokens.textMuted,
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
                            color: isSelected
                                ? tokens.primaryLight
                                : tokens.textMuted,
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
        border:
            Border.all(color: _blend(tokens.primary, tokens.borderMed, 0.22)),
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
            color: Colors.black.withValues(alpha: 0.18),
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
                  color: tokens.primary.withValues(alpha: 0.045),
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
                        tokens.primary.withValues(alpha: 0.08),
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
                      color: tokens.primary.withValues(alpha: 0.65),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _blend(tokens.primary, tokens.bgSurface, 0.12),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                          color: _blend(tokens.primary, tokens.borderMed, 0.2)),
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
            _blend(tokens.primary, tokens.bgSurface,
                _isLightTheme(tokens) ? 0.06 : 0.1),
            _blend(tokens.bgSurface2, tokens.bgSurface, 0.9),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
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
              color: tokens.primary.withValues(alpha: 0.45),
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
          const SizedBox(height: 12),
          // Retry button — lets the user trigger a fresh location attempt
          // instead of waiting indefinitely with no feedback.
          OutlinedButton.icon(
            onPressed: () => ref.invalidate(prayerLocationDiagnosticProvider),
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: Text(l10n.commonRetry),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackHero(
    QiblaTokens tokens,
    PrayerLocationDiagnostic? diagnostic,
  ) {
    final l10n = context.l10n;
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
          const SizedBox(height: 10),
          Text(
            l10n.homeLocationTapHint,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              color: tokens.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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
    final completedCount =
        items.where((item) => item.state == _RamadanGoalState.completed).length;

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
    final (iconColor, chipLabel, chipBg, chipBorder) =
        _goalStyle(tokens, item.state);

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
                if (!mounted) return;
                ref.invalidate(lastReadingProvider);
                ref.invalidate(dhikrSnapshotProvider);
              },
              icon:
                  Icon(Icons.arrow_forward, size: 18, color: tokens.textMuted),
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

  void _refreshPrayerLocationState() {
    ref.invalidate(manualPrayerLocationProvider);
    ref.invalidate(prayerLocationProvider);
    ref.invalidate(prayerLocationDiagnosticProvider);
    ref.invalidate(lastLocationLabelProvider);
    ref.invalidate(recentLocationsProvider);
    ref.invalidate(prayerScheduleProvider);
    ref.invalidate(nextPrayerInfoProvider);
    ref.invalidate(prayerCountdownProvider);
    ref.invalidate(prayerScheduleForDateProvider(_selectedDate));
  }

  Future<void> _showLocationModeDialog({
    required ManualPrayerLocation? manualLocation,
    required bool isGpsLocation,
  }) async {
    final l10n = context.l10n;
    final tokens = QiblaThemes.current;
    final modeTitle = manualLocation != null
        ? l10n.homeLocationModeManual
        : l10n.homeLocationModeGps;
    final modeBody = manualLocation != null
        ? manualLocation.label
        : isGpsLocation
            ? l10n.homeLocationModeDeviceGps
            : l10n.homeLocationModeGpsUnavailable;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return SafeArea(
          minimum: const EdgeInsets.all(18),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: tokens.bgSurface,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: tokens.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 28,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: _blend(
                                  tokens.primary, tokens.bgSurface, 0.12),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Icon(
                              manualLocation != null
                                  ? Icons.location_city_rounded
                                  : Icons.gps_fixed_rounded,
                              color: tokens.primary,
                              size: 19,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  modeTitle,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 13,
                                    color: tokens.textSecondary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  modeBody,
                                  style: GoogleFonts.dmSerifDisplay(
                                    fontSize: 22,
                                    color: tokens.primary,
                                    height: 1.05,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      if (manualLocation != null) ...[
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () {
                              Navigator.of(dialogContext).pop();
                              _showManualCitySheet();
                            },
                            icon: const Icon(Icons.edit_location_alt_rounded,
                                size: 16),
                            label: Text(l10n.homeManualCityChange),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              await ref
                                  .read(manualPrayerLocationDataSourceProvider)
                                  .clearManualLocation();
                              if (!mounted) {
                                return;
                              }
                              _refreshPrayerLocationState();
                              if (!dialogContext.mounted) {
                                return;
                              }
                              Navigator.of(dialogContext).pop();
                            },
                            icon: const Icon(Icons.gps_fixed_rounded, size: 16),
                            label: Text(l10n.homeUseDeviceGps),
                          ),
                        ),
                      ] else ...[
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () {
                              Navigator.of(dialogContext).pop();
                              _showManualCitySheet();
                            },
                            icon: const Icon(Icons.location_city_rounded,
                                size: 16),
                            label: Text(l10n.homeSelectCityManually),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showManualCitySheet() async {
    final l10n = context.l10n;
    final cityController = TextEditingController();
    final citiesDataSource = ref.read(offlinePrayerCitiesDataSourceProvider);
    final manualLocationDataSource =
        ref.read(manualPrayerLocationDataSourceProvider);
    var cityQuery = '';
    var isSaving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final tokens = QiblaThemes.current;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final dialogNavigator = Navigator.of(dialogContext);
            final messenger = ScaffoldMessenger.of(context);

            Future<void> saveOfflineCity(
              OfflinePrayerCitySuggestion suggestion,
            ) async {
              if (isSaving) {
                return;
              }

              setSheetState(() => isSaving = true);
              try {
                final city =
                    await citiesDataSource.resolveSuggestion(suggestion);
                await manualLocationDataSource.saveOfflineCity(city);
                if (!mounted) {
                  return;
                }
                _refreshPrayerLocationState();
                dialogNavigator.pop();
                await ref.read(adhanManagerProvider).scheduleTodayAdhans();
              } catch (_) {
                if (!mounted || !context.mounted) {
                  return;
                }
                setSheetState(() => isSaving = false);
                showQiblaSnackBarWithMessenger(
                  context,
                  messenger: messenger,
                  message: l10n.homeManualCityNotFound,
                );
              }
            }

            Future<void> saveTypedCity() async {
              final city = cityController.text.trim();
              if (city.isEmpty || isSaving) {
                return;
              }

              setSheetState(() => isSaving = true);
              try {
                final resolved = await manualLocationDataSource.resolveAndSave(
                  country: '',
                  city: city,
                );
                if (!mounted) {
                  return;
                }
                final confirmed = await _confirmManualCity(resolved);
                if (!confirmed) {
                  setSheetState(() => isSaving = false);
                  return;
                }
                _refreshPrayerLocationState();
                dialogNavigator.pop();
                await ref.read(adhanManagerProvider).scheduleTodayAdhans();
              } catch (_) {
                if (!mounted || !context.mounted) {
                  return;
                }
                setSheetState(() => isSaving = false);
                showQiblaSnackBarWithMessenger(
                  context,
                  messenger: messenger,
                  message: l10n.homeManualCityNotFound,
                );
              }
            }

            Widget buildCitySuggestions() {
              if (cityQuery.trim().length < 2) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Text(
                    l10n.homeManualCityEmptyHint,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      height: 1.45,
                      color: tokens.textSecondary,
                    ),
                  ),
                );
              }

              return FutureBuilder<List<OfflinePrayerCitySuggestion>>(
                future: citiesDataSource.searchGlobalCities(
                  query: cityQuery,
                ),
                builder: (context, snapshot) {
                  final cities = snapshot.data ?? const [];
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (cities.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            l10n.homeManualCityNoResults,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color: tokens.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: isSaving ? null : () => saveTypedCity(),
                            icon: const Icon(Icons.public_rounded, size: 16),
                            label: Text(
                              l10n.homeManualCityOnlineFallback,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: cities.length,
                    separatorBuilder: (_, __) =>
                        Divider(color: tokens.border, height: 1),
                    itemBuilder: (_, index) {
                      final city = cities[index];
                      return ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        leading: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: tokens.primary.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.location_city_rounded,
                            size: 17,
                            color: tokens.primary,
                          ),
                        ),
                        title: Text(
                          city.name,
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: tokens.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          city.countryName,
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: tokens.textSecondary,
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: isSaving ? null : () => saveOfflineCity(city),
                      );
                    },
                  );
                },
              );
            }

            return SafeArea(
              minimum: EdgeInsets.fromLTRB(
                18,
                18,
                18,
                MediaQuery.of(context).viewInsets.bottom + 18,
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final maxDialogHeight = constraints.maxHeight;
                  final suggestionsHeight =
                      (maxDialogHeight * 0.42).clamp(160.0, 280.0);
                  return Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: 430,
                        maxHeight: maxDialogHeight,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: tokens.bgSurface,
                            borderRadius: BorderRadius.circular(26),
                            border: Border.all(color: tokens.border),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: tokens.primary
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Icon(
                                      Icons.travel_explore_rounded,
                                      color: tokens.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      l10n.homeManualCityTitle,
                                      style: GoogleFonts.dmSerifDisplay(
                                        fontSize: 24,
                                        color: tokens.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                l10n.homeManualCityBody,
                                style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  height: 1.45,
                                  color: tokens.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: cityController,
                                autofocus: true,
                                textInputAction: TextInputAction.search,
                                onChanged: (value) {
                                  setSheetState(() => cityQuery = value);
                                },
                                onSubmitted: (_) {
                                  if (cityQuery.trim().isNotEmpty) {
                                    saveTypedCity();
                                  }
                                },
                                decoration: InputDecoration(
                                  hintText: l10n.homeManualCitySearchHint,
                                  prefixIcon: const Icon(Icons.search_rounded,
                                      size: 20),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(18),
                                    borderSide:
                                        BorderSide(color: tokens.border),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(18),
                                    borderSide: BorderSide(
                                      color: tokens.primary,
                                      width: 1.4,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: suggestionsHeight,
                                child: ClipRect(
                                  child: buildCitySuggestions(),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                l10n.homeManualCityGeoNamesAttribution,
                                style: GoogleFonts.dmSans(
                                  fontSize: 10,
                                  color: tokens.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  TextButton(
                                    onPressed: isSaving
                                        ? null
                                        : () =>
                                            Navigator.of(dialogContext).pop(),
                                    child: Text(l10n.commonCancel),
                                  ),
                                  const Spacer(),
                                  if (isSaving)
                                    SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: tokens.primary,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );

    cityController.dispose();
  }

  Future<bool> _confirmManualCity(ManualPrayerLocation location) async {
    final l10n = context.l10n;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.homeManualCityConfirmTitle),
          content: Text(
            l10n.homeManualCityConfirmBody(
              location.label,
              location.latitude.toStringAsFixed(4),
              location.longitude.toStringAsFixed(4),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.homeManualCityConfirmUse),
            ),
          ],
        );
      },
    );
    if (result != true) {
      await ref
          .read(manualPrayerLocationDataSourceProvider)
          .clearManualLocation();
    }
    return result == true;
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
          color: Colors.black.withValues(alpha: 0.18),
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
      height: 230,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: 0,
            child: SizedBox(
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
          ),
          Positioned(
            top: 0,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 136),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _blend(tokens.bgSurface, Colors.black, 0.9),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: _blend(tokens.primary, tokens.borderMed, 0.18),
                ),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  l10n.homeCountdownLabelUppercase,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    fontSize: 9,
                    color: tokens.textSecondary,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 17,
            child: Container(
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
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: SizedBox(
                      width: 120,
                      child: Text(
                        contextLabel,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
                          color: tokens.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerTimeline(
    PrayerSchedule? prayerSchedule,
    DateTime date,
    RamadanStatus? ramadanStatus,
    QiblaTokens tokens,
  ) {
    if (prayerSchedule == null) {
      return const SizedBox.shrink();
    }

    final l10n = context.l10n;
    final fastingActive = ramadanStatus?.isEnabled == true;
    final items = <_PrayerTimelineItem>[
      _PrayerTimelineItem(
        label: fastingActive
            ? l10n.homePrayerTimelineFajrImsak
            : l10n.homePrayerTimelineFajr,
        time: prayerSchedule.fajr,
        icon: _prayerIcon(PrayerName.fajr),
        prayer: PrayerName.fajr,
      ),
      if (prayerSchedule.sunrise != null)
        _PrayerTimelineItem(
          label: l10n.homePrayerTimelineShuruq,
          time: prayerSchedule.sunrise!,
          icon: Icons.wb_twilight_rounded,
        ),
      _PrayerTimelineItem(
        label: l10n.homePrayerTimelineDhuhr,
        time: prayerSchedule.dhuhr,
        icon: _prayerIcon(PrayerName.dhuhr),
        prayer: PrayerName.dhuhr,
      ),
      _PrayerTimelineItem(
        label: l10n.homePrayerTimelineAsr,
        time: prayerSchedule.asr,
        icon: _prayerIcon(PrayerName.asr),
        prayer: PrayerName.asr,
      ),
      _PrayerTimelineItem(
        label: fastingActive
            ? l10n.homePrayerTimelineIftar
            : l10n.homePrayerTimelineMaghrib,
        time: prayerSchedule.maghrib,
        icon: _prayerIcon(PrayerName.maghrib),
        prayer: PrayerName.maghrib,
      ),
      _PrayerTimelineItem(
        label: l10n.homePrayerTimelineIsha,
        time: prayerSchedule.isha,
        icon: _prayerIcon(PrayerName.isha),
        prayer: PrayerName.isha,
      ),
    ];

    final now = DateTime.now();
    final isToday = _isSameDay(date, _dateOnly(now));
    final completedIndex = isToday ? _lastPassedTimelineIndex(items, now) : -1;
    final highlightedInterval =
        isToday ? _currentTimelineInterval(items, now) : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
        decoration: BoxDecoration(
          color: _blend(tokens.bgSurface2, tokens.bgSurface, 0.76),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: _blend(tokens.primary, tokens.border, 0.18),
          ),
          boxShadow: [
            BoxShadow(
              color: tokens.primary.withValues(alpha: 0.05),
              blurRadius: 22,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 360;
            final timelineHeight = compact ? 132.0 : 146.0;
            final nodeBaseSize = compact ? 29.0 : 33.0;

            return SizedBox(
              height: timelineHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _PrayerTimelineCurvePainter(
                        itemCount: items.length,
                        highlightedStartIndex: highlightedInterval?.$1,
                        highlightedEndIndex: highlightedInterval?.$2,
                        trackColor: _blend(
                          tokens.primary,
                          tokens.border,
                          0.16,
                        ),
                        glowColor: tokens.primary,
                        highlightColor: const Color(0xFFD8A53A),
                      ),
                    ),
                  ),
                  ...List.generate(items.length, (index) {
                    final item = items[index];
                    final point = _PrayerTimelineCurvePainter.pointForIndex(
                      Size(constraints.maxWidth, timelineHeight),
                      index,
                      items.length,
                    );
                    final isHighlighted = highlightedInterval != null &&
                        (index == highlightedInterval.$1 ||
                            index == highlightedInterval.$2);
                    final isCompleted = !isHighlighted &&
                        completedIndex >= 0 &&
                        index <= completedIndex;
                    final nodeSize =
                        isHighlighted ? (compact ? 36.0 : 40.0) : nodeBaseSize;
                    final labelWidth = compact ? 58.0 : 68.0;
                    final labelTop = math.min(
                      point.dy + nodeSize * 0.55 + 12,
                      timelineHeight - 45,
                    );
                    final emphasis = isHighlighted
                        ? 1.0
                        : isCompleted
                            ? 0.42
                            : 0.72;
                    final labelColor = isHighlighted
                        ? const Color(0xFFD8A53A)
                        : isCompleted
                            ? tokens.textMuted
                            : tokens.textSecondary;
                    final timeColor = isHighlighted
                        ? const Color(0xFFE9C46A)
                        : isCompleted
                            ? tokens.textMuted
                            : tokens.textPrimary;

                    return Positioned(
                      left: point.dx - labelWidth / 2,
                      top: math.max(0, point.dy - nodeSize / 2),
                      width: labelWidth,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 260),
                            curve: Curves.easeOutCubic,
                            width: nodeSize,
                            height: nodeSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isHighlighted
                                  ? _blend(
                                      const Color(0xFFD8A53A),
                                      tokens.bgSurface,
                                      0.18,
                                    )
                                  : _blend(
                                      tokens.bgSurface,
                                      tokens.bgSurface2,
                                      0.64,
                                    ).withValues(alpha: emphasis),
                              border: Border.all(
                                color: isHighlighted
                                    ? const Color(0xFFD8A53A)
                                    : _blend(
                                        tokens.textMuted,
                                        tokens.border,
                                        0.28,
                                      ).withValues(alpha: emphasis),
                                width: isHighlighted ? 1.8 : 1.2,
                              ),
                              boxShadow: isHighlighted
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFFD8A53A)
                                            .withValues(alpha: 0.18),
                                        blurRadius: 18,
                                        spreadRadius: 1,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Icon(
                              item.icon,
                              size: isHighlighted
                                  ? (compact ? 18 : 20)
                                  : (compact ? 15 : 17),
                              color: labelColor.withValues(
                                alpha: emphasis,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: labelTop - point.dy - nodeSize / 2,
                          ),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 240),
                            curve: Curves.easeOutCubic,
                            style: GoogleFonts.dmSans(
                              fontSize: compact ? 8.2 : 9.2,
                              height: 1.08,
                              letterSpacing: 0.6,
                              fontWeight: isHighlighted
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: labelColor,
                            ),
                            child: Text(
                              item.label,
                              maxLines: 2,
                              softWrap: true,
                              overflow: TextOverflow.visible,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 4),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 240),
                            curve: Curves.easeOutCubic,
                            style: GoogleFonts.dmSans(
                              fontSize: isHighlighted
                                  ? (compact ? 12.5 : 13.5)
                                  : (compact ? 10.5 : 11.5),
                              height: 1,
                              fontWeight: isHighlighted
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: timeColor,
                            ),
                            child: Text(
                              _formatTime(item.time),
                              maxLines: 1,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  int _lastPassedTimelineIndex(List<_PrayerTimelineItem> items, DateTime now) {
    for (var i = items.length - 1; i >= 0; i--) {
      if (!now.isBefore(items[i].time)) {
        return i;
      }
    }
    return -1;
  }

  (int, int)? _currentTimelineInterval(
    List<_PrayerTimelineItem> items,
    DateTime now,
  ) {
    if (items.length <= 1 || now.isBefore(items.first.time)) {
      return null;
    }

    for (var index = 0; index < items.length - 1; index++) {
      if (!now.isBefore(items[index].time) &&
          now.isBefore(items[index + 1].time)) {
        return (index, index + 1);
      }
    }

    return null;
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
            final isNow = isToday &&
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
                                    fontWeight:
                                        tone == _PremiumPrayerCardTone.idle
                                            ? FontWeight.w600
                                            : FontWeight.w700,
                                    color: tone == _PremiumPrayerCardTone.next
                                        ? tokens.primary
                                        : tokens.textPrimary,
                                  ),
                                ),
                              ),
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
                                            ? l10n
                                                .homePrayerDescriptionPendingToday
                                            : l10n
                                                .homePrayerDescriptionReviewDate,
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
                              color:
                                  _blend(style.timeColor, tokens.border, 0.12),
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
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            ref
                                .read(prayerTrackingProvider.notifier)
                                .togglePrayer(prayer.$1.key, date: date);
                          },
                          child: SizedBox(
                            width: 44,
                            height: 44,
                            child: Center(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(999),
                                  color: isDone
                                      ? tokens.accent
                                      : _blend(
                                          tokens.bgSurface2,
                                          tokens.bgSurface,
                                          0.82,
                                        ),
                                  border: Border.all(
                                    color: isDone
                                        ? tokens.accent
                                        : _blend(
                                            tokens.textMuted,
                                            tokens.border,
                                            0.22,
                                          ),
                                    width: 1.4,
                                  ),
                                ),
                                child: Icon(
                                  isDone
                                      ? Icons.check_rounded
                                      : Icons.add_task_rounded,
                                  size: 16,
                                  color: isDone
                                      ? tokens.bgPage
                                      : tokens.textSecondary,
                                ),
                              ),
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
    final actions = <({
      IconData? icon,
      String? svgAsset,
      String label,
      Widget destination
    })>[
      (
        icon: Icons.auto_stories_outlined,
        svgAsset: null,
        label: l10n.commonHadiths,
        destination: const HadithLibraryScreen(),
      ),
      (
        icon: Icons.library_books_outlined,
        svgAsset: null,
        label: l10n.commonBooks,
        destination: const IslamicBooksScreen(),
      ),
      (
        icon: Icons.water_drop_outlined,
        svgAsset: null,
        label: l10n.homeQuickActionPurification,
        destination: const PurificationGuideScreen(),
      ),
      (
        icon: null,
        svgAsset: _sujudIconAsset,
        label: l10n.focusModeTitle,
        destination: const FocusModeScreen(),
      ),
      (
        icon: Icons.calendar_month_outlined,
        svgAsset: null,
        label: l10n.calendarTitle,
        destination: const CalendarScreen(),
      ),
      (
        icon: Icons.insights_outlined,
        svgAsset: null,
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
                  if (!mounted) return;
                  ref.invalidate(lastReadingProvider);
                  ref.invalidate(dhikrSnapshotProvider);
                },
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  decoration: BoxDecoration(
                    color: _blend(tokens.bgSurface2, tokens.bgSurface, 0.88),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: _blend(tokens.primary, tokens.border, 0.08)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
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
                        child: Center(
                          child: action.svgAsset == null
                              ? Icon(
                                  action.icon,
                                  size: 20,
                                  color: tokens.primary,
                                )
                              : SvgPicture.asset(
                                  action.svgAsset!,
                                  width: 24,
                                  height: 24,
                                  colorFilter: ColorFilter.mode(
                                    tokens.primary,
                                    BlendMode.srcIn,
                                  ),
                                ),
                        ),
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
    switch (tone) {
      case _PremiumPrayerCardTone.now:
        return _PremiumPrayerCardStyle(
          surfaceColor: _blend(tokens.accent, tokens.bgSurface, 0.16),
          borderColor: _blend(tokens.accent, tokens.borderMed, 0.22),
          shadowColor: tokens.accent.withValues(alpha: 0.12),
          iconBackground: _blend(tokens.accent, tokens.bgSurface2, 0.2),
          iconColor: tokens.accent,
          timeBackground: _blend(tokens.accent, tokens.bgSurface, 0.14),
          timeColor: tokens.textPrimary,
        );
      case _PremiumPrayerCardTone.next:
        return _PremiumPrayerCardStyle(
          surfaceColor: _blend(tokens.primary, tokens.bgSurface, 0.14),
          borderColor: _blend(tokens.primary, tokens.primaryBorder, 0.2),
          shadowColor: tokens.primary.withValues(alpha: 0.12),
          iconBackground: _blend(tokens.primary, tokens.bgSurface2, 0.18),
          iconColor: tokens.primary,
          timeBackground: _blend(tokens.primary, tokens.bgSurface, 0.12),
          timeColor: tokens.primaryLight,
        );
      case _PremiumPrayerCardTone.completed:
        return _PremiumPrayerCardStyle(
          surfaceColor: _blend(tokens.bgSurface, tokens.bgPage, 0.9),
          borderColor: tokens.border,
          shadowColor: Colors.black.withValues(alpha: 0.06),
          iconBackground: _blend(tokens.accent, tokens.bgSurface, 0.1),
          iconColor: tokens.accent,
          timeBackground: _blend(tokens.bgSurface2, tokens.bgSurface, 0.88),
          timeColor: tokens.textSecondary,
        );
      case _PremiumPrayerCardTone.upcoming:
        return _PremiumPrayerCardStyle(
          surfaceColor: _blend(tokens.bgSurface2, tokens.bgSurface, 0.84),
          borderColor: _blend(tokens.primary, tokens.border, 0.08),
          shadowColor: Colors.black.withValues(alpha: 0.07),
          iconBackground: _blend(tokens.primary, tokens.bgSurface, 0.08),
          iconColor: tokens.textSecondary,
          timeBackground: _blend(tokens.bgSurface, tokens.bgPage, 0.82),
          timeColor: tokens.textPrimary,
        );
      case _PremiumPrayerCardTone.idle:
        return _PremiumPrayerCardStyle(
          surfaceColor: tokens.bgSurface,
          borderColor: tokens.border,
          shadowColor: Colors.black.withValues(alpha: 0.06),
          iconBackground: tokens.bgSurface2,
          iconColor: tokens.textSecondary,
          timeBackground: _blend(tokens.bgSurface2, tokens.bgSurface, 0.88),
          timeColor: tokens.textPrimary,
        );
    }
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
    return ThemeData.estimateBrightnessForColor(tokens.bgPage) ==
        Brightness.light;
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
    required this.surfaceColor,
    required this.borderColor,
    required this.shadowColor,
    required this.iconBackground,
    required this.iconColor,
    required this.timeBackground,
    required this.timeColor,
  });

  final Color surfaceColor;
  final Color borderColor;
  final Color shadowColor;
  final Color iconBackground;
  final Color iconColor;
  final Color timeBackground;
  final Color timeColor;
}

class _PrayerTimelineItem {
  const _PrayerTimelineItem({
    required this.label,
    required this.time,
    required this.icon,
    this.prayer,
  });

  final String label;
  final DateTime time;
  final IconData icon;
  final PrayerName? prayer;
}

class _PrayerTimelineCurvePainter extends CustomPainter {
  const _PrayerTimelineCurvePainter({
    required this.itemCount,
    required this.highlightedStartIndex,
    required this.highlightedEndIndex,
    required this.trackColor,
    required this.glowColor,
    required this.highlightColor,
  });

  final int itemCount;
  final int? highlightedStartIndex;
  final int? highlightedEndIndex;
  final Color trackColor;
  final Color glowColor;
  final Color highlightColor;

  static Offset pointForIndex(Size size, int index, int itemCount) {
    if (itemCount <= 1) {
      return Offset(size.width / 2, size.height * 0.34);
    }

    final t = index / (itemCount - 1);
    return pointOnArc(size, t);
  }

  static Offset pointOnArc(Size size, double t) {
    final safeWidth = math.max(1.0, size.width);
    final clampedT = t.clamp(0.0, 1.0).toDouble();
    final horizontalPadding = math.min(36.0, safeWidth * 0.1);
    final x =
        horizontalPadding + (safeWidth - horizontalPadding * 2) * clampedT;
    final baseY = size.height * 0.42;
    final arcHeight = size.height * 0.22;
    final y = baseY - math.sin(math.pi * clampedT) * arcHeight;
    return Offset(x, y);
  }

  Path _arcPath(Size size) {
    final path = Path();
    if (itemCount <= 0) return path;

    final first = pointOnArc(size, 0);
    path.moveTo(first.dx, first.dy);
    const segmentCount = 80;
    for (var i = 1; i <= segmentCount; i++) {
      final point = pointOnArc(size, i / segmentCount);
      path.lineTo(point.dx, point.dy);
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (itemCount <= 1) return;

    final path = _arcPath(size);
    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final shadowPaint = Paint()
      ..color = glowColor.withValues(alpha: 0.06)
      ..strokeWidth = 9
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    canvas
      ..drawPath(path, shadowPaint)
      ..drawPath(path, trackPaint);

    final startIndex = highlightedStartIndex;
    final endIndex = highlightedEndIndex;
    if (startIndex == null || endIndex == null) return;

    final pathMetrics = path.computeMetrics().toList(growable: false);
    if (pathMetrics.isEmpty) return;

    final metric = pathMetrics.first;
    final clampedStart = startIndex.clamp(0, itemCount - 1);
    final clampedEnd = endIndex.clamp(0, itemCount - 1);
    if (clampedStart == clampedEnd) return;

    final startProgress = clampedStart / (itemCount - 1);
    final endProgress = clampedEnd / (itemCount - 1);
    final highlightedPath = metric.extractPath(
      metric.length * math.min(startProgress, endProgress),
      metric.length * math.max(startProgress, endProgress),
    );
    final highlightGlowPaint = Paint()
      ..color = highlightColor.withValues(alpha: 0.16)
      ..strokeWidth = 9
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    final highlightPaint = Paint()
      ..color = highlightColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas
      ..drawPath(highlightedPath, highlightGlowPaint)
      ..drawPath(highlightedPath, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant _PrayerTimelineCurvePainter oldDelegate) {
    return oldDelegate.itemCount != itemCount ||
        oldDelegate.highlightedStartIndex != highlightedStartIndex ||
        oldDelegate.highlightedEndIndex != highlightedEndIndex ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.glowColor != glowColor ||
        oldDelegate.highlightColor != highlightColor;
  }
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
    const stroke = 4.0;
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
