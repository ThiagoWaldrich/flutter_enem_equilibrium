// calendar/logic/date_calculator.dart
import 'package:intl/intl.dart';

class DateCalculator {
  static DateTime parseDate(String dateStr) {
    try {
      if (dateStr.length == 10 && dateStr.contains('-')) {
        return DateTime.parse(dateStr);
      }
      if (dateStr.length == 7 && dateStr.contains('-')) {
        return DateTime.parse('$dateStr-01');
      }
      return DateTime.parse(dateStr);
    } catch (e) {
      try {
        final parts = dateStr.split('-');
        if (parts.length >= 2) {
          final year = int.tryParse(parts[0]) ?? DateTime.now().year;
          final month = int.tryParse(parts[1]) ?? DateTime.now().month;
          return DateTime(year, month, 1);
        }
      } catch (_) {}
      return DateTime.now();
    }
  }

  static List<DateTime> getAllDaysInMonth(int year, int month) {
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);

    final days = <DateTime>[];
    for (var i = 0; i <= lastDay.difference(firstDay).inDays; i++) {
      days.add(firstDay.add(Duration(days: i)));
    }

    return days;
  }

  static String formatMonth(DateTime date) {
    return DateFormat('yyyy-MM').format(date);
  }

  static String formatDay(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }
}