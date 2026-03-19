import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/services/connectivity_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../hadith/services/hadith_service.dart';
import '../../qibla/screens/qibla_screen.dart';
import '../../dhikr/screens/dhikr_screen.dart';
import '../../support/screens/dua_screen.dart';
import '../../support/screens/settings_screen.dart';
import '../../quran/screens/quran_screen.dart';
import '../../tracking/services/tracking_service.dart';
import '../services/adhan_manager.dart';
import '../services/prayer_service.dart';
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
    final prayerTimesAsync = ref.watch(prayerTimesProvider);
    final countdownAsync = ref.watch(nextPrayerCountdownProvider);
    final tracking = ref.watch(prayerTrackingProvider);
    final bannerAsync = ref.watch(travelBannerProvider);
    final connectivityAsync = ref.watch(connectivityStatusProvider);
    final locationLabelAsync = ref.watch(lastLocationLabelProvider);
    final hadithsAsync = ref.watch(allHadithsProvider);
    final favoritesAsync = ref.watch(hadithFavoritesProvider);
    final streak = ref.read(prayerTrackingProvider.notifier).getStreak();
    final now = DateTime.now();
    final dateKey = '${now.year}-${now.month}-${now.day}';

    return Scaffold(
      backgroundColor: tokens.bgPage,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.refresh(prayerTimesProvider),
          color: tokens.primary,
          backgroundColor: tokens.bgSurface,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _buildHeader(context, tokens, locationLabelAsync.valueOrNull, connectivityAsync.valueOrNull ?? true),
              bannerAsync.when(
                data: (banner) => banner == null ? const SizedBox.shrink() : _buildTravelBanner(tokens, banner),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              _buildCalendarStrip(tokens),
              prayerTimesAsync.when(
                data: (prayerTimes) => _buildHeroSection(
                  prayerTimes,
                  countdownAsync.value,
                  tracking[dateKey] ?? const [],
                  tokens,
                  streak,
                ),
                loading: () => _buildLoadingHero(tokens),
                error: (_, __) => _buildFallbackHero(tokens),
              ),
              _buildHadithSection(tokens, hadithsAsync.valueOrNull, favoritesAsync.valueOrNull ?? const <int>{}),
              prayerTimesAsync.when(
                data: (prayerTimes) => _buildPrayerSection(
                  prayerTimes,
                  tracking[dateKey] ?? const [],
                  dateKey,
                  tokens,
                ),
                loading: () => _buildPrayerSkeleton(tokens),
                error: (_, __) => _buildPrayerFallback(tokens),
              ),
              _buildQuickActions(tokens),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, QiblaTokens tokens, String? locationLabel, bool isOnline) {
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
                  '${isOnline ? '📍' : '📴'} ${locationLabel ?? 'Ubicacion pendiente'}',
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
              child: Text(message, style: GoogleFonts.dmSans(fontSize: 11, color: tokens.textPrimary)),
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
    final dates = List.generate(7, (index) => today.subtract(Duration(days: 3 - index)));

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
              border: Border.all(color: isToday ? tokens.activeBorder : tokens.border),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _weekdays[date.weekday - 1],
                  style: GoogleFonts.dmSans(fontSize: 9, color: tokens.textSecondary),
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
                  style: GoogleFonts.dmSans(fontSize: 7, color: tokens.textMuted),
                  overflow: TextOverflow.ellipsis,
                ),
                if (hasEvent)
                  Container(
                    width: 4,
                    height: 4,
                    margin: const EdgeInsets.only(top: 3),
                    decoration: BoxDecoration(color: tokens.primary, shape: BoxShape.circle),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeroSection(
    PrayerTimes? prayerTimes,
    Duration? remaining,
    List<String> completed,
    QiblaTokens tokens,
    int streak,
  ) {
    if (prayerTimes == null) {
      return _buildFallbackHero(tokens);
    }

    final nextPrayer = prayerTimes.nextPrayer();
    final nextTime = prayerTimes.timeForPrayer(nextPrayer);
    final hero = tokens.getHero(nextPrayer.name.toLowerCase());
    final names = _prayerName(nextPrayer);

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
                  '🔥 $streak dias',
                  style: GoogleFonts.dmSans(fontSize: 10, color: tokens.primaryLight),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${names.$1} · ${names.$2}',
            style: GoogleFonts.amiri(
              fontSize: 32,
              color: tokens.primaryLight,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            nextTime == null
                ? 'Sin hora disponible'
                : 'Hoy a las ${_formatTime(nextTime)} · ${_formatRemaining(remaining)}',
            style: GoogleFonts.dmSans(fontSize: 12, color: tokens.textSecondary),
          ),
          const SizedBox(height: 14),
          Row(
            children: _buildCountdown(tokens, remaining),
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
          Text('Cargando horarios', style: GoogleFonts.dmSans(color: tokens.textPrimary)),
          const SizedBox(height: 8),
          LinearProgressIndicator(color: tokens.primary, backgroundColor: tokens.bgSurface2),
        ],
      ),
    );
  }

  Widget _buildFallbackHero(QiblaTokens tokens) {
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
            'Activa la ubicacion para ver tus horarios',
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: tokens.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'La pantalla principal sigue visible aunque los horarios aun no esten listos.',
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

  List<Widget> _buildCountdown(QiblaTokens tokens, Duration? remaining) {
    final hours = ((remaining?.inHours ?? 0)).toString().padLeft(2, '0');
    final minutes = (((remaining?.inMinutes ?? 0) % 60)).toString().padLeft(2, '0');
    final seconds = (((remaining?.inSeconds ?? 0) % 60)).toString().padLeft(2, '0');
    final items = [(hours, 'horas'), (minutes, 'min'), (seconds, 'seg')];

    return [
      for (int i = 0; i < items.length; i++) ...[
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
                style: GoogleFonts.dmSans(fontSize: 7, color: tokens.textSecondary),
              ),
            ],
          ),
        ),
        if (i != items.length - 1)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Text(':', style: TextStyle(fontSize: 20, color: tokens.primary)),
          ),
      ],
    ];
  }

  Widget _buildPrayerSection(
    PrayerTimes? prayerTimes,
    List<String> completed,
    String dateKey,
    QiblaTokens tokens,
  ) {
    if (prayerTimes == null) {
      return _buildPrayerFallback(tokens);
    }

    final prayers = [
      ('Fajr', 'فجر', prayerTimes.fajr),
      ('Dhuhr', 'ظهر', prayerTimes.dhuhr),
      ('Asr', 'عصر', prayerTimes.asr),
      ('Maghrib', 'مغرب', prayerTimes.maghrib),
      ('Isha', 'عشاء', prayerTimes.isha),
    ];
    final nextPrayerName = prayerTimes.nextPrayer().name.toLowerCase();

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
            final isCurrent = prayer.$1.toLowerCase() == nextPrayerName;
            final isDone = completed.contains(prayer.$1);
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: isCurrent ? tokens.activeBg : tokens.bgSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isCurrent ? tokens.activeBorder : tokens.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(prayer.$1, style: GoogleFonts.amiri(fontSize: 16, color: tokens.textPrimary)),
                        Text(prayer.$2, style: GoogleFonts.amiri(fontSize: 11, color: tokens.textSecondary)),
                      ],
                    ),
                  ),
                  Text(
                    _formatTime(prayer.$3),
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isCurrent ? tokens.primaryLight : tokens.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => ref.read(prayerTrackingProvider.notifier).togglePrayer(DateTime.now(), prayer.$1),
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDone ? tokens.accent : Colors.transparent,
                        border: Border.all(color: isDone ? tokens.accent : tokens.textMuted, width: 1.5),
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

  Widget _buildPrayerFallback(QiblaTokens tokens) {
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
          'Los horarios apareceran aqui cuando tengamos ubicacion.',
          style: GoogleFonts.dmSans(fontSize: 12, color: tokens.textSecondary),
        ),
      ),
    );
  }

  Widget _buildHadithSection(QiblaTokens tokens, List<dynamic>? hadiths, Set<int> favorites) {
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
                    style: GoogleFonts.dmSans(fontSize: 9, color: tokens.textSecondary, letterSpacing: 1.4),
                  ),
                ),
                Text(hadith.grade, style: GoogleFonts.dmSans(fontSize: 10, color: tokens.primary)),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              hadith.arabic,
              textAlign: TextAlign.right,
              style: GoogleFonts.amiri(fontSize: 19, height: 1.8, color: tokens.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              hadith.translation,
              style: GoogleFonts.dmSans(fontSize: 12, height: 1.6, color: tokens.textPrimary),
              maxLines: _hadithExpanded ? null : 3,
              overflow: _hadithExpanded ? null : TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              '${hadith.reference} · ${hadith.category}',
              style: GoogleFonts.dmSans(fontSize: 10, color: tokens.textSecondary),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                TextButton(
                  onPressed: () => setState(() => _hadithExpanded = !_hadithExpanded),
                  child: Text(_hadithExpanded ? 'Ver menos' : 'Ver mas'),
                ),
                TextButton(
                  onPressed: () async {
                    await Share.share('${hadith.translation}\n\n${hadith.reference}');
                  },
                  child: const Text('Compartir'),
                ),
                TextButton(
                  onPressed: () async {
                    await ref.read(hadithServiceProvider).toggleFavorite(hadith.id);
                    ref.invalidate(hadithFavoritesProvider);
                  },
                  child: Text(isFavorite ? 'Favorito' : 'Guardar'),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Siguiente',
                  onPressed: () => setState(() => _hadithOffset = (_hadithOffset + 1) % hadiths.length),
                  icon: Icon(Icons.arrow_forward, color: tokens.primary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(QiblaTokens tokens) {
    final actions = [
      ('🧭', 'Qibla', const QiblaScreen()),
      ('📿', 'Tasbih', const DhikrScreen()),
      ('🤲', 'Dua', const DuasScreen()),
      ('⚙️', 'Ajustes', const SettingsScreen()),
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
                    style: GoogleFonts.dmSans(fontSize: 9, color: tokens.textSecondary),
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

  (String, String) _prayerName(Prayer prayer) {
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

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatRemaining(Duration? remaining) {
    if (remaining == null) return 'sin cuenta atras';
    return 'en ${remaining.inHours}h ${remaining.inMinutes.remainder(60)}min';
  }
}
