// Widget para el Header con Bismillah
// Diseño inspirado en el prototipo qiblatime-prototype.html

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';

class HomeHeader extends StatelessWidget {
  final DateTime currentDate;
  final String hijriDate;

  const HomeHeader({
    super.key,
    required this.currentDate,
    required this.hijriDate,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo y Bismillah
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // QiblaTime logo
                Text(
                  'Qibla Time',
                  style: GoogleFonts.amiri(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: tokens.primary,
                  ),
                ),
                const SizedBox(height: 4),
                // Bismillah en árabe
                Text(
                  'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيم',
                  style: GoogleFonts.amiri(
                    fontSize: 14,
                    color: tokens.textSecondary,
                    height: 1.8,
                  ),
                  textAlign: TextAlign.right,
                ),
              ],
            ),
          ),
          
          // Fecha Gregoriana e Hijri
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatDate(currentDate),
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: tokens.textSecondary,
                  fontWeight: FontWeight.w500,
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
                  hijriDate,
                  style: GoogleFonts.amiri(
                    fontSize: 13,
                    color: tokens.primaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    const days = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];
    
    return '${days[date.weekday % 7]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
