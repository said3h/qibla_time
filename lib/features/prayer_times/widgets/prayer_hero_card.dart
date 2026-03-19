// Widget para el Hero Card de la próxima oración
// Diseño inspirado en el prototipo qiblatime-prototype.html

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:adhan/adhan.dart';
import '../../../core/theme/app_theme.dart';

class PrayerHeroCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final nextPrayer = prayerTimes.nextPrayer();
    final nextPrayerTime = prayerTimes.timeForPrayer(nextPrayer);
    
    String nextName = nextPrayer.name.toUpperCase();
    if (nextName == "NONE" || nextName == "INVALID") {
      nextName = "FAJR (Mañana)";
    }
    
    // Gradiente según la oración
    final gradient = _getPrayerGradient(nextPrayer);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.gold.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: gradient.colors[0].withOpacity(0.4),
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
                  color: Colors.white.withOpacity(0.7),
                  letterSpacing: 1.5,
                ),
              ),
              Icon(
                Icons.info_outline,
                size: 16,
                color: Colors.white.withOpacity(0.5),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Nombre de la oración
          Text(
            nextName,
            style: GoogleFonts.amiri(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppTheme.goldLight,
            ),
          ),
          
          // Tiempo de la oración
          if (nextPrayerTime != null)
            Text(
              DateFormat('HH:mm').format(nextPrayerTime),
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          
          const SizedBox(height: 16),
          
          // Countdown
          if (timeRemaining != null) ...[
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
                          color: Colors.white.withOpacity(0.6),
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDuration(timeRemaining!),
                        style: GoogleFonts.dmSans(
                          fontSize: 28,
                          fontWeight: FontWeight.w300,
                          color: Colors.white,
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
          if (streak > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.gold.withOpacity(0.2),
                border: Border.all(color: AppTheme.gold.withOpacity(0.4)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.local_fire_department, 
                    color: Colors.orange, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    '$streak DÍAS',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.goldLight,
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

  LinearGradient _getPrayerGradient(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A3A5C), Color(0xFF0F2840), Color(0xFF1A3525)],
        );
      case Prayer.dhuhr:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2980B9), Color(0xFF6DD5FA), Color(0xFF2980B9)],
        );
      case Prayer.asr:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF2994A), Color(0xFFF2C94C), Color(0xFFE67E22)],
        );
      case Prayer.maghrib:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE96443), Color(0xFF904E95), Color(0xFFFF6B6B)],
        );
      case Prayer.isha:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF232526), Color(0xFF414345), Color(0xFF1A1A2E)],
        );
      default:
        return AppTheme.prayerHeroGradient;
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }
}
