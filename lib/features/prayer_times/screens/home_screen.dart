import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:adhan/adhan.dart';
import '../services/prayer_service.dart';
import '../services/quran_service.dart';
import '../../tracking/services/tracking_service.dart';
import '../../../core/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import '../../support/screens/settings_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prayerTimesAsyncValue = ref.watch(prayerTimesProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: const Text('QiblaTime', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined),
            tooltip: 'Nearby Mosques',
            onPressed: () async {
              final url = Uri.parse('https://www.google.com/maps/search/mosque+near+me');
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
            },
          ),
        ],
      ),
      body: prayerTimesAsyncValue.when(
        data: (prayerTimes) {
          if (prayerTimes == null) {
            return _buildLocationError();
          }
          return _buildPrayerTimesView(context, ref, prayerTimes);
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildLocationError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_off_rounded, size: 80, color: AppTheme.textLight),
            const SizedBox(height: 24),
            const Text(
              'Location Required',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'QiblaTime needs your location to calculate precise prayer times and Qibla direction.',
              style: TextStyle(color: AppTheme.textLight, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Geolocator.openAppSettings(),
              icon: const Icon(Icons.settings),
              label: const Text('Open App Settings'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
              ),
            ),
            TextButton(
              onPressed: () => Geolocator.openLocationSettings(),
              child: const Text('Check System Location'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrayerTimesView(BuildContext context, WidgetRef ref, PrayerTimes prayerTimes) {
    final nextPrayer = prayerTimes.nextPrayer();
    final timeFormat = DateFormat.jm();

    return RefreshIndicator(
      onRefresh: () async {
        // Refresh provider
        // ignore: unused_result
        ref.refresh(prayerTimesProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildNextPrayerCard(ref, nextPrayer, prayerTimes),
          const SizedBox(height: 24),
          const Text(
            'Today\'s Prayers',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
          ),
          const SizedBox(height: 12),
          _buildPrayerListItem(context, ref, 'Fajr', prayerTimes.fajr, timeFormat, nextPrayer == Prayer.fajr),
          _buildPrayerListItem(context, ref, 'Dhuhr', prayerTimes.dhuhr, timeFormat, nextPrayer == Prayer.dhuhr),
          _buildPrayerListItem(context, ref, 'Asr', prayerTimes.asr, timeFormat, nextPrayer == Prayer.asr),
          _buildPrayerListItem(context, ref, 'Maghrib', prayerTimes.maghrib, timeFormat, nextPrayer == Prayer.maghrib),
          _buildPrayerListItem(context, ref, 'Isha', prayerTimes.isha, timeFormat, nextPrayer == Prayer.isha),
          const SizedBox(height: 24),
          _buildDailyVerseCard(ref),
        ],
      ),
    );
  }

  Widget _buildNextPrayerCard(WidgetRef ref, Prayer nextPrayer, PrayerTimes prayerTimes) {
    String nextName = nextPrayer.name.toUpperCase();
    if (nextName == "NONE" || nextName == "INVALID") nextName = "FAJR (Tomorrow)";

    final countdownAsync = ref.watch(nextPrayerCountdownProvider);
    final nextTime = prayerTimes.timeForPrayer(nextPrayer);

    // Dynamic Gradients
    List<Color> gradientColors;
    switch (nextPrayer) {
      case Prayer.fajr:
        gradientColors = [const Color(0xFF0F2027), const Color(0xFF203A43)];
        break;
      case Prayer.dhuhr:
        gradientColors = [const Color(0xFF2980B9), const Color(0xFF6DD5FA)];
        break;
      case Prayer.asr:
        gradientColors = [const Color(0xFFF2994A), const Color(0xFFF2C94C)];
        break;
      case Prayer.maghrib:
        gradientColors = [const Color(0xFFE96443), const Color(0xFF904E95)];
        break;
      case Prayer.isha:
        gradientColors = [const Color(0xFF232526), const Color(0xFF414345)];
        break;
      default:
        gradientColors = [AppTheme.primaryGreen, const Color(0xFF006430)];
    }

    return Container(
      padding: const EdgeInsets.all(28.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'NEXT PRAYER',
            style: TextStyle(color: Colors.white70, fontSize: 13, letterSpacing: 2, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            nextName,
            style: const TextStyle(
              color: AppTheme.accentGold,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          if (nextTime != null)
            Text(
              DateFormat.jm().format(nextTime),
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
            ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20.0),
            child: Divider(color: Colors.white24, thickness: 1),
          ),
          countdownAsync.when(
            data: (duration) => Column(
              children: [
                const Text(
                  'TIME REMAINING',
                  style: TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDuration(duration),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w300,
                    fontFamily: 'Courier', // Using a monospaced font feel for the timer
                  ),
                ),
              ],
            ),
            loading: () => const SizedBox(height: 40, child: CircularProgressIndicator(color: Colors.white)),
            error: (_, __) => const Text('Error', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return "00:00:00";
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$hours:$minutes:$seconds";
  }

  Widget _buildPrayerListItem(BuildContext context, WidgetRef ref, String name, DateTime time, DateFormat format, bool isNext) {
    final tracking = ref.watch(prayerTrackingProvider);
    final dateKey = "${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}";
    final isDone = tracking[dateKey]?.contains(name) ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isNext ? AppTheme.accentGold.withOpacity(0.15) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isNext ? Border.all(color: AppTheme.accentGold, width: 2) : Border.all(color: Colors.grey.shade200),
      ),
      child: CheckboxListTile(
        title: Text(name, style: TextStyle(fontWeight: isNext ? FontWeight.bold : FontWeight.w500)),
        subtitle: Text(format.format(time)),
        value: isDone,
        activeColor: AppTheme.primaryGreen,
        onChanged: (bool? value) {
          ref.read(prayerTrackingProvider.notifier).togglePrayer(DateTime.now(), name);
        },
        secondary: isNext 
          ? const Icon(Icons.notifications_active, color: AppTheme.primaryGreen) 
          : const Icon(Icons.notifications_none, color: AppTheme.textLight),
      ),
    );
  }

  Widget _buildDailyVerseCard(WidgetRef ref) {
    final dailyVerseAsync = ref.watch(dailyVerseProvider);

    return dailyVerseAsync.when(
      data: (verse) => Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.menu_book_rounded, color: AppTheme.accentGold, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'DAILY VERSE',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textLight, letterSpacing: 1),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.play_circle_fill, color: AppTheme.primaryGreen, size: 32),
                  onPressed: () async {
                    final url = Uri.parse(verse.audioUrl);
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              verse.arabicText,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryGreen,
                fontFamily: 'Traditional Arabic', // Fallback to system fonts
              ),
            ),
            const SizedBox(height: 16),
            Text(
              verse.transliterationText,
              style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Divider(height: 24, thickness: 0.5),
            Text(
              '"${verse.translationText}"',
              style: const TextStyle(fontSize: 16, color: AppTheme.textDark, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.accentGold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  verse.reference,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange),
                ),
              ),
            ),
          ],
        ),
      ),
      loading: () => const Center(child: Padding(
        padding: EdgeInsets.all(20.0),
        child: CircularProgressIndicator(color: AppTheme.primaryGreen),
      )),
      error: (e, _) => const Text('Unable to load daily verse. Check connection.'),
    );
  }
}
