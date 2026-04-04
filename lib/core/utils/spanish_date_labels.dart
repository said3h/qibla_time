import 'package:intl/intl.dart';

import '../../l10n/l10n.dart';

class SpanishDateLabels {
  static String shortWeekday(DateTime date) {
    return _capitalize(
      _stripTrailingDot(
        DateFormat.E(_locale()).format(date),
      ),
    );
  }

  static String longWeekday(DateTime date) {
    return _capitalize(DateFormat.EEEE(_locale()).format(date));
  }

  static String shortMonth(DateTime date) {
    return _stripTrailingDot(DateFormat.MMM(_locale()).format(date));
  }

  static String longMonth(DateTime date) {
    return DateFormat.MMMM(_locale()).format(date);
  }

  static String compactDate(DateTime date) {
    return '${date.day} ${shortMonth(date)}';
  }

  static String shortWeekdayDate(DateTime date) {
    switch (_locale()) {
      case 'ar':
        return DateFormat('EEEE، d MMM yyyy', 'ar').format(date);
      case 'en':
        return DateFormat('EEEE, MMM d yyyy', 'en').format(date);
      case 'fr':
        return DateFormat('EEEE d MMM yyyy', 'fr').format(date);
      default:
        return DateFormat("EEEE, d MMM yyyy", 'es').format(date);
    }
  }

  static String fullDate(DateTime date) {
    switch (_locale()) {
      case 'ar':
        return DateFormat('EEEE، d MMMM', 'ar').format(date);
      case 'en':
        return DateFormat('EEEE, MMMM d', 'en').format(date);
      case 'fr':
        return DateFormat('EEEE d MMMM', 'fr').format(date);
      default:
        return DateFormat("EEEE, d 'de' MMMM", 'es').format(date);
    }
  }

  static String fullDateWithYear(DateTime date) {
    switch (_locale()) {
      case 'ar':
        return DateFormat('EEEE، d MMMM yyyy', 'ar').format(date);
      case 'en':
        return DateFormat('EEEE, MMMM d, yyyy', 'en').format(date);
      case 'fr':
        return DateFormat('EEEE d MMMM yyyy', 'fr').format(date);
      default:
        return DateFormat("EEEE, d 'de' MMMM 'de' yyyy", 'es').format(date);
    }
  }

  static String _locale() => currentLanguageCode();

  static String _stripTrailingDot(String value) {
    return value.endsWith('.') ? value.substring(0, value.length - 1) : value;
  }

  static String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }
}
