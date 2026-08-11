import 'package:intl/intl.dart';

import 'package:bmt_app/core/tracking/progress/stop_progress.dart';
import 'package:bmt_app/l10n/app_localizations.dart';

import '../../domain/entities/tracking_trip_state.dart';

/// Every string the tracking screen shows, resolved against the rider's locale.
///
/// The screen used to hardcode English inside an app that ships in Arabic and
/// runs right-to-left. Formatting lives here (not in the widgets) so a duration
/// or a clock time reads the same everywhere on the screen.
class TrackingLabels {
  const TrackingLabels(this.l10n, this.localeName);

  final AppLocalizations l10n;
  final String localeName;

  String headline(TrackingTripState state) => switch (state) {
    TrackingTripState.notStarted => l10n.tracking_stateNotStarted,
    TrackingTripState.driverOnWay => l10n.tracking_stateDriverOnWay,
    TrackingTripState.boarding => l10n.tracking_stateBoarding,
    TrackingTripState.inProgress => l10n.tracking_stateInProgress,
    TrackingTripState.completed => l10n.tracking_stateCompleted,
  };

  /// A clock time in the rider's locale ("٣:٤٥ م" / "3:45 PM").
  String? clock(DateTime? value) =>
      value == null ? null : DateFormat.jm(localeName).format(value);

  /// A countdown to [target]. Anything already due, or within the next minute,
  /// reads as "now" — a rider watching a bus pull in does not want "0 min".
  String countdown(DateTime? target, {DateTime? now}) {
    if (target == null) return l10n.tracking_etaUnavailable;
    final left = target.difference(now ?? DateTime.now());
    if (left.inSeconds <= 60) return l10n.tracking_etaNow;
    if (left.inMinutes < 60) return l10n.tracking_etaMinutes(left.inMinutes);
    return l10n.tracking_etaHoursMinutes(left.inHours, left.inMinutes % 60);
  }

  /// Where an ETA came from. Riders trust a number they can source, so the
  /// screen never passes a scheduled guess off as a live one.
  String? etaSource(EtaConfidence confidence) => switch (confidence) {
    EtaConfidence.live => l10n.tracking_sourceLive,
    EtaConfidence.estimated => l10n.tracking_sourceEstimated,
    EtaConfidence.scheduled => l10n.tracking_sourceScheduled,
    EtaConfidence.none => null,
  };

  String stopStatus(StopVisitStatus status) => switch (status) {
    StopVisitStatus.departed => l10n.tracking_stationPassed,
    StopVisitStatus.arrived => l10n.tracking_stationHere,
    StopVisitStatus.next => l10n.tracking_stopNext,
    StopVisitStatus.upcoming => '',
  };

  /// How fresh the captain's last fix is.
  String signalAge(DateTime? recordedAt, {DateTime? now}) {
    if (recordedAt == null) return l10n.tracking_signalNone;
    final age = (now ?? DateTime.now()).difference(recordedAt);
    if (age.inMinutes < 1) return l10n.tracking_updatedJustNow;
    return l10n.tracking_updatedMinutesAgo(age.inMinutes);
  }

  String rating(double value, int count) =>
      l10n.tracking_ratingWithCount(value.toStringAsFixed(1), count);

  String stopsRemaining(int count) => l10n.tracking_stopsRemaining(count);
}
