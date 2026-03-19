import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hijri/hijri.dart';
import '../services/prayer_service.dart';
import '../services/adhan_manager.dart';
import '../widgets/calendar_strip.dart';
import '../widgets/prayer_hero_card.dart';
import 'home_header.dart';
import '../../../core/theme/app_theme.dart';
import '../../tracking/services/tracking_service.dart';
import '../../focus/screens/focus_mode_screen.dart';
import '../../dhikr/screens/dhikr_screen.dart';
import '../../support/screens/dua_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Programar adhans cuando se carga la pantalla
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
    
    // Calcular streak
    final streak = ref.read(prayerTrackingProvider.notifier).getStreak();

    return Scaffold(
      backgroundColor: tokens.bgPage,
      body: prayerTimesAsync.when(
        data: (prayerTimes) {
          if (prayerTimes == null) {
            return _buildLocationError(tokens);
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.refresh(prayerTimesProvider);
            },
            color: tokens.primary,
            backgroundColor: tokens.bgSurface,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Header con Bismillah
                HomeHeader(
                  currentDate: DateTime.now(),
                  hijriDate: _getHijriDate(),
                ),
                
                // Calendar Strip
                const CalendarStrip(selectedDate: null, onDateSelected: null),
                
                // Prayer Hero Card
                PrayerHeroCard(
                  prayerTimes: prayerTimes,
                  streak: streak,
                ),
                
                // Lista de oraciones
                _buildPrayerList(prayerTimes, tracking, dateKey, tokens),
                
                const SizedBox(height: 24),
                
                // Acciones rápidas
                _buildQuickActions(tokens),
                
                const SizedBox(height: 24),
              ],
            ),
          );
        },
        loading: () => Center(
          child: CircularProgressIndicator(color: tokens.primary),
        ),
        error: (error, stack) => Center(
          child: Text('Error: $error', style: TextStyle(color: tokens.textPrimary)),
        ),
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
              onPressed: () => Geolocator.openAppSettings(),
              icon: const Icon(Icons.settings),
              label: const Text('Abrir Configuración'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrayerList(prayerTimes, tracking, String dateKey, QiblaTokens tokens) {
    final prayers = [
      {'name': 'Fajr', 'arabic': 'فجر', 'time': prayerTimes.fajr},
      {'name': 'Dhuhr', 'arabic': 'ظهر', 'time': prayerTimes.dhuhr},
      {'name': 'Asr', 'arabic': 'عصر', 'time': prayerTimes.asr},
      {'name': 'Maghrib', 'arabic': 'مغرب', 'time': prayerTimes.maghrib},
      {'name': 'Isha', 'arabic': 'عشاء', 'time': prayerTimes.isha},
    ];

    final nextPrayer = prayerTimes.nextPrayer();
    final isDone = tracking[dateKey] ?? [];

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
          ...prayers.map((prayer) => _buildPrayerItem(
            prayer['name'] as String,
            prayer['arabic'] as String,
            prayer['time'] as DateTime,
            nextPrayer.name.toLowerCase() == prayer['name'].toLowerCase(),
            isDone.contains(prayer['name']),
            tokens,
          )),
        ],
      ),
    );
  }

  Widget _buildPrayerItem(
    String name,
    String arabic,
    DateTime time,
    bool isNext,
    bool isDone,
    QiblaTokens tokens,
  ) {
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
          // Checkbox
          GestureDetector(
            onTap: () {
              ref.read(prayerTrackingProvider.notifier).togglePrayer(DateTime.now(), name);
            },
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isDone ? tokens.accent : tokens.bgSurface2,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDone ? tokens.accent : tokens.borderMed,
                  width: 2,
                ),
              ),
              child: isDone
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 16),
          
          // Nombre y árabe
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.amiri(
                    fontSize: 18,
                    fontWeight: isNext ? FontWeight.bold : FontWeight.w500,
                    color: isNext ? tokens.primaryLight : tokens.textPrimary,
                  ),
                ),
                Text(
                  arabic,
                  style: GoogleFonts.amiri(
                    fontSize: 14,
                    color: tokens.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          
          // Tiempo e icono
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatTime(time),
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
  }

  Widget _buildQuickActions(QiblaTokens tokens) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildQuickActionButton(
            icon: Icons.auto_stories,
            label: 'Duas',
            color: tokens.primary,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DuaScreen())),
          ),
          const SizedBox(width: 12),
          _buildQuickActionButton(
            icon: Icons.fingerprint,
            label: 'Tasbih',
            color: tokens.accent,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DhikrScreen())),
          ),
          const SizedBox(width: 12),
          _buildQuickActionButton(
            icon: Icons.center_focus_strong,
            label: 'Focus',
            color: tokens.danger,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FocusModeScreen())),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final tokens = QiblaThemes.current;
    
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getHijriDate() {
    final hijri = HijriCalendar.now();
    hijri.toLocal();
    return '${hijri.iDay} ${hijri.iMonthShort} ${hijri.iYear}';
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
