import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/services/connectivity_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../calendar/screens/calendar_screen.dart';
import '../../dhikr/screens/dhikr_screen.dart';
import '../../focus/screens/focus_mode_screen.dart';
import '../../hadith/services/hadith_service.dart';
import '../../qibla/screens/qibla_screen.dart';
import '../../quran/screens/quran_screen.dart';
import '../../support/screens/dua_screen.dart';
import '../../support/screens/settings_screen.dart';
import '../../tracking/models/tracking_models.dart';
import '../../tracking/screens/analytics_screen.dart';
import '../../tracking/services/tracking_service.dart';
import '../domain/entities/next_prayer_info.dart';
import '../domain/entities/prayer_name.dart';
import '../domain/entities/prayer_location_diagnostic.dart';
import '../domain/entities/prayer_schedule.dart';
import '../domain/entities/resolved_prayer_schedule.dart';
import '../presentation/providers/prayer_times_providers.dart';
import '../services/adhan_manager.dart';
import '../services/travel_mode_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const _weekdays = ['Lun', 'Mar', 'Mie', 'Jue', 'Vie', 'Sab', 'Dom'];

  bool _hadithExpanded = false;
  int _hadithOffset = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adhanManagerProvider).scheduleTodayAdhans();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;
    final prayerScheduleAsync = ref.watch(prayerScheduleProvider);
    final nextPrayerInfo = ref.watch(nextPrayerInfoProvider);
    final countdownAsync = ref.watch(prayerCountdownProvider);
    final bannerAsync = ref.watch(travelBannerProvider);
    final connectivityAsync = ref.watch(connectivityStatusProvider);
    final locationLabelAsync = ref.watch(lastLocationLabelProvider);
    final locationDiagnosticAsync = ref.watch(prayerLocationDiagnosticProvider);
    final systemNotificationPermissionAsync =
        ref.watch(systemNotificationPermissionProvider);
    final prayerNotificationsEnabledAsync =
        ref.watch(prayerNotificationsEnabledProvider);
    final hadithsAsync = ref.watch(allHadithsProvider);
    final favoritesAsync = ref.watch(hadithFavoritesProvider);
    final tracking = ref.watch(prayerTrackingProvider);
    final streak = tracking.currentStreak;
    final now = DateTime.now();
    final completedPrayers = tracking.completedPrayersFor(now);
    final weeklySummary = tracking.currentWeekSummary;

    return Scaffold(
      backgroundColor: tokens.bgPage,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.refresh(prayerScheduleProvider),
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
              bannerAsync.when(
                data: (banner) => banner == null
                    ? const SizedBox.shrink()
                    : _buildTravelBanner(tokens, banner),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              _buildCalendarStrip(tokens),
              prayerScheduleAsync.when(
                data: (resolvedSchedule) => _buildHeroSection(
                  resolvedSchedule,
                  nextPrayerInfo,
                  countdownAsync.value,
                  tokens,
                  streak,
                  locationDiagnosticAsync.valueOrNull,
                ),
                loading: () => _buildLoadingHero(tokens),
                error: (_, __) => _buildFallbackHero(
                  tokens,
                  locationDiagnosticAsync.valueOrNull,
                ),
              ),
              _buildDailyProgressCard(
                tokens,
                prayerScheduleAsync.valueOrNull,
                nextPrayerInfo,
                completedPrayers,
                streak,
              ),
              _buildNotificationStatusCard(
                tokens,
                systemNotificationPermissionAsync.valueOrNull,
                prayerNotificationsEnabledAsync.valueOrNull,
              ),
              _buildWeeklySummaryCard(tokens, weeklySummary),
              _buildHadithSection(
                tokens,
                hadithsAsync.valueOrNull,
                favoritesAsync.valueOrNull ?? const <int>{},
              ),
              prayerScheduleAsync.when(
                data: (resolvedSchedule) => _buildPrayerSection(
                  resolvedSchedule?.schedule,
                  nextPrayerInfo,
                  completedPrayers,
                  now,
                  tokens,
                ),
                loading: () => _buildPrayerSkeleton(tokens),
                error: (_, __) => _buildPrayerFallback(
                  tokens,
                  locationDiagnosticAsync.valueOrNull,
                ),
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
                  'QiblaTime',
                  style: GoogleFonts.amiri(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: tokens.primary,
                  ),
                ),
                Text(
                  '${isOnline ? 'En linea' : 'Sin red'} · ${locationLabel ?? 'Ubicacion pendiente'}',
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
              tooltip: 'Coran',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const QuranScreen()),
                );
              },
              icon: Icon(Icons.menu_book, size: 17, color: tokens.textPrimary),
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
    final today = DateTime.now();
    final dates =
        List.generate(7, (index) => today.subtract(Duration(days: 3 - index)));

    return SizedBox(
      height: 68,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: dates.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, index) {
          final date = dates[index];
          final hijri = HijriCalendar.fromDate(date);
          final isToday = _isSameDay(date, today);
          final hasEvent = index == 3 || index == 4;

          return Container(
            width: 46,
            padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
            decoration: BoxDecoration(
              color: isToday ? tokens.primaryBg : tokens.bgSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isToday ? tokens.activeBorder : tokens.border,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _weekdays[date.weekday - 1],
                  style: GoogleFonts.dmSans(
                    fontSize: 9,
                    color: tokens.textSecondary,
                  ),
                ),
                Text(
                  '${date.day}',
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: tokens.textPrimary,
                  ),
                ),
                Text(
                  '${hijri.hDay} ${hijri.getShortMonthName()}',
                  style: GoogleFonts.dmSans(
                    fontSize: 7,
                    color: tokens.textMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (hasEvent)
                  Container(
                    width: 4,
                    height: 4,
                    margin: const EdgeInsets.only(top: 3),
                    decoration: BoxDecoration(
                      color: tokens.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
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
  ) {
    final prayerSchedule = resolvedSchedule?.schedule;
    if (prayerSchedule == null || nextPrayerInfo == null) {
      return _buildFallbackHero(tokens, locationDiagnostic);
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
                  'Proxima oracion'.toUpperCase(),
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
                  '$streak dias seguidos',
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
            '${names.$1} Â· ${names.$2}',
            style: GoogleFonts.amiri(
              fontSize: 32,
              color: tokens.primaryLight,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Hoy a las ${_formatTime(nextPrayerInfo.time)} · ${_formatRemaining(remaining)}',
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
                'Usando tu ultima ubicacion guardada',
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

  Widget _buildDailyProgressCard(
    QiblaTokens tokens,
    ResolvedPrayerSchedule? resolvedSchedule,
    NextPrayerInfo? nextPrayerInfo,
    List<String> completedPrayers,
    int streak,
  ) {
    final completedCount = completedPrayers.length;
    final progress = completedCount / 5;
    final remainingPrayers = resolvedSchedule?.schedule.times.keys
            .where((prayer) => !completedPrayers.contains(prayer.key))
            .toList() ??
        const <PrayerName>[];

    String message;
    if (completedCount == 5) {
      message = 'Dia completo. Mantienes tu ritmo con $streak dias seguidos.';
    } else if (nextPrayerInfo != null &&
        !completedPrayers.contains(nextPrayerInfo.prayer.key)) {
      message =
          'Siguiente foco: ${nextPrayerInfo.prayer.displayName} a las ${_formatTime(nextPrayerInfo.time)}.';
    } else if (remainingPrayers.isNotEmpty) {
      message = 'Te faltan ${remainingPrayers.length} oraciones hoy.';
    } else {
      message = 'En cuanto tengamos horarios, veras aqui tu progreso de hoy.';
    }

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
                    'PROGRESO DE HOY',
                    style: GoogleFonts.dmSans(
                      fontSize: 9,
                      color: tokens.textSecondary,
                      letterSpacing: 1.4,
                    ),
                  ),
                ),
                Text(
                  '$completedCount/5',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: tokens.primaryLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                height: 1.5,
                color: tokens.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                color: tokens.primary,
                backgroundColor: tokens.bgSurface2,
              ),
            ),
            if (remainingPrayers.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: remainingPrayers
                    .map(
                      (prayer) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: tokens.primaryBg,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: tokens.primaryBorder),
                        ),
                        child: Text(
                          prayer.displayName,
                          style: GoogleFonts.dmSans(
                            fontSize: 10,
                            color: tokens.textPrimary,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
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
        : 'Los avisos generales de oracion estan pausados ahora mismo.';

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
                Expanded(child: _summaryMetric(tokens, '${summary.fullDays}', 'dias 5/5')),
                Expanded(child: _summaryMetric(tokens, '${summary.currentStreak}', 'racha actual')),
                Expanded(
                  child: _summaryMetric(
                    tokens,
                    summary.strongestDay.shortLabel,
                    '${summary.strongestDay.completed}/5 mejor dia',
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

  String _locationDiagnosticTitle(PrayerLocationDiagnostic? diagnostic) {
    if (diagnostic == null) {
      return 'Preparando tus horarios';
    }
    if (!diagnostic.serviceEnabled) {
      return 'Activa la ubicacion del dispositivo';
    }
    if (diagnostic.permissionStatus ==
        PrayerLocationPermissionStatus.deniedForever) {
      return 'Permiso de ubicacion bloqueado';
    }
    if (diagnostic.permissionStatus == PrayerLocationPermissionStatus.denied) {
      return 'Permite la ubicacion para ver tus horarios';
    }
    return 'Preparando tus horarios';
  }

  String _locationDiagnosticBody(PrayerLocationDiagnostic? diagnostic) {
    if (diagnostic == null) {
      return 'La pantalla principal sigue visible aunque los horarios aun no esten listos.';
    }
    if (!diagnostic.serviceEnabled) {
      return 'Sin GPS activo no podemos calcular horarios precisos ni orientar la Qibla.';
    }
    if (diagnostic.permissionStatus ==
        PrayerLocationPermissionStatus.deniedForever) {
      return 'Puedes activar la ubicacion para QiblaTime desde Ajustes del sistema cuando quieras.';
    }
    if (diagnostic.permissionStatus == PrayerLocationPermissionStatus.denied) {
      return 'QiblaTime necesita tu ubicacion para mostrar horarios fiables segun tu ciudad.';
    }
    if (diagnostic.hasCachedLocation) {
      return 'Estamos preparando tus horarios usando la ultima ubicacion guardada.';
    }
    return 'La pantalla principal sigue visible aunque los horarios aun no esten listos.';
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
      (PrayerName.fajr, 'Fajr', 'ÙØ¬Ø±', prayerSchedule.fajr),
      (PrayerName.dhuhr, 'Dhuhr', 'Ø¸Ù‡Ø±', prayerSchedule.dhuhr),
      (PrayerName.asr, 'Asr', 'Ø¹ØµØ±', prayerSchedule.asr),
      (PrayerName.maghrib, 'Maghrib', 'Ù…ØºØ±Ø¨', prayerSchedule.maghrib),
      (PrayerName.isha, 'Isha', 'Ø¹Ø´Ø§Ø¡', prayerSchedule.isha),
    ];
    final nextPrayerName = nextPrayerInfo?.prayer.key;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Oraciones de hoy'.toUpperCase(),
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

  Widget _buildHadithSection(
    QiblaTokens tokens,
    List<dynamic>? hadiths,
    Set<int> favorites,
  ) {
    if (hadiths == null || hadiths.isEmpty) {
      return const SizedBox.shrink();
    }

    final hadith = hadiths[_hadithOffset % hadiths.length];
    final isFavorite = favorites.contains(hadith.id);

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
                    'HADITH DIARIO',
                    style: GoogleFonts.dmSans(
                      fontSize: 9,
                      color: tokens.textSecondary,
                      letterSpacing: 1.4,
                    ),
                  ),
                ),
                Text(
                  hadith.grade,
                  style: GoogleFonts.dmSans(fontSize: 10, color: tokens.primary),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              hadith.arabic,
              textAlign: TextAlign.right,
              style: GoogleFonts.amiri(
                fontSize: 19,
                height: 1.8,
                color: tokens.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hadith.translation,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                height: 1.6,
                color: tokens.textPrimary,
              ),
              maxLines: _hadithExpanded ? null : 3,
              overflow: _hadithExpanded ? null : TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              '${hadith.reference} Â· ${hadith.category}',
              style: GoogleFonts.dmSans(
                fontSize: 10,
                color: tokens.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                TextButton(
                  onPressed: () =>
                      setState(() => _hadithExpanded = !_hadithExpanded),
                  child: Text(_hadithExpanded ? 'Ver menos' : 'Ver mas'),
                ),
                TextButton(
                  onPressed: () async {
                    await Share.share(
                      '${hadith.translation}\n\n${hadith.reference}',
                    );
                  },
                  child: const Text('Compartir'),
                ),
                TextButton(
                  onPressed: () async {
                    await ref
                        .read(hadithServiceProvider)
                        .toggleFavorite(hadith.id);
                    ref.invalidate(hadithFavoritesProvider);
                  },
                  child: Text(isFavorite ? 'Favorito' : 'Guardar'),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Siguiente',
                  onPressed: () => setState(
                    () => _hadithOffset = (_hadithOffset + 1) % hadiths.length,
                  ),
                  icon: Icon(Icons.arrow_forward, color: tokens.primary),
                ),
              ],
            ),
            if (favorites.isEmpty)
              Text(
                'Todavia no has guardado hadiths favoritos.',
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  color: tokens.textMuted,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(QiblaTokens tokens) {
    final actions = [
      ('ðŸ§­', 'Qibla', const QiblaScreen()),
      ('ðŸ“…', 'Calendario', const CalendarScreen()),
      ('ðŸ“¿', 'Tasbih', const DhikrScreen()),
      ('ðŸ›', 'Focus', const FocusModeScreen()),
      ('ðŸ“Š', 'Stats', const AnalyticsScreen()),
      ('ðŸ¤²', 'Dua', const DuasScreen()),
      ('âš™ï¸', 'Ajustes', const SettingsScreen()),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
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
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => action.$3 as Widget),
              );
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
                  Text(action.$1, style: const TextStyle(fontSize: 22)),
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

  bool _isPrayerDone(List<String> completed, String prayerName) {
    return completed.contains(prayerName.toLowerCase());
  }

  (String, String) _prayerName(PrayerName prayer) {
    switch (prayer) {
      case PrayerName.fajr:
        return ('Fajr', 'ÙØ¬Ø±');
      case PrayerName.dhuhr:
        return ('Dhuhr', 'Ø¸Ù‡Ø±');
      case PrayerName.asr:
        return ('Asr', 'Ø¹ØµØ±');
      case PrayerName.maghrib:
        return ('Maghrib', 'Ù…ØºØ±Ø¨');
      case PrayerName.isha:
        return ('Isha', 'Ø¹Ø´Ø§Ø¡');
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatRemaining(Duration? remaining) {
    if (remaining == null) {
      return 'sin cuenta atras';
    }
    return 'en ${remaining.inHours}h ${remaining.inMinutes.remainder(60)}min';
  }
}
