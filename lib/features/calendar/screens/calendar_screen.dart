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
    final tokens = QiblaThemes.current;

    return Scaffold(
      backgroundColor: tokens.bgPage,
      appBar: AppBar(
        backgroundColor: tokens.bgApp,
        foregroundColor: tokens.textPrimary,
        elevation: 0,
        title: Text(
          'Calendario islámico',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: tokens.textPrimary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHijriBanner(tokens),
          const SizedBox(height: 24),
          _buildGregorianDatePicker(tokens),
          const SizedBox(height: 32),
          Text(
            'Fechas importantes (${currentHijri.hYear} AH)',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: tokens.primary,
            ),
          ),
          const SizedBox(height: 16),
          ..._buildUpcomingEvents(tokens),
        ],
      ),
    );
  }

  List<Widget> _buildUpcomingEvents(QiblaTokens tokens) {
    final events = [
      {'name': 'Año nuevo islámico', 'day': 1, 'month': 1},
      {'name': 'Ashura', 'day': 10, 'month': 1},
      {'name': 'Inicio de Ramadán', 'day': 1, 'month': 9},
      {'name': 'Eid al-Fitr', 'day': 1, 'month': 10},
      {'name': 'Día de Arafah', 'day': 9, 'month': 12},
      {'name': 'Eid al-Adha', 'day': 10, 'month': 12},
    ];

    return events.map((event) {
      final hCalendar = HijriCalendar();
      hCalendar.hYear = currentHijri.hYear;
      hCalendar.hMonth = event['month'] as int;
      hCalendar.hDay = event['day'] as int;

      final gregorianDate = hCalendar.hijriToGregorian(
        hCalendar.hYear,
        hCalendar.hMonth,
        hCalendar.hDay,
      );
      final isCurrentMonth = currentHijri.hMonth == event['month'];

      return _buildEventItem(
        tokens,
        event['name'] as String,
        '${event['day']} ${hCalendar.toFormat("MMMM")}',
        DateFormat('EEEE, d MMM yyyy', 'es').format(gregorianDate),
        isCurrentMonth,
      );
    }).toList();
  }

  Widget _buildHijriBanner(QiblaTokens tokens) {
    final bannerText = _foregroundFor(tokens.primary);
    final bannerAccent = _foregroundFor(tokens.accent);
    final today = _dateOnly(DateTime.now());
    final isToday = _isSameDay(selectedDate, today);
    final todayLabel = DateFormat('EEEE, d MMMM yyyy', 'es').format(today);
    final selectedLabel = DateFormat(
      'EEEE, d MMMM yyyy',
      'es',
    ).format(selectedDate);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [tokens.primary, tokens.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: tokens.primary.withOpacity(0.22),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            isToday ? 'HOY' : 'FECHA SELECCIONADA',
            style: TextStyle(
              color: bannerText.withOpacity(0.7),
              fontSize: 12,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${currentHijri.hDay} ${currentHijri.toFormat("MMMM")}',
            style: TextStyle(
              color: bannerAccent,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '${currentHijri.hYear} AH',
            style: TextStyle(
              color: bannerText,
              fontSize: 18,
            ),
          ),
          Divider(
            color: bannerText.withOpacity(0.2),
            thickness: 1,
            height: 32,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.calendar_month, color: bannerText.withOpacity(0.75), size: 18),
              const SizedBox(width: 8),
              Text(
                selectedLabel,
                style: TextStyle(
                  color: bannerText,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          if (!isToday) ...[
            const SizedBox(height: 10),
            Text(
              'Hoy: $todayLabel',
              style: TextStyle(
                color: bannerText.withOpacity(0.78),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGregorianDatePicker(QiblaTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selecciona una fecha',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: tokens.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: selectedDate,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
              builder: (context, child) => Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: ColorScheme(
                    brightness: ThemeData.estimateBrightnessForColor(tokens.bgPage),
                    primary: tokens.primary,
                    onPrimary: _foregroundFor(tokens.primary),
                    secondary: tokens.accent,
                    onSecondary: _foregroundFor(tokens.accent),
                    error: tokens.danger,
                    onError: _foregroundFor(tokens.danger),
                    surface: tokens.bgSurface,
                    onSurface: tokens.textPrimary,
                  ),
                  dialogBackgroundColor: tokens.bgSurface,
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
              color: tokens.bgSurface,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: tokens.borderMed),
              boxShadow: [
                BoxShadow(
                  color: tokens.border.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('d MMMM yyyy', 'es').format(selectedDate),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: tokens.textPrimary,
                  ),
                ),
                Icon(Icons.event, color: tokens.primary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEventItem(
    QiblaTokens tokens,
    String eventName,
    String hijriDateString,
    String gregorianDateString,
    bool isCurrentMonth,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isCurrentMonth ? tokens.primaryBg : tokens.bgSurface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isCurrentMonth ? tokens.primaryBorder : tokens.border,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        title: Text(
          eventName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: tokens.textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              hijriDateString,
              style: TextStyle(
                color: tokens.primary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            Text(
              gregorianDateString,
              style: TextStyle(
                color: tokens.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: isCurrentMonth
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: tokens.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'ESTE MES',
                  style: TextStyle(
                    color: _foregroundFor(tokens.primary),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
      ),
    );
  }

  Color _foregroundFor(Color background) {
    final brightness = ThemeData.estimateBrightnessForColor(background);
    return brightness == Brightness.dark ? Colors.white : Colors.black;
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
