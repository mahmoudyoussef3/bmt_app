import 'package:intl/intl.dart';

/// Presentation formatting shared across captain screens.
///
/// These are deliberately *not* [FormatUtil]: that helper renders times through
/// `DateFormat.jm` (locale-aware, 12-hour, with an AM/PM marker). Captain
/// screens are operational readouts that have always shown a zero-padded
/// 24-hour clock, and a captain comparing a departure against a wall clock
/// should not have to parse a meridiem marker.
///
/// The [DateFormat] instances are cached: constructing one parses its pattern,
/// and every caller here reads from a `build` method.
class CaptainFormats {
  const CaptainFormats._();

  static final DateFormat _fullDate = DateFormat('EEEE، d MMMM y', 'ar');
  static final DateFormat _dayAndMonth = DateFormat('EEEE، d MMMM', 'ar');
  static final DateFormat _dayMonthYear = DateFormat('d MMMM y', 'ar');
  static final DateFormat _monthAndYear = DateFormat('MMMM y', 'ar');

  /// A zero-padded 24-hour clock, e.g. `07:05`.
  static String clock(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// A departure–arrival window, e.g. `07:05 - 08:30`.
  static String timeRange(DateTime from, DateTime to) =>
      '${clock(from)} - ${clock(to)}';

  /// An elapsed duration in Arabic short units, e.g. `2س 15د`, or `—` when
  /// there is nothing to report.
  static String duration(Duration value) {
    if (value.inMinutes <= 0) return '—';
    final hours = value.inHours;
    final minutes = value.inMinutes.remainder(60);
    return hours > 0 ? '$hoursس $minutesد' : '$minutesد';
  }

  /// e.g. `الأحد، 6 يوليو 2026`.
  static String fullDate(DateTime value) => _fullDate.format(value);

  /// e.g. `الأحد، 6 يوليو`.
  static String dayAndMonth(DateTime value) => _dayAndMonth.format(value);

  /// e.g. `6 يوليو 2026`.
  static String dayMonthYear(DateTime value) => _dayMonthYear.format(value);

  /// e.g. `يوليو 2026`.
  static String monthAndYear(DateTime value) => _monthAndYear.format(value);
}
