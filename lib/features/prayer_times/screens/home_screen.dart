import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hijri/hijri_calendar.dart';

import '../../../core/services/connectivity_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../calendar/screens/calendar_screen.dart';
import '../../dhikr/screens/dhikr_screen.dart';
import '../../dhikr/services/dhikr_service.dart';
import '../../focus/screens/focus_mode_screen.dart';
import '../../hadith/screens/hadith_library_screen.dart';
import '../../hadith/widgets/daily_hadith_widget.dart';
import '../../library/screens/islamic_books_screen.dart';
import '../../library/widgets/daily_book_widget.dart';
import '../../quran/models/quran_models.dart';
import '../../quran/screens/quran_screen.dart';
import '../../quran/services/quran_reading_service.dart';
import '../../support/screens/settings_screen.dart';
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
import '../services/adhan_manager.dart';
import '../services/travel_mode_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const _weekdays = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
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
      body: SafeArea(
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
              selectedPrayerScheduleAsync.when(
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
              selectedPrayerScheduleAsync.when(
                data: (resolvedSchedule) => _buildPrayerSection(
                  resolvedSchedule?.schedule,
                  selectedNextPrayerInfo,
                  selectedCompletedPrayers,
                  _selectedDate,
                  tokens,
                ),
                loading: () => _buildPrayerSkeleton(tokens),
                error: (_, __) => _buildPrayerFallback(
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
              _buildCalendarStrip(tokens),
              // Hadiz del día - Widget mejorado con 1,954 hadices
              const DailyHadithWidget(),
              // Libro del día - IslamHouse
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
    );
  }

  Widget _buildHeader(
    BuildContext context,
    QiblaTokens tokens,
    String? locationLabel,
    bool isOnline,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Qibla Time',
                  style: GoogleFonts.amiri(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: tokens.primary,
                  ),
                ),
                Text(
                  '${isOnline ? 'En línea' : 'Sin red'} - ${locationLabel ?? 'Ubicación no disponible'}',
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    color: tokens.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: tokens.bgSurface,
              shape: BoxShape.circle,
              border: Border.all(color: tokens.border),
            ),
            child: IconButton(
              tooltip: 'Ajustes',
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
    final today = _dateOnly(DateTime.now());
    final dates =
        List.generate(15, (index) => today.subtract(Duration(days: 6 - index)));

    return SizedBox(
      height: 82,
      child: ListView.separated(
        controller: _calendarController,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: dates.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
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
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 58,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? tokens.activeBg
                    : isToday
                        ? tokens.primaryBg
                        : tokens.bgSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? tokens.activeBorder
                      : isToday
                          ? tokens.primaryBorder
                          : tokens.border,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _weekdays[date.weekday - 1],
                    style: GoogleFonts.dmSans(
                      fontSize: 9,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? tokens.primaryLight : tokens.textSecondary,
                    ),
                  ),
                  Text(
                    '${date.day}',
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: tokens.textPrimary,
                    ),
                  ),
                  Text(
                    '${hijri.hDay} ${hijri.getShortMonthName()}',
                    style: GoogleFonts.dmSans(
                      fontSize: 8,
                      color: isSelected ? tokens.primary : tokens.textMuted,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  if (isSelected)
                    Container(
                      width: 16,
                      height: 4,
                      decoration: BoxDecoration(
                        color: tokens.primary,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    )
                  else if (hasEvent)
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: tokens.primary,
                        shape: BoxShape.circle,
                      ),
                    )
                  else
                    const SizedBox(height: 4),
                ],
              ),
            ),
          );
        },
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
    final prayerSchedule = resolvedSchedule?.schedule;
    if (prayerSchedule == null) {
      return _buildFallbackHero(tokens, locationDiagnostic);
    }

    final isToday = _isSameDay(selectedDate, _dateOnly(DateTime.now()));
    if (!isToday || nextPrayerInfo == null) {
      return _buildSelectedDateHero(
        tokens,
        prayerSchedule,
        selectedDate,
        streak,
        resolvedSchedule?.fromCache == true,
      );
    }

    final hero = tokens.getHero(nextPrayerInfo.prayer.key);
    final names = _prayerName(nextPrayerInfo.prayer);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: hero.bg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: tokens.primaryBorder),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [hero.bg, hero.tint],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Próxima oración'.toUpperCase(),
                  style: GoogleFonts.dmSans(
                    fontSize: 9,
                    color: hero.label,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: tokens.primaryBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: tokens.primaryBorder),
                ),
                child: Text(
                  '$streak días seguidos',
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    color: tokens.primaryLight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${names.$1} - ${names.$2}',
            style: GoogleFonts.amiri(
              fontSize: 32,
              color: tokens.primaryLight,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Hoy a las ${_formatTime(nextPrayerInfo.time)} - ${_formatRemaining(remaining)}',
            style: GoogleFonts.dmSans(
              fontSize: 12,
              color: tokens.textSecondary,
            ),
          ),
          if (resolvedSchedule?.fromCache == true) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: tokens.primaryBg,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: tokens.primaryBorder),
              ),
              child: Text(
                'Usando tu última ubicación guardada',
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  color: tokens.textPrimary,
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(children: _buildCountdown(tokens, remaining)),
        ],
      ),
    );
  }

  Widget _buildSelectedDateHero(
    QiblaTokens tokens,
    PrayerSchedule prayerSchedule,
    DateTime selectedDate,
    int streak,
    bool fromCache,
  ) {
    final isToday = _isSameDay(selectedDate, _dateOnly(DateTime.now()));
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tokens.bgSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: tokens.border),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tokens.bgSurface, tokens.bgSurface2],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  isToday
                      ? 'HORARIOS DE HOY'
                      : 'HORARIOS DEL ${_formatHeroDate(selectedDate).toUpperCase()}',
                  style: GoogleFonts.dmSans(
                    fontSize: 9,
                    color: tokens.textSecondary,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: tokens.primaryBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: tokens.primaryBorder),
                ),
                child: Text(
                  '$streak días seguidos',
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    color: tokens.primaryLight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _formatHeroDate(selectedDate),
            style: GoogleFonts.amiri(
              fontSize: 28,
              color: tokens.primaryLight,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Fajr ${_formatTime(prayerSchedule.fajr)} - Dhuhr ${_formatTime(prayerSchedule.dhuhr)} - Maghrib ${_formatTime(prayerSchedule.maghrib)} - Isha ${_formatTime(prayerSchedule.isha)}',
            style: GoogleFonts.dmSans(
              fontSize: 12,
              height: 1.5,
              color: tokens.textSecondary,
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
                'Usando tu última ubicación guardada',
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  color: tokens.textPrimary,
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _summaryMetric(tokens, _formatTime(prayerSchedule.fajr), 'Fajr'),
              ),
              Expanded(
                child: _summaryMetric(
                  tokens,
                  _formatTime(prayerSchedule.maghrib),
                  'Maghrib',
                ),
              ),
              Expanded(
                child: _summaryMetric(tokens, _formatTime(prayerSchedule.isha), 'Isha'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingHero(QiblaTokens tokens) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
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
            'Cargando horarios',
            style: GoogleFonts.dmSans(color: tokens.textPrimary),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            color: tokens.primary,
            backgroundColor: tokens.bgSurface2,
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
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
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
    if (systemPermissionGranted == null || prayerNotificationsEnabled == null) {
      return const SizedBox.shrink();
    }
    if (systemPermissionGranted && prayerNotificationsEnabled) {
      return const SizedBox.shrink();
    }

    final text = !systemPermissionGranted
        ? 'Tus recordatorios de Adhan estan configurados, pero el permiso del sistema sigue pendiente.'
        : 'Los avisos generales de oración están pausados ahora mismo.';

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
    final countdownLabel = beforeImsak
        ? 'Faltan ${_formatRamadanCountdown(targetTime.difference(now))} para Imsak'
        : beforeIftar
        ? 'Faltan ${_formatRamadanCountdown(targetTime.difference(now))} para Iftar'
        : 'Faltan ${_formatRamadanCountdown(targetTime.difference(now))} para Imsak de mañana';

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
                    'MODO RAMADAN',
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
                        ? 'Suhoor'
                        : beforeIftar
                            ? 'Ayuno'
                            : 'Noche',
                    beforeImsak
                        ? 'cierre cercano'
                        : beforeIftar
                            ? 'hasta iftar'
                            : 'proximo foco',
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
                        'INSIGHT DE HOY',
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
                    'RESUMEN SEMANAL',
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
                Expanded(child: _summaryMetric(tokens, '${summary.fullDays}', 'días 5/5')),
                Expanded(child: _summaryMetric(tokens, '${summary.currentStreak}', 'racha actual')),
                Expanded(
                  child: _summaryMetric(
                    tokens,
                    summary.strongestDay.shortLabel,
                    '${summary.strongestDay.completed}/5 mejor día',
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
    final items = <_RamadanGoalItem>[
      _RamadanGoalItem(
        title: 'Oraciones',
        description: '$prayerCount/5 completadas hoy',
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
                    'OBJETIVOS DE RAMADAN',
                    style: GoogleFonts.dmSans(
                      fontSize: 9,
                      color: tokens.textSecondary,
                      letterSpacing: 1.4,
                    ),
                  ),
                ),
                Text(
                  '$completedCount/4 listos',
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
                  ? 'Jornada de Ramadán muy completa. Mantén este ritmo con calma.'
                  : completedCount >= 2
                  ? 'Vas bien hoy. Un pequeño paso más puede cerrar tu día con fuerza.'
                  : 'Empieza por algo pequeño: una oración, unas aleyas o unos minutos de dhikr.',
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
              tooltip: item.actionLabel ?? 'Abrir',
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
    if (lastReading == null) {
      return const _RamadanGoalItem(
        title: 'Corán',
        description: 'Haz una lectura corta hoy y luego podrás retomarla fácilmente.',
        icon: Icons.menu_book_outlined,
        state: _RamadanGoalState.pending,
        destination: QuranScreen(),
        actionLabel: 'Abrir Corán',
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
        title: 'Corán',
        description:
            'Lectura guardada hoy en ${lastReading.surahNameLatin}, aleya ${lastReading.ayahNumber}.',
        icon: Icons.menu_book_outlined,
        state: _RamadanGoalState.completed,
        destination: const QuranScreen(),
        actionLabel: 'Continuar lectura',
      );
    }

    if (daysSince <= 3) {
      return _RamadanGoalItem(
        title: 'Corán',
        description:
            'Retoma ${lastReading.surahNameLatin}, aleya ${lastReading.ayahNumber}. Tienes progreso reciente.',
        icon: Icons.menu_book_outlined,
        state: _RamadanGoalState.inProgress,
        destination: const QuranScreen(),
        actionLabel: 'Continuar lectura',
      );
    }

    return _RamadanGoalItem(
      title: 'Corán',
      description:
          'Tu último punto fue ${lastReading.surahNameLatin}, aleya ${lastReading.ayahNumber}. Merece la pena retomarlo hoy.',
      icon: Icons.menu_book_outlined,
      state: _RamadanGoalState.pending,
      destination: const QuranScreen(),
      actionLabel: 'Abrir Corán',
    );
  }

  _RamadanGoalItem _buildDhikrGoal(DhikrSnapshot? snapshot) {
    if (snapshot == null) {
      return const _RamadanGoalItem(
        title: 'Dhikr',
        description: 'Preparando tu progreso diario de dhikr.',
        icon: Icons.auto_awesome_outlined,
        state: _RamadanGoalState.pending,
        destination: DhikrScreen(),
        actionLabel: 'Abrir Tasbih',
      );
    }

    if (snapshot.dailyGoalReached) {
      return _RamadanGoalItem(
        title: 'Dhikr',
        description:
            '${snapshot.todayCount}/${snapshot.dailyGoal} repeticiones hoy. Meta diaria cumplida.',
        icon: Icons.auto_awesome_outlined,
        state: _RamadanGoalState.completed,
        destination: const DhikrScreen(),
        actionLabel: 'Seguir',
      );
    }

    if (snapshot.todayCount > 0) {
      return _RamadanGoalItem(
        title: 'Dhikr',
        description:
            '${snapshot.todayCount}/${snapshot.dailyGoal} repeticiones hoy. Ya has empezado.',
        icon: Icons.auto_awesome_outlined,
        state: _RamadanGoalState.inProgress,
        destination: const DhikrScreen(),
        actionLabel: 'Continuar',
      );
    }

    return _RamadanGoalItem(
      title: 'Dhikr',
      description:
          'Tu objetivo de hoy es ${snapshot.dailyGoal}. Unas pocas repeticiones ya suman.',
      icon: Icons.auto_awesome_outlined,
      state: _RamadanGoalState.pending,
      destination: const DhikrScreen(),
      actionLabel: 'Empezar',
    );
  }

  _RamadanGoalItem _buildFastingGoal(
    PrayerSchedule schedule,
    DateTime now,
  ) {
    if (now.isBefore(schedule.maghrib)) {
      return _RamadanGoalItem(
        title: 'Ayuno',
        description: 'Dia de ayuno en curso hasta las ${_formatTime(schedule.maghrib)}.',
        icon: Icons.wb_sunny_outlined,
        state: _RamadanGoalState.inProgress,
      );
    }

    return _RamadanGoalItem(
      title: 'Ayuno',
      description: 'Ya puedes hacer iftar desde las ${_formatTime(schedule.maghrib)}.',
      icon: Icons.nightlight_round,
      state: _RamadanGoalState.completed,
    );
  }

  (Color, String, Color, Color) _goalStyle(
    QiblaTokens tokens,
    _RamadanGoalState state,
  ) {
    switch (state) {
      case _RamadanGoalState.completed:
        return (tokens.accent, 'cumplido', tokens.primaryBg, tokens.primaryBorder);
      case _RamadanGoalState.inProgress:
        return (tokens.primaryLight, 'en progreso', tokens.activeBg, tokens.activeBorder);
      case _RamadanGoalState.pending:
        return (tokens.textMuted, 'pendiente', tokens.bgSurface, tokens.border);
    }
  }

  String _locationDiagnosticTitle(PrayerLocationDiagnostic? diagnostic) {
    if (diagnostic == null) {
      return 'Preparando tus horarios';
    }
    if (!diagnostic.serviceEnabled) {
      return 'Activa la ubicación del dispositivo';
    }
    if (diagnostic.permissionStatus ==
        PrayerLocationPermissionStatus.deniedForever) {
      return 'Permiso de ubicación bloqueado';
    }
    if (diagnostic.permissionStatus == PrayerLocationPermissionStatus.denied) {
      return 'Permite la ubicación para ver tus horarios';
    }
    return 'Preparando tus horarios';
  }

  String _locationDiagnosticBody(PrayerLocationDiagnostic? diagnostic) {
    if (diagnostic == null) {
      return 'La pantalla principal sigue visible aunque los horarios aún no estén listos.';
    }
    if (!diagnostic.serviceEnabled) {
      return 'Sin GPS activo no podemos calcular horarios precisos ni orientar la Qibla.';
    }
    if (diagnostic.permissionStatus ==
        PrayerLocationPermissionStatus.deniedForever) {
      return 'Puedes activar la ubicación para Qibla Time desde los ajustes del sistema cuando quieras.';
    }
    if (diagnostic.permissionStatus == PrayerLocationPermissionStatus.denied) {
      return 'Qibla Time necesita tu ubicación para mostrar horarios fiables según tu ciudad.';
    }
    if (diagnostic.hasCachedLocation) {
      return 'Estamos preparando tus horarios usando la última ubicación guardada.';
    }
    return 'La pantalla principal sigue visible aunque los horarios aún no estén listos.';
  }

  List<Widget> _buildCountdown(QiblaTokens tokens, Duration? remaining) {
    final hours = (remaining?.inHours ?? 0).toString().padLeft(2, '0');
    final minutes =
        ((remaining?.inMinutes ?? 0) % 60).toString().padLeft(2, '0');
    final seconds =
        ((remaining?.inSeconds ?? 0) % 60).toString().padLeft(2, '0');
    final items = [(hours, 'horas'), (minutes, 'min'), (seconds, 'seg')];

    return [
      for (var i = 0; i < items.length; i++) ...[
        Container(
          constraints: const BoxConstraints(minWidth: 54),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.25),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                items[i].$1,
                style: GoogleFonts.dmSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  color: tokens.textPrimary,
                ),
              ),
              Text(
                items[i].$2,
                style: GoogleFonts.dmSans(
                  fontSize: 7,
                  color: tokens.textSecondary,
                ),
              ),
            ],
          ),
        ),
        if (i != items.length - 1)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Text(
              ':',
              style: TextStyle(fontSize: 20, color: tokens.primary),
            ),
          ),
      ],
    ];
  }

  Widget _buildPrayerSection(
    PrayerSchedule? prayerSchedule,
    NextPrayerInfo? nextPrayerInfo,
    List<String> completed,
    DateTime date,
    QiblaTokens tokens,
  ) {
    if (prayerSchedule == null) {
      return _buildPrayerFallback(tokens, null);
    }

    final prayers = [
      (PrayerName.fajr, 'Fajr', 'فجر', prayerSchedule.fajr),
      (PrayerName.dhuhr, 'Dhuhr', 'ظهر', prayerSchedule.dhuhr),
      (PrayerName.asr, 'Asr', 'عصر', prayerSchedule.asr),
      (PrayerName.maghrib, 'Maghrib', 'مغرب', prayerSchedule.maghrib),
      (PrayerName.isha, 'Isha', 'عشاء', prayerSchedule.isha),
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
                          ? 'Oraciones de hoy'
                          : 'Horarios de ${_formatCompactDate(date)}')
                      .toUpperCase(),
                  style: GoogleFonts.dmSans(
                    fontSize: 9,
                    color: tokens.textSecondary,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              Text(
                '${completed.length}/5',
                style: GoogleFonts.dmSans(fontSize: 10, color: tokens.primary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...prayers.map((prayer) {
            final isCurrent = prayer.$1.key == nextPrayerName;
            final isDone = _isPrayerDone(completed, prayer.$1.key);
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: isCurrent ? tokens.activeBg : tokens.bgSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isCurrent ? tokens.activeBorder : tokens.border,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          prayer.$2,
                          style: GoogleFonts.amiri(
                            fontSize: 16,
                            color: tokens.textPrimary,
                          ),
                        ),
                        Text(
                          prayer.$3,
                          style: GoogleFonts.amiri(
                            fontSize: 11,
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
                      fontWeight: FontWeight.w500,
                      color: isCurrent
                          ? tokens.primaryLight
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

  Widget _buildQuickActions(QiblaTokens tokens) {
    final actions = [
      (Icons.auto_stories_outlined, 'Hadices', const HadithLibraryScreen()),
      (Icons.library_books_outlined, 'Libros', const IslamicBooksScreen()),
      (Icons.menu_book_outlined, 'Corán', const QuranScreen()),
      (Icons.calendar_month_outlined, 'Calendario', const CalendarScreen()),
      (Icons.insights_outlined, 'Análisis', const AnalyticsScreen()),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: actions.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 0.95,
        ),
        itemBuilder: (_, index) {
          final action = actions[index];
          return InkWell(
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => action.$3 as Widget),
              );
              ref.invalidate(lastReadingProvider);
              ref.invalidate(dhikrSnapshotProvider);
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                color: tokens.bgSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: tokens.border),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(action.$1, size: 22, color: tokens.primary),
                  const SizedBox(height: 6),
                  Text(
                    action.$2,
                    style: GoogleFonts.dmSans(
                      fontSize: 9,
                      color: tokens.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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

  (String, String) _prayerName(PrayerName prayer) {
    switch (prayer) {
      case PrayerName.fajr:
        return ('Fajr', 'فجر');
      case PrayerName.dhuhr:
        return ('Dhuhr', 'ظهر');
      case PrayerName.asr:
        return ('Asr', 'عصر');
      case PrayerName.maghrib:
        return ('Maghrib', 'مغرب');
      case PrayerName.isha:
        return ('Isha', 'عشاء');
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatCompactDate(DateTime date) {
    const months = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];
    return '${date.day} ${months[date.month - 1]}';
  }

  String _formatHeroDate(DateTime date) {
    const weekdays = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];
    return '${weekdays[date.weekday - 1]} ${date.day}/${date.month}';
  }

  String _formatRemaining(Duration? remaining) {
    if (remaining == null) {
      return 'sin cuenta atrás';
    }
    return 'en ${remaining.inHours}h ${remaining.inMinutes.remainder(60)}min';
  }

  String _formatRamadanCountdown(Duration remaining) {
    final safe = remaining.isNegative ? Duration.zero : remaining;
    final hours = safe.inHours;
    final minutes = safe.inMinutes.remainder(60);
    return '${hours}h ${minutes.toString().padLeft(2, '0')}min';
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
