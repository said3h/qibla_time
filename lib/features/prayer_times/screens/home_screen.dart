import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../tracking/services/tracking_service.dart';
import '../services/adhan_manager.dart';
import '../services/prayer_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
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
    final prayerTimesAsync = ref.watch(prayerTimesProvider);
    final countdownAsync = ref.watch(nextPrayerCountdownProvider);
    final tracking = ref.watch(prayerTrackingProvider);
    final streak = ref.read(prayerTrackingProvider.notifier).getStreak();
    final now = DateTime.now();
    final dateKey = '${now.year}-${now.month}-${now.day}';

    return Scaffold(
      backgroundColor: tokens.bgPage,
      body: SafeArea(
        child: prayerTimesAsync.when(
          data: (prayerTimes) {
            if (prayerTimes == null) {
              return _buildLocationError(tokens);
            }

            final remaining = countdownAsync.value;

            return RefreshIndicator(
              onRefresh: () async => ref.refresh(prayerTimesProvider),
              color: tokens.primary,
              backgroundColor: tokens.bgSurface,
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildHeader(tokens),
                  _buildCalendarStrip(tokens),
                  _buildNextPrayerCard(prayerTimes, remaining, tokens, streak),
                  _buildPrayerList(prayerTimes, tracking, dateKey, tokens),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
          loading: () => Center(
            child: CircularProgressIndicator(color: tokens.primary),
          ),
          error: (error, _) => Center(
            child: Text(
              'Error: $error',
              style: GoogleFonts.dmSans(color: tokens.textPrimary),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(QiblaTokens tokens) {
    final now = DateTime.now();
    final hijri = HijriCalendar.fromDate(now);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'QiblaTime',
                  style: GoogleFonts.amiri(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: tokens.primary,
                  ),
                ),
                Text(
                  'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيم',
                  style: GoogleFonts.amiri(
                    fontSize: 13,
                    color: tokens.textSecondary,
                    height: 1.7,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                DateFormat('EEE, d MMM yyyy', 'es').format(now),
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: tokens.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: tokens.primaryBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: tokens.primaryBorder),
                ),
                child: Text(
                  '${hijri.hDay} ${hijri.getShortMonthName()} ${hijri.hYear}',
                  style: GoogleFonts.amiri(
                    fontSize: 13,
                    color: tokens.primaryLight,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarStrip(QiblaTokens tokens) {
    final today = DateTime.now();
    final dates = List.generate(6, (index) => today.subtract(Duration(days: 3 - index)));

    return SizedBox(
      height: 76,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final date = dates[index];
          final hijri = HijriCalendar.fromDate(date);
          final isToday = _isSameDay(date, today);

          return Container(
            width: 54,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              color: isToday ? tokens.primaryBg : tokens.bgSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isToday ? tokens.primaryBorder : tokens.border,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat('EEE', 'es').format(date),
                  style: GoogleFonts.dmSans(
                    fontSize: 9,
                    color: tokens.textSecondary,
                  ),
                ),
                Text(
                  '${date.day}',
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: tokens.textPrimary,
                  ),
                ),
                Text(
                  '${hijri.hDay} ${hijri.getShortMonthName()}',
                  style: GoogleFonts.dmSans(
                    fontSize: 8,
                    color: tokens.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemCount: dates.length,
      ),
    );
  }

  Widget _buildNextPrayerCard(
    PrayerTimes prayerTimes,
    Duration? remaining,
    QiblaTokens tokens,
    int streak,
  ) {
    final nextPrayer = prayerTimes.nextPrayer();
    final nextTime = prayerTimes.timeForPrayer(nextPrayer);
    final hero = tokens.getHero(nextPrayer.name.toLowerCase());
    final prayerName = _displayName(nextPrayer);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: hero.bg,
        borderRadius: BorderRadius.circular(22),
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
          Text(
            'PROXIMA ORACION',
            style: GoogleFonts.dmSans(
              fontSize: 9,
              letterSpacing: 1.5,
              color: hero.label,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${prayerName.$1} · ${prayerName.$2}',
            style: GoogleFonts.amiri(
              fontSize: 28,
              color: tokens.primaryLight,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            nextTime == null
                ? '--:--'
                : '${DateFormat('HH:mm').format(nextTime)} · ${_formatRemainingText(remaining)}',
            style: GoogleFonts.dmSans(
              fontSize: 12,
              color: tokens.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: _buildCountdownBlocks(remaining, tokens),
          ),
          if (streak > 0) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: tokens.primaryBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: tokens.primaryBorder),
              ),
              child: Text(
                '🔥 $streak dias seguidos',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: tokens.primaryLight,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildCountdownBlocks(Duration? remaining, QiblaTokens tokens) {
    final totalSeconds = remaining?.inSeconds ?? 0;
    final hours = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    final values = [
      (hours, 'horas'),
      (minutes, 'min'),
      (seconds, 'seg'),
    ];

    return values
        .map(
          (item) => Expanded(
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    item.$1,
                    style: GoogleFonts.dmSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: tokens.textPrimary,
                    ),
                  ),
                  Text(
                    item.$2,
                    style: GoogleFonts.dmSans(
                      fontSize: 8,
                      color: tokens.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
        .toList();
  }

  Widget _buildPrayerList(
    PrayerTimes prayerTimes,
    Map<String, List<String>> tracking,
    String dateKey,
    QiblaTokens tokens,
  ) {
    final prayers = [
      ('Fajr', 'فجر', prayerTimes.fajr),
      ('Dhuhr', 'ظهر', prayerTimes.dhuhr),
      ('Asr', 'عصر', prayerTimes.asr),
      ('Maghrib', 'مغرب', prayerTimes.maghrib),
      ('Isha', 'عشاء', prayerTimes.isha),
    ];
    final nextPrayer = prayerTimes.nextPrayer().name.toLowerCase();
    final completed = tracking[dateKey] ?? <String>[];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ORACIONES DE HOY',
            style: GoogleFonts.dmSans(
              fontSize: 10,
              letterSpacing: 1.5,
              color: tokens.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          ...prayers.map((prayer) {
            final isCurrent = prayer.$1.toLowerCase() == nextPrayer;
            final isDone = completed.contains(prayer.$1);

            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                          prayer.$1,
                          style: GoogleFonts.amiri(
                            fontSize: 18,
                            color: tokens.textPrimary,
                          ),
                        ),
                        Text(
                          prayer.$2,
                          style: GoogleFonts.amiri(
                            fontSize: 13,
                            color: tokens.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    DateFormat('HH:mm').format(prayer.$3),
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isCurrent ? tokens.primaryLight : tokens.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => ref
                        .read(prayerTrackingProvider.notifier)
                        .togglePrayer(DateTime.now(), prayer.$1),
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDone ? tokens.accent : Colors.transparent,
                        border: Border.all(
                          color: isDone ? tokens.accent : tokens.textSecondary,
                          width: 1.5,
                        ),
                      ),
                      child: isDone
                          ? Icon(Icons.check, size: 14, color: tokens.bgPage)
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

  Widget _buildLocationError(QiblaTokens tokens) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off_rounded, size: 72, color: tokens.textMuted),
            const SizedBox(height: 20),
            Text(
              'Ubicacion requerida',
              style: GoogleFonts.dmSans(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: tokens.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'QiblaTime necesita tu ubicacion para calcular horarios de oracion y Qibla.',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: tokens.textSecondary,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  (String, String) _displayName(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr:
        return ('Fajr', 'فجر');
      case Prayer.dhuhr:
        return ('Dhuhr', 'ظهر');
      case Prayer.asr:
        return ('Asr', 'عصر');
      case Prayer.maghrib:
        return ('Maghrib', 'مغرب');
      case Prayer.isha:
        return ('Isha', 'عشاء');
      default:
        return ('Fajr', 'فجر');
    }
  }

  String _formatRemainingText(Duration? remaining) {
    if (remaining == null) return 'Sin cuenta atras';
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes.remainder(60);
    return 'En ${hours}h ${minutes}min';
  }
}
