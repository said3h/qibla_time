import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:adhan/adhan.dart';
import '../services/prayer_service.dart';
import '../services/quran_service.dart';
import '../../tracking/services/tracking_service.dart';
import '../../../core/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

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
              // Navigate to Settings
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
          _buildNextPrayerCard(nextPrayer, prayerTimes),
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
          _buildDailyVerseCard(),
        ],
      ),
    );
  }

  Widget _buildNextPrayerCard(Prayer nextPrayer, PrayerTimes prayerTimes) {
    String nextName = nextPrayer.name.toUpperCase();
    if (nextName == "NONE" || nextName == "INVALID") nextName = "FAJR (Tomorrow)";

    DateTime? nextTime = prayerTimes.timeForPrayer(nextPrayer);
    
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Next Prayer',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            nextName,
            style: const TextStyle(
              color: AppTheme.accentGold,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          if (nextTime != null)
            Text(
              DateFormat.jm().format(nextTime),
              style: const TextStyle(color: Colors.white, fontSize: 24),
            ),
        ],
      ),
    );
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

  Widget _buildDailyVerseCard() {
    final dailyVerse = QuranVerseService.getVerseOfTheDay();

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.menu_book, color: AppTheme.accentGold),
              SizedBox(width: 8),
              Text(
                'Verse of the Day',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '"${dailyVerse['verse']}"',
            style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: AppTheme.textDark),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              dailyVerse['ref']!,
              style: const TextStyle(fontSize: 14, color: AppTheme.textLight),
            ),
          ),
        ],
      ),
    );
  }
}
