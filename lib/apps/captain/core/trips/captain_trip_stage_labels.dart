import 'package:bmt_app/apps/captain/core/utils/captain_formats.dart';

import 'captain_trip_stage.dart';

class CaptainTripStageLabels {
  const CaptainTripStageLabels._();

  static String eyebrow(CaptainTripStage stage) => switch (stage) {
    CaptainTripStage.underway || CaptainTripStage.boarding => 'رحلتك الحالية',
    CaptainTripStage.finished => 'رحلة مكتملة',
    CaptainTripStage.cancelled => 'رحلة ملغاة',
    _ => 'رحلتك القادمة',
  };

  static String action(CaptainTripStage stage) => switch (stage) {
    CaptainTripStage.awaitingRelease => 'بانتظار فتح الحجز',
    CaptainTripStage.awaitingWindow => 'لم يحن وقت الصعود',
    CaptainTripStage.readyToBoard => 'بدء صعود الركاب',
    CaptainTripStage.boarding => 'بدء الرحلة',
    CaptainTripStage.underway => 'إنهاء الرحلة',
    CaptainTripStage.finished => 'مكتملة',
    CaptainTripStage.cancelled => 'ملغاة',
  };

  static String openAction(CaptainTripStage stage) => switch (stage) {
    CaptainTripStage.underway => 'متابعة الرحلة',
    CaptainTripStage.boarding => 'متابعة صعود الركاب',
    CaptainTripStage.readyToBoard => 'بدء صعود الركاب',
    _ => 'عرض تفاصيل الرحلة',
  };

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

  static String _relative(DateTime target, DateTime now) {
    final delta = target.difference(now);
    if (delta.isNegative) return 'منذ ${_span(delta.abs())}';
    if (delta.inMinutes < 1) return 'الآن';
    return 'بعد ${_span(delta)}';
  }

  static String _span(Duration value) {
    final hours = value.inHours;
    final minutes = value.inMinutes.remainder(60);
    if (hours == 0) return '$minutes دقيقة';
    if (minutes == 0) return '$hours ساعة';
    return '$hours س و $minutes د';
  }
}
