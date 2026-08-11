import 'package:bmt_app/apps/captain/core/utils/captain_formats.dart';
import 'package:bmt_app/core/tracking/progress/station_board.dart';
import 'package:bmt_app/core/tracking/progress/stop_progress.dart';

import '../../domain/entities/station_action_failure.dart';
import '../../domain/entities/station_passenger.dart';

/// Every string the station flow shows. Kept out of the widgets so the wording
/// of a refusal is decided once, and so the Arabic plural forms (واحد / اثنان /
/// جمع) live next to each other where they can be kept consistent.
abstract final class StationLabels {
  /// "3 ركاب" — Arabic counts one, two and many differently, and a bus with two
  /// passengers left reading "2 ركاب" is the kind of thing a captain notices.
  static String passengers(int count) => switch (count) {
    0 => 'لا ركاب',
    1 => 'راكب واحد',
    2 => 'راكبان',
    _ => '$count ركاب',
  };

  static String stations(int count) => switch (count) {
    0 => 'لا محطات',
    1 => 'محطة واحدة',
    2 => 'محطتان',
    _ => '$count محطات',
  };

  static String remainingToBoard(int count) => switch (count) {
    1 => 'متبقي راكب واحد',
    2 => 'متبقي راكبان',
    _ => 'متبقي $count ركاب',
  };

  /// The headline answer to "can I leave now?".
  static String gateHeadline(StationGate gate) => switch (gate.state) {
    StationGateState.notAtStation => 'في الطريق إلى المحطة التالية',
    StationGateState.waitingForPassengers => 'في انتظار صعود جميع الركاب',
    StationGateState.waitingForDepartureTime => 'اكتمل الصعود — في انتظار الموعد',
    StationGateState.ready => 'يمكنك متابعة الرحلة',
  };

  /// The one line underneath it that says what is actually being waited on.
  static String? gateDetail(StationGate gate, DateTime now) {
    return switch (gate.state) {
      StationGateState.notAtStation => null,
      StationGateState.waitingForPassengers => remainingToBoard(
        gate.pendingCount,
      ),
      StationGateState.waitingForDepartureTime => _departureHint(gate, now),
      StationGateState.ready => null,
    };
  }

  static String? _departureHint(StationGate gate, DateTime now) {
    final at = gate.earliestDeparture;
    if (at == null) return null;
    final left = gate.countdown(now);
    final clock = 'يمكنك المغادرة بعد ${CaptainFormats.clock(at)}';
    if (left == null || left.inMinutes < 1) return clock;
    return '$clock — ${CaptainFormats.duration(left)}';
  }

  /// The primary button's label for each situation.
  static const arriveAction = 'تسجيل الوصول للمحطة';

  static String departAction(bool isLast) =>
      isLast ? 'متابعة — آخر محطة' : 'متابعة إلى المحطة التالية';

  /// A station's own state, for the timeline.
  static String stationStatus(TripStation station) {
    if (station.hasDeparted) return 'تم المرور';
    if (station.isCurrent) return 'عند المحطة الآن';
    return switch (station.status) {
      TripStationStatus.arriving => 'المحطة التالية',
      _ => 'لاحقاً',
    };
  }

  /// An estimate, always worded as one.
  static String? eta(StationEta eta) {
    final at = eta.at;
    if (at == null) return null;
    return 'الوصول المتوقع ${CaptainFormats.clock(at)}';
  }

  /// Where the estimate came from. Riders and captains alike are told, so a
  /// projection is never mistaken for a measurement.
  static String? etaSource(EtaConfidence confidence) => switch (confidence) {
    EtaConfidence.live => 'من الموقع المباشر',
    EtaConfidence.estimated => 'تقدير حسب سير الرحلة',
    EtaConfidence.scheduled => 'حسب الجدول',
    EtaConfidence.none => null,
  };

  /// The boarding tally, as three plain facts.
  static String expectedLine(TripStation station) =>
      '${passengers(station.expectedBoardings)} متوقعون';

  static String boardedLine(TripStation station) =>
      '${station.boardedCount} صعدوا';

  static String pendingLine(TripStation station) =>
      '${station.pendingCount} لم يصعدوا بعد';

  static String noShowReason(NoShowReason reason) => switch (reason) {
    NoShowReason.didNotArrive => 'الراكب لم يحضر',
    NoShowReason.cancelledByPassenger => 'الراكب ألغى الحجز',
    NoShowReason.passengerRequested => 'بناءً على طلب الراكب',
    NoShowReason.other => 'سبب آخر',
  };

  /// A refused transition, said in the captain's terms.
  ///
  /// The two interesting refusals are not errors — they are the rule doing its
  /// job — so they are worded as the rule, not as a failure.
  static String failure(StationActionException exception) {
    return switch (exception.failure) {
      StationActionFailure.passengersNotBoarded =>
        exception.pendingCount == null
            ? 'لا يمكن المغادرة قبل صعود جميع الركاب'
            : remainingToBoard(exception.pendingCount!),
      StationActionFailure.departureTimeNotReached =>
        exception.earliestDeparture == null
            ? 'لم يحن موعد المغادرة بعد'
            : 'يمكنك المغادرة بعد ${exception.earliestDeparture}',
      StationActionFailure.noCurrentStation =>
        'سجّل وصولك للمحطة أولاً — أو تم تسجيل المغادرة بالفعل',
      StationActionFailure.noPendingStation => 'لا توجد محطات متبقية',
      StationActionFailure.tripNotRunning => 'حالة الرحلة لا تسمح بهذا الإجراء',
      StationActionFailure.notYourTrip => 'غير مصرح لك بتعديل هذه الرحلة',
      StationActionFailure.noShowNoteRequired =>
        'اكتب سبب عدم الصعود قبل التأكيد',
      StationActionFailure.passengerNotPending =>
        'حالة الراكب تغيّرت — حدّث القائمة',
      StationActionFailure.unknown => 'تعذر تنفيذ الإجراء، حاول مجدداً',
    };
  }
}
