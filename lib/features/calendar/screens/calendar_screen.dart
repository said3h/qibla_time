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
          const SizedBox(height: 32),
          Text(
            'Important Events (${currentHijri.hYear} AH)',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
          ),
          const SizedBox(height: 16),
          ..._buildUpcomingEvents(),
        ],
      ),
    );
  }

  List<Widget> _buildUpcomingEvents() {
    final List<Map<String, dynamic>> events = [
      {'name': 'Islamic New Year', 'day': 1, 'month': 1},
      {'name': 'Ashura', 'day': 10, 'month': 1},
      {'name': 'Ramadan Begins', 'day': 1, 'month': 9},
      {'name': 'Eid al-Fitr', 'day': 1, 'month': 10},
      {'name': 'Day of Arafah', 'day': 9, 'month': 12},
      {'name': 'Eid al-Adha', 'day': 10, 'month': 12},
    ];

    return events.map((event) {
      final hCalendar = HijriCalendar();
      hCalendar.hYear = currentHijri.hYear;
      hCalendar.hMonth = event['month'];
      hCalendar.hDay = event['day'];
      
      final gregorianDate = hCalendar.hijriToGregorian(hCalendar.hYear, hCalendar.hMonth, hCalendar.hDay);
      final isCurrent = currentHijri.hMonth == event['month'];
      
      return _buildEventItem(
        event['name'], 
        '${event['day']} ${hCalendar.toFormat("MMMM")}', 
        DateFormat('EEEE, d MMM yyyy').format(gregorianDate),
        isCurrent
      );
    }).toList();
  }

  Widget _buildHijriBanner() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryGreen, Color(0xFF006430)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'TODAY',
            style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            '${currentHijri.hDay} ${currentHijri.toFormat("MMMM")}',
            style: const TextStyle(color: AppTheme.accentGold, fontSize: 28, fontWeight: FontWeight.bold),
          ),
          Text(
            '${currentHijri.hYear} AH',
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Divider(color: Colors.white24, thickness: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.calendar_month, color: Colors.white70, size: 18),
              const SizedBox(width: 8),
              Text(
                DateFormat('EEEE, d MMMM yyyy').format(selectedDate),
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGregorianDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Check specific date',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: selectedDate,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
              builder: (context, child) => Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.light(primary: AppTheme.primaryGreen),
                ),
                child: child!,
              ),
            );
            if (picked != null && picked != selectedDate) {
              _onDateChanged(picked);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('MMMM d, yyyy').format(selectedDate),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Icon(Icons.event, color: AppTheme.primaryGreen),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEventItem(String eventName, String hijriDateString, String gregorianDateString, bool isCurrentMonth) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isCurrentMonth ? AppTheme.primaryGreen.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: isCurrentMonth ? AppTheme.primaryGreen.withOpacity(0.1) : Colors.grey.shade100),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        title: Text(eventName, style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(hijriDateString, style: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.w600, fontSize: 13)),
            Text(gregorianDateString, style: const TextStyle(color: AppTheme.textLight, fontSize: 12)),
          ],
        ),
        trailing: isCurrentMonth 
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppTheme.primaryGreen, borderRadius: BorderRadius.circular(20)),
                child: const Text('THIS MONTH', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              )
            : null,
      ),
    );
  }
}

