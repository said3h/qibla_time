class SpanishDateLabels {
  static const _weekdaysShort = [
    'Lun',
    'Mar',
    'Mié',
    'Jue',
    'Vie',
    'Sáb',
    'Dom',
  ];

  static const _weekdaysLong = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  static const _monthsShort = [
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];

  static const _monthsLong = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];

  static String shortWeekday(DateTime date) => _weekdaysShort[date.weekday - 1];

  static String longWeekday(DateTime date) => _weekdaysLong[date.weekday - 1];

  static String shortMonth(DateTime date) => _monthsShort[date.month - 1];

  static String longMonth(DateTime date) => _monthsLong[date.month - 1];

  static String compactDate(DateTime date) {
    return '${date.day} ${shortMonth(date)}';
  }

  static String shortWeekdayDate(DateTime date) {
    return '${longWeekday(date)}, ${date.day} ${shortMonth(date)} ${date.year}';
  }

  static String fullDate(DateTime date) {
    return '${longWeekday(date)}, ${date.day} de ${longMonth(date)}';
  }

  static String fullDateWithYear(DateTime date) {
    return '${longWeekday(date)}, ${date.day} de ${longMonth(date)} de ${date.year}';
  }
}
