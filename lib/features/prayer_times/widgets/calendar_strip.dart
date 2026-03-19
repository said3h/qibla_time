// Widget para el calendario strip horizontal (días de la semana)
// Inspirado en el prototipo qiblatime-prototype.html

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hijri/hijri_calendar.dart';
import '../../../core/theme/app_theme.dart';

class CalendarStrip extends StatelessWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;

  const CalendarStrip({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    // Generar los últimos 3 días y próximos 4 días
    final today = DateTime.now();
    final dates = List.generate(7, (index) {
      return today.subtract(Duration(days: 3 - index));
    });

    return SizedBox(
      height: 90,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemCount: dates.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final date = dates[index];
          final isToday = _isSameDay(date, today);
          final isSelected = _isSameDay(date, selectedDate);
          
          return _buildDayCard(date, isToday, isSelected);
        },
      ),
    );
  }

  Widget _buildDayCard(DateTime date, bool isToday, bool isSelected) {
    final hijriDate = HijriCalendar.fromDate(date);
    final dayNames = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    final dayName = dayNames[date.weekday - 1];
    
    return GestureDetector(
      onTap: () => onDateSelected(date),
      child: Container(
        width: 70,
        decoration: BoxDecoration(
          color: isSelected 
              ? AppTheme.gold.withOpacity(0.15) 
              : AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isToday || isSelected
                ? AppTheme.gold.withOpacity(0.4)
                : const Color(0x0FFFFFFF),
            width: isToday || isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Día de la semana
            Text(
              dayName,
              style: GoogleFonts.dmSans(
                fontSize: 11,
                color: isToday ? AppTheme.goldLight : AppTheme.muted,
                fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            const SizedBox(height: 6),
            // Número del día
            Text(
              date.day.toString(),
              style: GoogleFonts.dmSans(
                fontSize: 22,
                fontWeight: FontWeight.w500,
                color: isToday ? AppTheme.goldLight : AppTheme.text,
              ),
            ),
            const SizedBox(height: 4),
            // Día Hijri
            Text(
              '${hijriDate.day} ${_getHijriMonthAbbr(hijriDate.month)}',
              style: GoogleFonts.dmSans(
                fontSize: 9,
                color: AppTheme.muted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  String _getHijriMonthAbbr(int month) {
    const months = [
      'Muh', 'Saf', 'Rab I', 'Rab II', 
      'Jum I', 'Jum II', 'Raj', 'Sha', 
      'Ram', 'Shaw', 'Dhu Q', 'Dhu H'
    ];
    return months[month - 1];
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
