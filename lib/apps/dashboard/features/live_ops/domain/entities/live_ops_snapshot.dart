import 'trip_incident.dart';

/// Health of a trip's live position feed, derived from the age of its most
/// recent GPS fix.
///
/// The Captain App publishes a fix roughly every 30s while a trip runs
/// (`kAutoLocationInterval` in the captain live-location cubit). The thresholds
/// below are expressed as multiples of that cadence so a single dropped update
/// never demotes a healthy captain:
///
/// - [live]    — a fix within the last 75s (≤ ~2 cadences). Genuinely current.
/// - [stale]   — 75s–4min old. The feed slipped; worth a glance, not an alarm.
/// - [offline] — older than 4min while the trip is still running. The captain
///               has almost certainly lost signal or closed the app.
/// - [unknown] — the trip is active but no fix has ever arrived. The captain
///               likely never granted location permission or never started the
///               share. Distinct from [offline]: there is nothing to be stale.
enum TrackingHealth {
  live('حية'),
  stale('متأخرة'),
  offline('غير متصلة'),
  unknown('غير معروفة');

  const TrackingHealth(this.label);

  final String label;

  /// A fix at or under this age is [live].
  static const Duration liveWindow = Duration(seconds: 75);

  /// A fix older than [liveWindow] but at or under this age is [stale];
  /// anything older is [offline].
  static const Duration staleWindow = Duration(minutes: 4);

  /// Classifies a feed from the age of its latest fix. [fixAge] is `null` when
  /// no fix has ever been received.
  static TrackingHealth fromFixAge(Duration? fixAge) {
    if (fixAge == null) return TrackingHealth.unknown;
    if (fixAge <= liveWindow) return TrackingHealth.live;
    if (fixAge <= staleWindow) return TrackingHealth.stale;
    return TrackingHealth.offline;
  }
}

/// Where a trip stands against its scheduled departure time.
///
/// A transportation desk's single most actionable question about a trip that
/// has not left yet is "should it have?". The states below answer it without
/// the operator doing clock arithmetic:
///
/// - [pending]  — boarding, departure still ahead. Nothing to do.
/// - [due]      — boarding, within [boardingGrace] after the scheduled time.
///                Normal loading slack, not yet a problem.
/// - [overdue]  — boarding, past the grace window. The trip is late leaving and
///                nobody has told the desk why. This is the alarm.
/// - [departed] — already in progress. Lateness, if any, is history; the card
///                reports how late it left rather than nagging.
/// - [unknown]  — the schedule could not be parsed, so no honest claim is
///                possible. Never guessed.
enum DepartureStatus { pending, due, overdue, departed, unknown }

/// How long after the scheduled time a boarding trip is still considered to be
/// loading normally rather than late. Loading a 14-seat Hiace routinely runs a
/// few minutes past the clock; flagging that as late would train operators to
/// ignore the flag.
const Duration boardingGrace = Duration(minutes: 10);

/// The last known position reported for a trip.
class LiveFix {
  final double latitude;
  final double longitude;
  final double? heading;
  final double? speedKph;
  final DateTime recordedAt;

  const LiveFix({
    required this.latitude,
    required this.longitude,
    required this.recordedAt,
    this.heading,
    this.speedKph,
  });
}

/// A trip that is currently on the road (boarding or in progress), joined with
/// its crew, occupancy and live-tracking feed for the operations center.
class LiveTrip {
  final String id;

  /// `boarding` or `in_progress` — the raw operational status, kept as the
  /// dashboard's [OperationTripStatus] would render it. Stored as the display
  /// label so this entity carries no dependency on the trips feature.
  final String statusLabel;
  final bool isInProgress;

  final String routeName;
  final String driverName;
  final String driverPhone;
  final String vehicleLabel;
  final String tripDate;
  final String departureTime;
  final int capacity;
  final int bookedSeats;

  /// Latest position, or `null` if the trip has never reported one.
  final LiveFix? lastFix;

  /// `trip_date` + `departure_time` resolved to a single local instant, or
  /// `null` when either was missing or unparseable. Delay reporting is skipped
  /// entirely rather than guessed when this is `null`.
  final DateTime? scheduledDeparture;

  /// When the captain actually started the trip (`actual_start_time`), if the
  /// trip has departed.
  final DateTime? actualStart;

  const LiveTrip({
    required this.id,
    required this.statusLabel,
    required this.isInProgress,
    required this.routeName,
    required this.driverName,
    required this.driverPhone,
    required this.vehicleLabel,
    required this.tripDate,
    required this.departureTime,
    required this.capacity,
    required this.bookedSeats,
    this.lastFix,
    this.scheduledDeparture,
    this.actualStart,
  });

  /// Age of the latest fix relative to [now], or `null` if there is no fix.
  Duration? fixAgeAt(DateTime now) {
    final fix = lastFix;
    if (fix == null) return null;
    final age = now.difference(fix.recordedAt);
    
    return age.isNegative ? Duration.zero : age;
  }

  TrackingHealth trackingHealthAt(DateTime now) =>
      TrackingHealth.fromFixAge(fixAgeAt(now));

  double get occupancyRatio => capacity <= 0 ? 0 : bookedSeats / capacity;

  /// Where this trip stands against its schedule at [now].
  DepartureStatus departureStatusAt(DateTime now) {
    if (isInProgress) return DepartureStatus.departed;
    final scheduled = scheduledDeparture;
    if (scheduled == null) return DepartureStatus.unknown;

    final overdueBy = now.difference(scheduled);
    if (overdueBy.isNegative) return DepartureStatus.pending;
    return overdueBy <= boardingGrace
        ? DepartureStatus.due
        : DepartureStatus.overdue;
  }

  /// How late the trip is, or `null` when lateness is not a meaningful claim.
  ///
  /// For a trip still boarding this is how long it has been sitting past its
  /// scheduled time; for one already in progress it is how late it actually
  /// left. Returns `null` when the trip is early/on time, when the schedule is
  /// unknown, or when a departed trip never recorded a start time — an unknown
  /// delay must not render as "0 minutes late".
  Duration? departureDelayAt(DateTime now) {
    final scheduled = scheduledDeparture;
    if (scheduled == null) return null;

    final reference = isInProgress ? actualStart : now;
    if (reference == null) return null;

    final delay = reference.difference(scheduled);
    return delay > boardingGrace ? delay : null;
  }

  /// True when the desk should act: the trip is still boarding well past its
  /// scheduled departure. A trip already on the road is never "overdue" — it is
  /// simply late, which is reported, not alarmed.
  bool isOverdueAt(DateTime now) =>
      departureStatusAt(now) == DepartureStatus.overdue;
}

/// Everything the Live Operations Center renders in one pull: the trips on the
/// road and the open incident queue, stamped with the moment they were read so
/// tracking health is computed against a single, testable clock.
class LiveOpsSnapshot {
  final List<LiveTrip> activeTrips;
  final List<TripIncident> incidents;

  /// Client wall-clock at the moment this snapshot was assembled. Tracking
  /// health and "updated N ago" labels are measured against this, not a live
  /// clock, so the whole screen agrees and tests stay deterministic.
  final DateTime generatedAt;

  const LiveOpsSnapshot({
    required this.activeTrips,
    required this.incidents,
    required this.generatedAt,
  });

  const LiveOpsSnapshot.empty(this.generatedAt)
    : activeTrips = const [],
      incidents = const [];

  /// The desk's working queue: everything not yet closed, triaged worst-first.
  ///
  /// Order is severity, then age — an SOS filed a minute ago outranks a delay
  /// report from an hour ago, and within one severity the oldest waits least.
  /// Acknowledged reports stay in the queue (they are still open work) but sink
  /// below untouched ones of the same severity, so "nobody has looked at this"
  /// always floats to the top.
  List<TripIncident> get openIncidents {
    final open = incidents.where((i) => i.isOpen).toList();
    open.sort((a, b) {
      final bySeverity = a.severity.index.compareTo(b.severity.index);
      if (bySeverity != 0) return bySeverity;
      final byOwnership = (a.isPending ? 0 : 1).compareTo(b.isPending ? 0 : 1);
      if (byOwnership != 0) return byOwnership;
      return a.createdAt.compareTo(b.createdAt);
    });
    return open;
  }

  int get openIncidentCount => openIncidents.length;

  /// Open reports nobody has taken ownership of yet — the number that should
  /// drive an operator to act, as distinct from total open work.
  int get unacknowledgedCount => incidents.where((i) => i.isPending).length;

  bool get hasCriticalIncident =>
      openIncidents.any((i) => i.severity == IncidentSeverity.critical);

  int get inProgressCount => activeTrips.where((t) => t.isInProgress).length;

  int get boardingCount => activeTrips.where((t) => !t.isInProgress).length;

  /// Count of active trips whose feed is [TrackingHealth.stale],
  /// [TrackingHealth.offline] or [TrackingHealth.unknown] — the ones an
  /// operator can no longer see moving.
  int trackingAtRiskCount(DateTime now) => activeTrips
      .where((t) => t.trackingHealthAt(now) != TrackingHealth.live)
      .length;

  /// Trips still boarding well past their scheduled departure, worst first, so
  /// the desk works the longest-delayed trip before the one that just tipped
  /// over the grace window.
  List<LiveTrip> overdueTrips(DateTime now) {
    final overdue = activeTrips.where((t) => t.isOverdueAt(now)).toList();
    overdue.sort((a, b) {
      final aDelay = a.departureDelayAt(now) ?? Duration.zero;
      final bDelay = b.departureDelayAt(now) ?? Duration.zero;
      return bDelay.compareTo(aDelay);
    });
    return overdue;
  }

  int overdueCount(DateTime now) => overdueTrips(now).length;

  /// Active trips that have a position to draw. The map renders only these; the
  /// rest are still represented in the trip list, so an untracked trip is never
  /// silently dropped from the operator's view.
  List<LiveTrip> get mappableTrips =>
      activeTrips.where((t) => t.lastFix != null).toList();

  /// True when nothing at all is happening — used to pick between the map and
  /// a quiet empty state rather than showing an empty map of the world.
  bool get isQuiet => activeTrips.isEmpty && openIncidents.isEmpty;
}
