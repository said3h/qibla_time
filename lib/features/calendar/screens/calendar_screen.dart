import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/spanish_date_labels.dart';
import '../../../l10n/l10n.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  static const int _hijriAdjustmentDays = 0;

  late DateTime selectedDate;
  late DateTime visibleMonth;
  late HijriCalendar currentHijri;

  @override
  void initState() {
    super.initState();
    final today = _dateOnly(DateTime.now());
    selectedDate = today;
    visibleMonth = DateTime(today.year, today.month);
    currentHijri = _hijriFor(today);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    HijriCalendar.setLocal(_hijriLocaleFor(context.l10n.localeName));
    currentHijri = _hijriFor(selectedDate);
  }

  void _selectDate(DateTime newDate) {
    setState(() {
      selectedDate = _dateOnly(newDate);
      visibleMonth = DateTime(newDate.year, newDate.month);
      currentHijri = _hijriFor(selectedDate);
    });
  }

  void _changeMonth(int delta) {
    setState(() {
      final nextMonth = DateTime(visibleMonth.year, visibleMonth.month + delta);
      final day = selectedDate.day.clamp(1, _daysInMonth(nextMonth)).toInt();
      visibleMonth = nextMonth;
      selectedDate = DateTime(nextMonth.year, nextMonth.month, day);
      currentHijri = _hijriFor(selectedDate);
    });
  }

  void _goToToday() {
    _selectDate(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;
    final l10n = context.l10n;
    final selectedEvents = _eventsForDate(selectedDate);

    return Scaffold(
      backgroundColor: tokens.bgPage,
      appBar: AppBar(
        backgroundColor: tokens.bgApp,
        foregroundColor: tokens.textPrimary,
        elevation: 0,
        title: Text(
          l10n.calendarTitle,
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
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _buildMonthHeader(tokens),
            const SizedBox(height: 16),
            _buildMonthGrid(tokens),
            const SizedBox(height: 16),
            _buildSelectedDayCard(tokens, selectedEvents),
            const SizedBox(height: 20),
            Text(
              l10n.calendarImportantDatesTitle(currentHijri.hYear),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: tokens.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ..._buildUpcomingEvents(tokens),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthHeader(QiblaTokens tokens) {
    final monthLabel = SpanishDateLabels.longMonth(visibleMonth);
    final hijriMonth = _hijriFor(selectedDate);
    final isTodayVisible = _isSameMonth(visibleMonth, DateTime.now());

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surfaceCardColor(tokens),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _blend(
            tokens.primary,
            tokens.border,
            _isLightTheme(tokens) ? 0.1 : 0.18,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color:
                tokens.primary.withOpacity(_isLightTheme(tokens) ? 0.08 : 0.16),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildMonthNavButton(
                tokens,
                icon: Icons.chevron_left_rounded,
                onTap: () => _changeMonth(-1),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '${_capitalize(monthLabel)} ${visibleMonth.year}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: tokens.textPrimary,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${hijriMonth.hDay} ${hijriMonth.toFormat("MMMM")} ${hijriMonth.hYear} AH',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: tokens.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              _buildMonthNavButton(
                tokens,
                icon: Icons.chevron_right_rounded,
                onTap: () => _changeMonth(1),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.center,
            child: TextButton.icon(
              onPressed:
                  isTodayVisible && _isSameDay(selectedDate, DateTime.now())
                      ? null
                      : _goToToday,
              icon: const Icon(Icons.today_outlined, size: 18),
              label: Text(context.l10n.commonToday),
              style: TextButton.styleFrom(
                foregroundColor: tokens.primary,
                disabledForegroundColor: tokens.textMuted,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthNavButton(
    QiblaTokens tokens, {
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: _blend(tokens.primary, tokens.bgSurface,
          _isLightTheme(tokens) ? 0.08 : 0.16),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: tokens.primary),
        ),
      ),
    );
  }

  Widget _buildMonthGrid(QiblaTokens tokens) {
    final days = _visibleGridDays(visibleMonth);
    final monthEvents = _eventsForVisibleMonth();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _surfaceCardColor(tokens),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: tokens.border),
      ),
      child: Column(
        children: [
          Row(
            children: _weekdayLabels()
                .map(
                  (label) => Expanded(
                    child: Center(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: tokens.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            itemCount: days.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.78,
            ),
            itemBuilder: (context, index) {
              final date = days[index];
              final events =
                  monthEvents[_dateOnly(date)] ?? const <_IslamicEvent>[];
              return _buildDayCell(tokens, date, events);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDayCell(
    QiblaTokens tokens,
    DateTime date,
    List<_IslamicEvent> events,
  ) {
    final isCurrentMonth = _isSameMonth(date, visibleMonth);
    final isToday = _isSameDay(date, DateTime.now());
    final isSelected = _isSameDay(date, selectedDate);
    final hasEvents = events.isNotEmpty;
    final hijri = _hijriFor(date);
    final foreground =
        isSelected ? _foregroundFor(tokens.primary) : tokens.textPrimary;
    final secondary = isSelected
        ? _foregroundFor(tokens.primary).withOpacity(0.78)
        : isCurrentMonth
            ? tokens.textSecondary
            : tokens.textMuted;

    Color background;
    Color border;
    if (isSelected) {
      background = tokens.primary;
      border = tokens.primary;
    } else if (isToday) {
      background = _blend(
          tokens.accent, tokens.bgSurface, _isLightTheme(tokens) ? 0.16 : 0.22);
      border = tokens.accent;
    } else if (hasEvents) {
      background = _blend(
          tokens.primary, tokens.bgSurface, _isLightTheme(tokens) ? 0.1 : 0.16);
      border = _blend(
          tokens.primary, tokens.borderMed, _isLightTheme(tokens) ? 0.2 : 0.3);
    } else {
      background = isCurrentMonth ? tokens.bgSurface : tokens.bgApp;
      border = tokens.border;
    }

    return Material(
      color: background.withOpacity(isCurrentMonth || isSelected ? 1 : 0.55),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => _selectDate(date),
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: border, width: isToday || isSelected ? 1.4 : 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${date.day}',
                style: TextStyle(
                  color: foreground
                      .withOpacity(isCurrentMonth || isSelected ? 1 : 0.45),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '${hijri.hDay}',
                style: TextStyle(
                  color: secondary
                      .withOpacity(isCurrentMonth || isSelected ? 1 : 0.5),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 5,
                child: hasEvents
                    ? DecoratedBox(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _foregroundFor(tokens.primary)
                              : tokens.accent,
                          shape: BoxShape.circle,
                        ),
                        child: const SizedBox(width: 5, height: 5),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedDayCard(
    QiblaTokens tokens,
    List<_IslamicEvent> selectedEvents,
  ) {
    final hijri = _hijriFor(selectedDate);
    final hijriLabel =
        '${hijri.hDay} ${hijri.toFormat("MMMM")} ${hijri.hYear} AH';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _blend(tokens.primary, tokens.bgSurface,
                _isLightTheme(tokens) ? 0.12 : 0.2),
            _blend(tokens.accent, tokens.bgSurface,
                _isLightTheme(tokens) ? 0.08 : 0.16),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _blend(tokens.primary, tokens.borderMed,
              _isLightTheme(tokens) ? 0.16 : 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: tokens.primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.event_available_outlined,
                    color: _foregroundFor(tokens.primary)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      SpanishDateLabels.fullDateWithYear(selectedDate),
                      style: TextStyle(
                        color: tokens.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      hijriLabel,
                      style: TextStyle(
                        color: tokens.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (selectedEvents.isNotEmpty)
            ...selectedEvents.map(
              (event) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.star_rounded, color: tokens.accent, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        event.name,
                        style: TextStyle(
                          color: tokens.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildUpcomingEvents(QiblaTokens tokens) {
    final events = _eventsForHijriYear(currentHijri.hYear);

    return events.map((event) {
      final isCurrentMonth = currentHijri.hMonth == event.hMonth;

      return _buildEventItem(
        tokens,
        event.name,
        '${event.hDay} ${event.hijriMonthName}',
        SpanishDateLabels.shortWeekdayDate(event.gregorianDate),
        isCurrentMonth,
      );
    }).toList();
  }

  Widget _buildEventItem(
    QiblaTokens tokens,
    String eventName,
    String hijriDateString,
    String gregorianDateString,
    bool isCurrentMonth,
  ) {
    final l10n = context.l10n;
    final isLightTheme = _isLightTheme(tokens);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isCurrentMonth
            ? _highlightCardColor(tokens)
            : _surfaceCardColor(tokens),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentMonth
              ? _blend(tokens.primary, tokens.primaryBorder,
                  isLightTheme ? 0.12 : 0.18)
              : _blend(
                  tokens.primary, tokens.border, isLightTheme ? 0.06 : 0.12),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: _blend(
                tokens.accent, tokens.bgSurface, isLightTheme ? 0.14 : 0.24),
            borderRadius: BorderRadius.circular(12),
          ),
          child:
              Icon(Icons.star_border_rounded, color: tokens.accent, size: 20),
        ),
        title: Text(
          eventName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: tokens.textPrimary,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '$hijriDateString · $gregorianDateString',
            style: TextStyle(
              color: tokens.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
        trailing: isCurrentMonth
            ? Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: tokens.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  l10n.calendarCurrentMonth.toUpperCase(),
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

  Map<DateTime, List<_IslamicEvent>> _eventsForVisibleMonth() {
    final first = DateTime(visibleMonth.year, visibleMonth.month, 1);
    final last = DateTime(visibleMonth.year, visibleMonth.month + 1, 0);
    final hijriYears = {
      _hijriFor(first).hYear,
      _hijriFor(selectedDate).hYear,
      _hijriFor(last).hYear,
    };
    final events = <DateTime, List<_IslamicEvent>>{};

    for (final hYear in hijriYears) {
      for (final event in _eventsForHijriYear(hYear)) {
        if (_isSameMonth(event.gregorianDate, visibleMonth)) {
          final key = _dateOnly(event.gregorianDate);
          events.putIfAbsent(key, () => <_IslamicEvent>[]).add(event);
        }
      }
    }

    return events;
  }

  List<_IslamicEvent> _eventsForDate(DateTime date) {
    return _eventsForHijriYear(_hijriFor(date).hYear)
        .where((event) => _isSameDay(event.gregorianDate, date))
        .toList();
  }

  List<_IslamicEvent> _eventsForHijriYear(int hYear) {
    final definitions = [
      ('newYear', 1, 1),
      ('ashura', 10, 1),
      ('ramadan', 1, 9),
      ('eidFitr', 1, 10),
      ('arafah', 9, 12),
      ('eidAdha', 10, 12),
    ];

    return definitions.map((event) {
      final hCalendar = HijriCalendar()
        ..hYear = hYear
        ..hMonth = event.$3
        ..hDay = event.$2;
      final gregorianDate =
          hCalendar.hijriToGregorian(hYear, event.$3, event.$2);

      return _IslamicEvent(
        id: event.$1,
        name: _eventName(event.$1),
        hDay: event.$2,
        hMonth: event.$3,
        hYear: hYear,
        hijriMonthName: hCalendar.toFormat('MMMM'),
        gregorianDate: _dateOnly(gregorianDate),
      );
    }).toList();
  }

  List<DateTime> _visibleGridDays(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    final leadingDays = first.weekday - DateTime.monday;
    final gridStart = first.subtract(Duration(days: leadingDays));

    return List.generate(
        42, (index) => _dateOnly(gridStart.add(Duration(days: index))));
  }

  List<String> _weekdayLabels() {
    final baseMonday = DateTime(2024, 1, 1);
    return List.generate(7, (index) {
      final label =
          SpanishDateLabels.shortWeekday(baseMonday.add(Duration(days: index)));
      return label.length > 2
          ? label.substring(0, 2).toUpperCase()
          : label.toUpperCase();
    });
  }

  String _eventName(String id) {
    final l10n = context.l10n;
    return switch (id) {
      'newYear' => l10n.calendarEventIslamicNewYear,
      'ashura' => l10n.calendarEventAshura,
      'ramadan' => l10n.calendarEventRamadanStart,
      'eidFitr' => l10n.calendarEventEidFitr,
      'arafah' => l10n.calendarEventDayOfArafah,
      'eidAdha' => l10n.calendarEventEidAdha,
      _ => id,
    };
  }

  HijriCalendar _hijriFor(DateTime date) {
    return HijriCalendar.fromDate(
        date.add(const Duration(days: _hijriAdjustmentDays)));
  }

  String _hijriLocaleFor(String localeName) {
    if (localeName.startsWith('ar')) {
      return 'ar';
    }
    return 'en';
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

  bool _isSameMonth(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month;
  }

  int _daysInMonth(DateTime month) {
    return DateTime(month.year, month.month + 1, 0).day;
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }
}

class _IslamicEvent {
  const _IslamicEvent({
    required this.id,
    required this.name,
    required this.hDay,
    required this.hMonth,
    required this.hYear,
    required this.hijriMonthName,
    required this.gregorianDate,
  });

  final String id;
  final String name;
  final int hDay;
  final int hMonth;
  final int hYear;
  final String hijriMonthName;
  final DateTime gregorianDate;
}
