import '../../../finance/presentation/widgets/finance_format.dart';

/// الشكاوى' number and date vocabulary.
///
/// Delegates to [FinanceFormat] rather than rendering its own digits, for the
/// same reason العملاء and الاشتراكات do: the الدعم section sits one sidebar
/// group away from المبيعات and reports on the same office, and a count spelled
/// `١٢` on one screen and `12` on the next reads as two different numbers.
abstract final class TicketsFormat {
  const TicketsFormat._();

  static String count(num value) => FinanceFormat.count(value);

  static String date(DateTime value) => FinanceFormat.date(value);

  static String dateTime(DateTime value) => FinanceFormat.dateTime(value);

  /// `متبقٍ ٣ س ١٢ د` — how much of the office's promise is left. Returns null
  /// when the ticket carries no clock, which is not the same claim as "no time
  /// left" and must not render as one.
  static String? slaRemaining(DateTime? dueAt, DateTime now) {
    if (dueAt == null) return null;
    final remaining = dueAt.difference(now);
    if (remaining.isNegative) return null;
    if (remaining.inHours > 0) {
      return 'متبقٍ ${remaining.inHours} س ${remaining.inMinutes.remainder(60)} د';
    }
    return 'متبقٍ ${remaining.inMinutes} د';
  }
}
