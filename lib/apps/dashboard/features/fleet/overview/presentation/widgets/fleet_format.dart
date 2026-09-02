import 'package:bmt_app/core/vehicles/vehicles.dart';

import '../../../../finance/presentation/widgets/finance_format.dart';

/// إدارة الأسطول' number vocabulary.
///
/// Delegates to [FinanceFormat] rather than rendering its own digits, for the
/// same reason الشكاوى and العملاء do: a count spelled `١٢` on one screen and
/// `12` on the next reads as two different numbers.
abstract final class FleetFormat {
  const FleetFormat._();

  static String count(num value) => FinanceFormat.count(value);

  /// `هايس` — the short Arabic name of a `vehicles.vehicle_type`, for a list
  /// line that has no room for the form's full "Toyota Hiace - هايس". The raw
  /// column is free text, so it goes through the same tolerant parser the seat
  /// layouts use; an unrecognised type reads as nothing rather than as a raw
  /// `hiace` in the middle of an Arabic sentence.
  static String vehicleType(String raw) =>
      switch (VehicleTypeParser.fromDatabase(raw)) {
        VehicleType.hiace => 'هايس',
        VehicleType.coaster => 'كوستر',
        VehicleType.sprinter => 'سبرنتر',
        VehicleType.h1 => 'فان H1',
        VehicleType.other => '',
      };

  /// `2026/08/19` — one date shape for the whole module.
  static String date(DateTime value) => FinanceFormat.date(value);

  /// The same, from the ISO text the fleet entities store their dates as.
  /// Unparsable text is returned as itself: showing the operator the raw value
  /// they can recognise beats inventing a date they cannot.
  static String dateText(String iso) {
    final parsed = DateTime.tryParse(iso.trim());
    return parsed == null ? iso.trim() : date(parsed);
  }

  /// `متبقٍ ١٢ يوماً` / `منتهية منذ ٩ أيام` — what a licence or an inspection
  /// date *means*, so the reader is not doing arithmetic against today in
  /// every row.
  static String relativeDate(String iso, {DateTime? now}) {
    final days = _daysUntil(iso, now);
    if (days == null) return 'غير مسجلة';
    if (days == 0) return 'تنتهي اليوم';
    return days > 0 ? 'متبقٍ ${_span(days)}' : 'منتهية منذ ${_span(-days)}';
  }

  /// The same fact with the words a chip has room for: `خلال ٧ أيام`.
  static String remainingShort(String iso, {DateTime? now}) {
    final days = _daysUntil(iso, now);
    if (days == null) return 'غير مسجلة';
    if (days == 0) return 'اليوم';
    return days > 0 ? 'خلال ${_span(days)}' : 'منذ ${_span(-days)}';
  }

  /// `منذ ٣ أيام` — how stale a record is. Past a month it falls back to the
  /// date, where "منذ ٤٧ يوماً" stops being easier to read than `2026/07/05`.
  static String age(DateTime value, {DateTime? now}) {
    final diff = (now ?? DateTime.now()).difference(value);
    if (diff.isNegative) return date(value);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) {
      final minutes = _unit(
        diff.inMinutes,
        'دقيقة',
        'دقيقتين',
        'دقائق',
        'دقيقة',
      );
      return 'منذ $minutes';
    }
    if (diff.inHours < 24) {
      final hours = _unit(diff.inHours, 'ساعة', 'ساعتين', 'ساعات', 'ساعة');
      return 'منذ $hours';
    }
    if (diff.inDays < 30) return 'منذ ${_span(diff.inDays)}';
    return date(value);
  }

  static int? _daysUntil(String iso, DateTime? now) {
    final parsed = DateTime.tryParse(iso.trim());
    if (parsed == null) return null;
    final today = now ?? DateTime.now();
    return DateTime(
      parsed.year,
      parsed.month,
      parsed.day,
    ).difference(DateTime(today.year, today.month, today.day)).inDays;
  }

  /// A duration in the largest unit that still reads honestly, correctly
  /// pluralised. Arabic counts in four shapes, not two — "١ يوم" and "٧ يوم"
  /// are both wrong where "يوم" and "٧ أيام" are right — and a console that
  /// gets this wrong in every row of every table reads as machine output.
  static String _span(int days) {
    if (days < 30) return _unit(days, 'يوم', 'يومين', 'أيام', 'يوماً');
    if (days < 365) {
      return _unit((days / 30).round(), 'شهر', 'شهرين', 'أشهر', 'شهراً');
    }
    return _unit((days / 365).round(), 'سنة', 'سنتين', 'سنوات', 'سنة');
  }

  static String _unit(
    int value,
    String one,
    String two,
    String few,
    String many,
  ) {
    if (value == 1) return one;
    if (value == 2) return two;
    if (value <= 10) return '${count(value)} $few';
    return '${count(value)} $many';
  }
}
