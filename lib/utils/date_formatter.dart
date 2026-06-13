import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class DateFormatter {
  static bool _initialized = false;
  
  static Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await initializeDateFormatting('fr_FR', null);
      _initialized = true;
    }
  }
  
  static DateFormat get _fullFormat {
    _ensureInitialized();
    return DateFormat("d MMMM yyyy 'à' HH:mm", 'fr_FR');
  }
  
  static DateFormat get _dayFormat {
    _ensureInitialized();
    return DateFormat("d MMMM yyyy", 'fr_FR');
  }
  
  static DateFormat get _monthFormat {
    _ensureInitialized();
    return DateFormat("MMMM yyyy", 'fr_FR');
  }
  
  static DateFormat get _yearFormat {
    _ensureInitialized();
    return DateFormat("yyyy", 'fr_FR');
  }
  
  static DateFormat get _weekFormat {
    _ensureInitialized();
    return DateFormat("'Semaine' w 'de' yyyy", 'fr_FR');
  }

  static String formatFull(DateTime date) {
    return _fullFormat.format(date);
  }

  static String formatDay(DateTime date) {
    return _dayFormat.format(date);
  }

  static String formatMonth(DateTime date) {
    return _monthFormat.format(date);
  }

  static String formatYear(DateTime date) {
    return _yearFormat.format(date);
  }

  static String formatWeek(DateTime date) {
    return _weekFormat.format(date);
  }

  static DateTime getStartOfWeek(DateTime date) {
    final int daysToSubtract = date.weekday - DateTime.monday;
    return DateTime(date.year, date.month, date.day - daysToSubtract);
  }

  static DateTime getEndOfWeek(DateTime date) {
    final startOfWeek = getStartOfWeek(date);
    return DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day + 6, 23, 59, 59);
  }

  static DateTime getStartOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  static DateTime getEndOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0, 23, 59, 59);
  }

  static DateTime getStartOfYear(DateTime date) {
    return DateTime(date.year, 1, 1);
  }

  static DateTime getEndOfYear(DateTime date) {
    return DateTime(date.year, 12, 31, 23, 59, 59);
  }

  static DateTime getStartOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static DateTime getEndOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }
}