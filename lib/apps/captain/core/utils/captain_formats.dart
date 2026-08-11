import 'package:intl/intl.dart';

class CaptainFormats {
  const CaptainFormats._();

  static final DateFormat _fullDate = DateFormat('EEEE، d MMMM y', 'ar');
  static final DateFormat _dayAndMonth = DateFormat('EEEE، d MMMM', 'ar');
  static final DateFormat _dayMonthYear = DateFormat('d MMMM y', 'ar');
  static final DateFormat _monthAndYear = DateFormat('MMMM y', 'ar');

  static String clock(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  static String timeRange(DateTime from, DateTime to) =>
      '${clock(from)} - ${clock(to)}';

  static String duration(Duration value) {
    if (value.inMinutes <= 0) return '—';
    final hours = value.inHours;
    final minutes = value.inMinutes.remainder(60);
    return hours > 0 ? '$hoursس $minutesد' : '$minutesد';
  }

  static String fullDate(DateTime value) => _fullDate.format(value);

  static String dayAndMonth(DateTime value) => _dayAndMonth.format(value);

  static String dayMonthYear(DateTime value) => _dayMonthYear.format(value);

  static String monthAndYear(DateTime value) => _monthAndYear.format(value);
}
