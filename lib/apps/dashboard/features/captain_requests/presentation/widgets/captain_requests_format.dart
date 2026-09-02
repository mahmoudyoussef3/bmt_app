import '../../../finance/presentation/widgets/finance_format.dart';

/// طلبات الكباتن' number and date vocabulary.
///
/// Delegates to [FinanceFormat] rather than rendering its own digits, for the
/// same reason الشكاوى and العملاء do: a count spelled `١٢` on one screen and
/// `12` on the next reads as two different numbers.
abstract final class CaptainRequestsFormat {
  const CaptainRequestsFormat._();

  static String count(num value) => FinanceFormat.count(value);

  static String date(DateTime value) => FinanceFormat.date(value);

  static String dateTime(DateTime value) => FinanceFormat.dateTime(value);

  /// How long ago a request arrived, in the office's own words — «اليوم»,
  /// «أمس», «منذ ٣ أيام».
  ///
  /// Null once "ago" stops being the useful reading, so a caller that already
  /// prints the date can leave the second line off rather than printing the
  /// same date twice — which is what a `return date(value)` fallback did.
  static String? age(DateTime value, DateTime now) {
    final days = DateTime(
      now.year,
      now.month,
      now.day,
    ).difference(DateTime(value.year, value.month, value.day)).inDays;
    if (days <= 0) return 'اليوم';
    if (days == 1) return 'أمس';
    if (days < 7) return 'منذ ${count(days)} أيام';
    if (days < 30) return 'منذ ${count(days ~/ 7)} أسابيع';
    return null;
  }

  /// An average turnaround as a headline figure and its unit, so the KPI tile
  /// can put the number in its value slot and the unit in its detail line —
  /// «٦ · ساعات» rather than one cramped string.
  static (String value, String unit) responseTime(Duration? average) {
    if (average == null) return ('—', 'لا توجد قرارات مسجّلة بعد');
    if (average.inHours >= 24) {
      return (count(average.inDays), 'أيام من الطلب حتى القرار');
    }
    if (average.inHours >= 1) {
      return (count(average.inHours), 'ساعات من الطلب حتى القرار');
    }
    return (count(average.inMinutes), 'دقائق من الطلب حتى القرار');
  }
}
