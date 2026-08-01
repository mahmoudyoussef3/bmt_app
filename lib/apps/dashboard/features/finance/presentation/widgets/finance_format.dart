import 'package:intl/intl.dart';

/// One money vocabulary for the whole module.
///
/// Western digits with thousands separators on purpose: these figures sit in
/// dense tables and charts next to each other, and mixing Arabic-Indic numerals
/// into a right-aligned money column is where "١٢٬٣٤٥" starts reading as a
/// different magnitude than "12,345" one row above it.
class FinanceFormat {
  const FinanceFormat._();

  static final NumberFormat _whole = NumberFormat('#,##0', 'en_US');
  static final NumberFormat _precise = NumberFormat('#,##0.00', 'en_US');

  /// `12,340 ج.م` — the default for KPIs, tables and charts.
  static String money(double value) => '${_whole.format(value.round())} ج.م';

  /// `12,340.75 ج.م` — statements and single-record detail, where the piastres
  /// are the point.
  static String moneyPrecise(double value) => '${_precise.format(value)} ج.م';

  static String count(num value) => _whole.format(value);

  /// `12.4%`
  static String percent(double fraction, {int decimals = 1}) =>
      '${(fraction * 100).toStringAsFixed(decimals)}%';

  /// Signed change, e.g. `+18.2%`. `null` renders as a dash, because "no
  /// comparable period" is not the same claim as "0% change".
  static String changeLabel(double? fraction) {
    if (fraction == null) return '—';
    final sign = fraction >= 0 ? '+' : '';
    return '$sign${(fraction * 100).toStringAsFixed(1)}%';
  }

  static String date(DateTime value) =>
      '${value.year}/${_two(value.month)}/${_two(value.day)}';

  /// `07/31` — dense axis labels.
  static String shortDate(DateTime value) =>
      '${_two(value.day)}/${_two(value.month)}';

  static String dateTime(DateTime value) =>
      '${date(value)} — ${_two(value.hour)}:${_two(value.minute)}';

  static String time(DateTime value) =>
      '${_two(value.hour)}:${_two(value.minute)}';

  static String _two(int value) => value.toString().padLeft(2, '0');
}
