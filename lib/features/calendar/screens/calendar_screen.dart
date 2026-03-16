import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime selectedDate = DateTime.now();
  late HijriCalendar currentHijri;

  @override
  void initState() {
    super.initState();
    HijriCalendar.setLocal('en');
    currentHijri = HijriCalendar.fromDate(selectedDate);
  }

  void _onDateChanged(DateTime newDate) {
    setState(() {
      selectedDate = newDate;
      currentHijri = HijriCalendar.fromDate(newDate);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
         title: const Text('Islamic Calendar', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildHijriBanner(),
          const SizedBox(height: 24),
          _buildGregorianDatePicker(),
          const SizedBox(height: 24),
          Text(
            'Upcoming Islamic Events (${currentHijri.hYear})',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
          ),
          const SizedBox(height: 12),
          _buildEventItem('Ramadan Begins', '1 Ramadan', currentHijri.hMonth == 9),
          _buildEventItem('Eid al-Fitr', '1 Shawwal', currentHijri.hMonth == 10),
          _buildEventItem('Day of Arafah', '9 Dhu al-Hijjah', currentHijri.hMonth == 12),
          _buildEventItem('Eid al-Adha', '10 Dhu al-Hijjah', currentHijri.hMonth == 12),
          _buildEventItem('Islamic New Year', '1 Muharram', currentHijri.hMonth == 1),
          _buildEventItem('Ashura', '10 Muharram', currentHijri.hMonth == 1),
        ],
      ),
    );
  }

  Widget _buildHijriBanner() {
    return Container(
       padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
       decoration: BoxDecoration(
         color: AppTheme.primaryGreen,
         borderRadius: BorderRadius.circular(16.0),
         boxShadow: [
            BoxShadow(
              color: AppTheme.primaryGreen.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
         ]
       ),
       child: Column(
         children: [
            Text(
              currentHijri.toFormat("MMMM"), // Hijri Month Name
              style: const TextStyle(color: AppTheme.accentGold, fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '${currentHijri.hDay} ${currentHijri.toFormat("MMMM")}, ${currentHijri.hYear} AH',
              style: const TextStyle(color: Colors.white, fontSize: 20),
            )
         ],
       ),
    );
  }

  Widget _buildGregorianDatePicker() {
    return InkWell(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: AppTheme.primaryGreen, 
                  onPrimary: Colors.white, 
                  onSurface: AppTheme.textDark, 
                ),
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryGreen, 
                  ),
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null && picked != selectedDate) {
          _onDateChanged(picked);
        }
      },
      child: Container(
         padding: const EdgeInsets.all(16.0),
         decoration: BoxDecoration(
           color: Colors.white,
           borderRadius: BorderRadius.circular(12),
           border: Border.all(color: Colors.grey.shade200),
         ),
         child: Row(
           mainAxisAlignment: MainAxisAlignment.spaceBetween,
           children: [
             Row(
                children: [
                  const Icon(Icons.calendar_today, color: AppTheme.primaryGreen),
                  const SizedBox(width: 12),
                  Text(
                    DateFormat('EEEE, MMMM d, yyyy').format(selectedDate),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
             ),
             const Icon(Icons.edit, color: AppTheme.textLight, size: 20),
           ],
         ),
      ),
    );
  }

  Widget _buildEventItem(String eventName, String hijriDateString, bool isCurrentMonth) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isCurrentMonth ? AppTheme.accentGold.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isCurrentMonth ? AppTheme.accentGold : Colors.grey.shade200),
      ),
      child: ListTile(
        title: Text(eventName, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(hijriDateString, style: TextStyle(color: isCurrentMonth ? AppTheme.primaryGreen : AppTheme.textLight)),
        trailing: isCurrentMonth 
            ? const Chip(
                label: Text('This Month', style: TextStyle(color: Colors.white, fontSize: 10)),
                backgroundColor: AppTheme.primaryGreen,
                padding: EdgeInsets.zero,
              )
            : null,
      ),
    );
  }
}
