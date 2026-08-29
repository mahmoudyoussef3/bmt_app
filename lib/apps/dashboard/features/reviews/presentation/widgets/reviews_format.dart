import '../../../finance/presentation/widgets/finance_format.dart';

/// التقييمات' number and date vocabulary.
///
/// Delegates to [FinanceFormat] for exactly the reason الشكاوى next door does:
/// the two modules sit in one sidebar section and report on one office, and a
/// count spelled `١٢` on one screen and `12` on the next reads as two numbers.
abstract final class ReviewsFormat {
  const ReviewsFormat._();

  static String count(num value) => FinanceFormat.count(value);

  static String dateTime(DateTime value) => FinanceFormat.dateTime(value);

  /// `٤٫٣` — a score out of five, to one decimal. Returns an em dash when there
  /// is nothing to average: `0.0` would claim every passenger gave zero stars.
  static String rating(double value, {required int outOf}) =>
      outOf == 0 ? '—' : value.toStringAsFixed(1);

  /// `05/08 · 14:30` — the dense form a table cell has room for.
  static String shortStamp(DateTime value) {
    final d = value.day.toString().padLeft(2, '0');
    final m = value.month.toString().padLeft(2, '0');
    final hh = value.hour.toString().padLeft(2, '0');
    final mm = value.minute.toString().padLeft(2, '0');
    return '$d/$m · $hh:$mm';
  }
}
