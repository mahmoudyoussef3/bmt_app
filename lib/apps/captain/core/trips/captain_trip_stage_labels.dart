import 'package:bmt_app/apps/captain/core/utils/captain_formats.dart';

import 'captain_trip_stage.dart';

/// The Arabic the captain reads for each [CaptainTripStage], in one place.
///
/// The home card and the execution screen previously worded the same moment
/// differently — home offered "بدء الرحلة" on a trip whose own screen then
/// asked for "بدء صعود الركاب". One vocabulary, one file.
class CaptainTripStageLabels {
  const CaptainTripStageLabels._();

  /// The card's eyebrow: is this the trip being driven, or the next one up.
  static String eyebrow(CaptainTripStage stage) => switch (stage) {
    CaptainTripStage.underway || CaptainTripStage.boarding => 'رحلتك الحالية',
    CaptainTripStage.finished => 'رحلة مكتملة',
    CaptainTripStage.cancelled => 'رحلة ملغاة',
    _ => 'رحلتك القادمة',
  };

  /// The primary action's wording. Every pre-boarding stage says plainly what
  /// it is waiting for, so a disabled button is never a dead end.
  static String action(CaptainTripStage stage) => switch (stage) {
    CaptainTripStage.awaitingRelease => 'بانتظار فتح الحجز',
    CaptainTripStage.awaitingWindow => 'لم يحن وقت الصعود',
    CaptainTripStage.readyToBoard => 'بدء صعود الركاب',
    CaptainTripStage.boarding => 'بدء الرحلة',
    CaptainTripStage.underway => 'إنهاء الرحلة',
    CaptainTripStage.finished => 'مكتملة',
    CaptainTripStage.cancelled => 'ملغاة',
  };

  /// The home card's CTA, which *opens* the trip rather than transitioning it —
  /// so it reads as navigation, not as the state change itself.
  static String openAction(CaptainTripStage stage) => switch (stage) {
    CaptainTripStage.underway => 'متابعة الرحلة',
    CaptainTripStage.boarding => 'متابعة صعود الركاب',
    CaptainTripStage.readyToBoard => 'بدء صعود الركاب',
    _ => 'عرض تفاصيل الرحلة',
  };

  /// One line explaining *why* the trip is where it is, and what moves it on.
  ///
  /// [now] is passed in rather than read from the clock so callers can drive
  /// it from a ticker and keep the countdown honest.
  static String status({
    required CaptainTripStage stage,
    required DateTime departureTime,
    required DateTime now,
  }) {
    switch (stage) {
      case CaptainTripStage.awaitingRelease:
        return 'بانتظار فتح الحجز من إدارة العمليات';

      case CaptainTripStage.awaitingWindow:
        final opensAt = boardingOpensAt(departureTime);
        return 'يبدأ الصعود ${CaptainFormats.clock(opensAt)} — '
            '${_relative(opensAt, now)}';

      case CaptainTripStage.readyToBoard:
        return 'يمكنك بدء صعود الركاب الآن — '
            'الانطلاق ${CaptainFormats.clock(departureTime)}';

      case CaptainTripStage.boarding:
        final until = departureTime.difference(now);
        return until.isNegative
            ? 'الصعود جارٍ — تأخر الانطلاق ${_span(until.abs())}'
            : 'الصعود جارٍ — الانطلاق ${_relative(departureTime, now)}';

      case CaptainTripStage.underway:
        return 'الرحلة جارية الآن';

      case CaptainTripStage.finished:
        return 'اكتملت الرحلة';

      case CaptainTripStage.cancelled:
        return 'أُلغيت الرحلة';
    }
  }

  /// e.g. `بعد 45 دقيقة`, `الآن`, `منذ 10 دقائق`.
  static String _relative(DateTime target, DateTime now) {
    final delta = target.difference(now);
    if (delta.isNegative) return 'منذ ${_span(delta.abs())}';
    if (delta.inMinutes < 1) return 'الآن';
    return 'بعد ${_span(delta)}';
  }

  /// A duration in Arabic, e.g. `45 دقيقة`, `ساعتين و 10 د`.
  static String _span(Duration value) {
    final hours = value.inHours;
    final minutes = value.inMinutes.remainder(60);
    if (hours == 0) return '$minutes دقيقة';
    if (minutes == 0) return '$hours ساعة';
    return '$hours س و $minutes د';
  }
}
