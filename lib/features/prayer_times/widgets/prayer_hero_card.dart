// Widget para el Hero Card de la próxima oración con countdown en tiempo real
// Diseño inspirado en el prototipo qiblatime-prototype.html

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:adhan/adhan.dart';
import '../../../core/theme/app_theme.dart';

class PrayerHeroCard extends StatefulWidget {
  final PrayerTimes prayerTimes;
  final Duration? timeRemaining;
  final int streak;

  const PrayerHeroCard({
    super.key,
    required this.prayerTimes,
    this.timeRemaining,
    this.streak = 0,
  });

  @override
  State<PrayerHeroCard> createState() => _PrayerHeroCardState();
}

class _PrayerHeroCardState extends State<PrayerHeroCard> {
  Timer? _timer;
  Duration? _remaining;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          final now = DateTime.now();
          final nextPrayer = widget.prayerTimes.nextPrayer();
          final nextTime = widget.prayerTimes.timeForPrayer(nextPrayer);
          
          if (nextTime != null && nextTime.isAfter(now)) {
            _remaining = nextTime.difference(now);
          } else {
            _remaining = Duration.zero;
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;
    final nextPrayer = widget.prayerTimes.nextPrayer();
    final nextPrayerTime = widget.prayerTimes.timeForPrayer(nextPrayer);
    
    String nextName = nextPrayer.name.toUpperCase();
    if (nextName == "NONE" || nextName == "INVALID") {
      nextName = "FAJR (Mañana)";
    }
    
    // Obtener colores del hero según la oración
    final hero = tokens.getHero(nextPrayer.name.toLowerCase());

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [hero.bg, hero.tint, hero.bg],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tokens.primaryBorder),
        boxShadow: [
          BoxShadow(
            color: hero.tint.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: "Próxima oración"
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              Icon(
                Icons.info_outline,
                size: 16,
                color: hero.label.withOpacity(0.5),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Nombre de la oración
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nextName,
                      style: GoogleFonts.amiri(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: tokens.primaryLight,
                      ),
                    ),
                    // Tiempo de la oración
                    if (nextPrayerTime != null)
                      Text(
                        DateFormat('HH:mm').format(nextPrayerTime),
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: hero.label,
                        ),
                      ),
                  ],
                ),
              ),
              // Icono de la oración
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: tokens.primaryBg,
                  shape: BoxShape.circle,
                  border: Border.all(color: tokens.primaryBorder),
                ),
                child: Icon(
                  _getPrayerIcon(nextPrayer),
                  color: tokens.primary,
                  size: 28,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Countdown
          if (_remaining != null) ...[
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TIEMPO RESTANTE',
                        style: GoogleFonts.dmSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                          color: hero.label.withOpacity(0.6),
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDuration(_remaining!),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w300,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
          
          const SizedBox(height: 14),
          
          // Streak badge
          if (widget.streak > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: tokens.activeBg,
                border: Border.all(color: tokens.primaryBorder),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.local_fire_department, 
                    color: Colors.orange, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    '${widget.streak} DÍAS',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: tokens.primaryLight,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  IconData _getPrayerIcon(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr:
        return Icons.brightness_2; // Luna
      case Prayer.dhuhr:
        return Icons.wb_sunny; // Sol
      case Prayer.asr:
        return Icons.wb_sunny_outlined; // Sol tarde
      case Prayer.maghrib:
        return Icons.nights_stay; // Atardecer
      case Prayer.isha:
        return Icons.star; // Noche
      default:
        return Icons.access_time;
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }
}
