import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/spanish_date_labels.dart';

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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _blend(
                tokens.primary,
                tokens.bgPage,
                _isLightTheme(tokens) ? 0.03 : 0.07,
              ),
              tokens.bgPage,
              _blend(
                tokens.accent,
                tokens.bgApp,
                _isLightTheme(tokens) ? 0.02 : 0.04,
              ),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
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
                color: tokens.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ..._buildUpcomingEvents(tokens),
          ],
        ),
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
        SpanishDateLabels.shortWeekdayDate(gregorianDate),
        isCurrentMonth,
      );
    }).toList();
  }

  Widget _buildHijriBanner(QiblaTokens tokens) {
    final bannerText = _foregroundFor(tokens.primary);
    final bannerAccent = _foregroundFor(tokens.accent);
    final today = _dateOnly(DateTime.now());
    final isToday = _isSameDay(selectedDate, today);
    final todayLabel = SpanishDateLabels.fullDateWithYear(today);
    final selectedLabel = SpanishDateLabels.fullDateWithYear(selectedDate);

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
              color: _surfaceCardColor(tokens),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: _blend(
                  tokens.primary,
                  tokens.borderMed,
                  _isLightTheme(tokens) ? 0.12 : 0.2,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: tokens.primary.withOpacity(
                    _isLightTheme(tokens) ? 0.08 : 0.16,
                  ),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${selectedDate.day} de ${SpanishDateLabels.longMonth(selectedDate)} de ${selectedDate.year}',
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
    final isLightTheme = _isLightTheme(tokens);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isCurrentMonth
            ? _highlightCardColor(tokens)
            : _surfaceCardColor(tokens),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isCurrentMonth
              ? _blend(
                  tokens.primary,
                  tokens.primaryBorder,
                  isLightTheme ? 0.12 : 0.18,
                )
              : _blend(
                  tokens.primary,
                  tokens.border,
                  isLightTheme ? 0.06 : 0.12,
                ),
        ),
        boxShadow: [
          BoxShadow(
            color: tokens.primary.withOpacity(isLightTheme ? 0.04 : 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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

  bool _isLightTheme(QiblaTokens tokens) {
    return ThemeData.estimateBrightnessForColor(tokens.bgPage) ==
        Brightness.light;
  }

  Color _blend(Color foreground, Color background, double opacity) {
    return Color.alphaBlend(foreground.withOpacity(opacity), background);
  }

  Color _surfaceCardColor(QiblaTokens tokens) {
    return _blend(
      tokens.primary,
      tokens.bgSurface,
      _isLightTheme(tokens) ? 0.05 : 0.09,
    );
  }

  Color _highlightCardColor(QiblaTokens tokens) {
    return _blend(
      tokens.primary,
      tokens.bgSurface,
      _isLightTheme(tokens) ? 0.12 : 0.18,
    );
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
