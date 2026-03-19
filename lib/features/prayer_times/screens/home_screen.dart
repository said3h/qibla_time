// Home Screen simplificado - Versión funcional
// Nota: Los widgets complejos (HomeHeader, CalendarStrip, PrayerHeroCard) 
// se implementarán en una siguiente iteración

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:adhan/adhan.dart';
import '../services/prayer_service.dart';
import '../services/adhan_manager.dart';
import '../../../core/theme/app_theme.dart';
import '../../tracking/services/tracking_service.dart';

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
    final tracking = ref.watch(prayerTrackingProvider);
    final dateKey = "${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}";
    final streak = ref.read(prayerTrackingProvider.notifier).getStreak();

    return Scaffold(
      backgroundColor: tokens.bgPage,
      body: prayerTimesAsync.when(
        data: (prayerTimes) {
          if (prayerTimes == null) {
            return _buildLocationError(tokens);
          }

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(prayerTimesProvider),
            color: tokens.primary,
            backgroundColor: tokens.bgSurface,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Header simple
                _buildHeader(tokens),
                
                // Próxima oración (simplificado)
                _buildNextPrayerCard(prayerTimes, tokens, streak),
                
                // Lista de oraciones
                _buildPrayerList(prayerTimes, tracking, dateKey, tokens),
                
                const SizedBox(height: 24),
              ],
            ),
          );
        },
        loading: () => Center(child: CircularProgressIndicator(color: tokens.primary)),
        error: (error, stack) => Center(child: Text('Error: $error', style: TextStyle(color: tokens.textPrimary))),
      ),
    );
  }

  Widget _buildHeader(QiblaTokens tokens) {
    final now = DateTime.now();
    final hijri = DateTime.now();
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
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
              const SizedBox(height: 4),
              Text(
                'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيم',
                style: GoogleFonts.amiri(
                  fontSize: 14,
                  color: tokens.textSecondary,
                  height: 1.8,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${now.day}/${now.month}/${now.year}',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: tokens.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: tokens.primaryBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: tokens.primaryBorder),
                ),
                child: Text(
                  '${hijri.iDay} ${hijri.iMonthShort} ${hijri.iYear}',
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

  Widget _buildNextPrayerCard(PrayerTimes prayerTimes, QiblaTokens tokens, int streak) {
    final nextPrayer = prayerTimes.nextPrayer();
    final nextTime = prayerTimes.timeForPrayer(nextPrayer);
    final hero = tokens.getHero(nextPrayer.name.toLowerCase());

    String nextName = nextPrayer.name.toUpperCase();
    if (nextName == "NONE" || nextName == "INVALID") nextName = "FAJR";

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [hero.bg, hero.tint],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tokens.primaryBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PRÓXIMA ORACIÓN',
            style: GoogleFonts.dmSans(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: hero.label.withOpacity(0.8),
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            nextName,
            style: GoogleFonts.amiri(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: tokens.primaryLight,
            ),
          ),
          if (nextTime != null)
            Text(
              '${nextTime.hour.toString().padLeft(2, '0')}:${nextTime.minute.toString().padLeft(2, '0')}',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: hero.label,
              ),
            ),
          const SizedBox(height: 14),
          if (streak > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: tokens.activeBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: tokens.primaryBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.local_fire_department, color: Colors.orange, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    '$streak DÍAS',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: tokens.primaryLight,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPrayerList(PrayerTimes prayerTimes, Map<String, List<String>> tracking, String dateKey, QiblaTokens tokens) {
    final prayers = [
      {'name': 'Fajr', 'arabic': 'فجر', 'time': prayerTimes.fajr},
      {'name': 'Dhuhr', 'arabic': 'ظهر', 'time': prayerTimes.dhuhr},
      {'name': 'Asr', 'arabic': 'عصر', 'time': prayerTimes.asr},
      {'name': 'Maghrib', 'arabic': 'مغرب', 'time': prayerTimes.maghrib},
      {'name': 'Isha', 'arabic': 'عشاء', 'time': prayerTimes.isha},
    ];

    final nextPrayer = prayerTimes.nextPrayer();
    final isDone = tracking[dateKey] ?? [];
    final currentPrayerName = nextPrayer.name.toLowerCase();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Oraciones de hoy',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: tokens.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...prayers.map((prayer) {
            final prayerName = prayer['name'] as String;
            final isNext = currentPrayerName == prayerName.toLowerCase();
            final isCompleted = isDone.contains(prayerName);
            
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isNext ? tokens.activeBg : tokens.bgSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isNext ? tokens.activeBorder : tokens.border,
                  width: isNext ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => ref.read(prayerTrackingProvider.notifier).togglePrayer(DateTime.now(), prayerName),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isCompleted ? tokens.accent : tokens.bgSurface2,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isCompleted ? tokens.accent : tokens.borderMed,
                          width: 2,
                        ),
                      ),
                      child: isCompleted ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          prayerName,
                          style: GoogleFonts.amiri(
                            fontSize: 18,
                            fontWeight: isNext ? FontWeight.bold : FontWeight.w500,
                            color: isNext ? tokens.primaryLight : tokens.textPrimary,
                          ),
                        ),
                        Text(
                          prayer['arabic'] as String,
                          style: GoogleFonts.amiri(
                            fontSize: 14,
                            color: tokens.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(prayer['time'] as DateTime).hour.toString().padLeft(2, '0')}:${(prayer['time'] as DateTime).minute.toString().padLeft(2, '0')}',
                        style: GoogleFonts.dmSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isNext ? tokens.primaryLight : tokens.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        isNext ? Icons.notifications_active : Icons.notifications_none,
                        size: 20,
                        color: isNext ? tokens.primary : tokens.textMuted,
                      ),
                    ],
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
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off_rounded, size: 80, color: tokens.textMuted),
            const SizedBox(height: 24),
            Text(
              'Ubicación Requerida',
              style: GoogleFonts.dmSans(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: tokens.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'QiblaTime necesita tu ubicación para calcular los horarios de oración.',
              style: GoogleFonts.dmSans(
                color: tokens.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {}, // Geolocator.openAppSettings() - importar si se necesita
              icon: const Icon(Icons.settings),
              label: const Text('Abrir Configuración'),
            ),
          ],
        ),
      ),
    );
  }
}

