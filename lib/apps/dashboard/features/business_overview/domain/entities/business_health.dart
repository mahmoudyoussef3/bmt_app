/// The health axis of the executive overview: seven readings, each reduced to
/// one of four states by a rule that is stated on screen next to it.
library;

/// How loudly a health signal speaks.
///
/// Ordered so a plain descending sort by [index] puts the problems first and
/// the unmeasurable last: critical → warning → healthy → unknown.
enum BusinessHealthStatus {
  /// The figure could not be measured — usually because the window has no data
  /// yet, or the module that owns it failed to load.
  ///
  /// A fourth state rather than defaulting to [healthy], because "we have no
  /// idea" and "everything is fine" are different sentences and only one of
  /// them is honest on a page an owner makes decisions from.
  unknown,
  healthy,
  warning,
  critical,
}

/// The seven things the overview grades. One member per rule, so a threshold
/// lives in exactly one place and both the badge and the explanation read from
/// the same evaluation.
enum BusinessHealthMetric {
  revenueTrend,
  occupancy,
  cancellationRate,
  delayedTrips,
  openRefunds,
  fleetUtilisation,
  collectionHealth,
}

/// One graded reading.
///
/// [reading] is the measured figure, already formatted for display; [detail]
/// is the rule that turned it into [status]. Carrying the rule with the result
/// is what keeps this from being a black box that says "warning" and leaves the
/// owner to guess what would clear it.
class BusinessHealthSignal {
  final BusinessHealthMetric metric;
  final BusinessHealthStatus status;
  final String reading;
  final String detail;

  const BusinessHealthSignal({
    required this.metric,
    required this.status,
    required this.reading,
    required this.detail,
  });

  bool get needsAttention =>
      status == BusinessHealthStatus.warning ||
      status == BusinessHealthStatus.critical;
}
