import 'stop_progress.dart';

/// The persisted lifecycle of one station on a running trip, mirroring
/// `trip_station_progress.status` exactly.
///
/// Deliberately shorter than the conceptual lifecycle: "ready to depart" is not
/// a stored state, because it becomes true simply because a minute passed and
/// no row was written. It is derived — see [StationGate] — from the same facts
/// the database derives it from in `captain_depart_station`.
enum TripStationStatus {
  /// Somewhere further down the route; the vehicle is not heading here yet.
  upcoming,

  /// The vehicle left the previous station and is driving towards this one.
  arriving,

  /// The vehicle is standing here, collecting the passengers due to board.
  waitingForPassengers,

  /// The vehicle has left.
  departed,
}

TripStationStatus tripStationStatusFrom(String? raw) => switch (raw) {
  'arriving' => TripStationStatus.arriving,
  'waiting_for_passengers' => TripStationStatus.waitingForPassengers,
  'departed' => TripStationStatus.departed,
  _ => TripStationStatus.upcoming,
};

/// One station of one trip: where it sits in the route, when it was planned for,
/// when the vehicle actually reached and left it, and the boarding tally there.
///
/// The counts are read straight from the row rather than recomputed from a
/// manifest, because a rider may only read their *own* manifest line — the
/// database denormalises them precisely so both apps can show the same numbers.
class TripStation {
  const TripStation({
    required this.id,
    required this.name,
    required this.sequence,
    required this.status,
    this.routePointId,
    this.expectedArrivalAt,
    this.expectedDepartureAt,
    this.minDwell = Duration.zero,
    this.actualArrivalAt,
    this.actualDepartureAt,
    this.expectedBoardings = 0,
    this.boardedCount = 0,
    this.pendingCount = 0,
    this.noShowCount = 0,
  });

  final String id;
  final String name;

  /// 1-based position along the route.
  final int sequence;

  final TripStationStatus status;

  /// `route_stations.id` — the id a manifest row's pickup point is expressed in.
  final String? routePointId;

  final DateTime? expectedArrivalAt;
  final DateTime? expectedDepartureAt;

  /// The dwell the operator configured for this stop (`departure_offset` −
  /// `arrival_offset`). A vehicle that arrives late still owes its passengers
  /// this long to board.
  final Duration minDwell;

  final DateTime? actualArrivalAt;
  final DateTime? actualDepartureAt;

  /// Riders due to board here who have not cancelled.
  final int expectedBoardings;

  /// Riders who are aboard.
  final int boardedCount;

  /// Riders still expected — the ones holding the vehicle here.
  final int pendingCount;

  /// Riders explicitly resolved as not travelling.
  final int noShowCount;

  bool get hasArrived => actualArrivalAt != null;
  bool get hasDeparted => actualDepartureAt != null;

  /// The vehicle is standing here right now.
  bool get isCurrent => hasArrived && !hasDeparted;

  /// Every rider due here is accounted for: aboard, a recorded no-show, or
  /// cancelled. This is the departure gate's Condition A.
  bool get boardingResolved => pendingCount <= 0;

  /// The earliest instant the vehicle may leave: the later of the configured
  /// dwell measured from the real arrival, and the published departure time.
  ///
  /// Mirrors `station_earliest_departure` in migration 20260811090000. Null
  /// until the vehicle has arrived and when the stop was never timed — in which
  /// case the boarding requirement is the only gate.
  DateTime? get earliestDeparture {
    final dwellDeadline = actualArrivalAt?.add(minDwell);
    final planned = expectedDepartureAt;
    if (dwellDeadline == null) return planned;
    if (planned == null) return dwellDeadline;
    return dwellDeadline.isAfter(planned) ? dwellDeadline : planned;
  }
}

/// Why the captain can — or cannot — leave the station they are standing at.
enum StationGateState {
  /// The vehicle is not at a station, so there is nothing to leave.
  notAtStation,

  /// Riders are still expected here.
  waitingForPassengers,

  /// Everyone is accounted for, but the vehicle is not due out yet.
  waitingForDepartureTime,

  /// Both conditions met.
  ready,
}

/// The answer to the only question a captain standing at a station has.
///
/// This is a *representation* of the rule. `captain_depart_station` evaluates
/// the identical two conditions server-side and refuses the transition when
/// they do not hold, so a stale screen cannot let a vehicle leave early.
class StationGate {
  const StationGate({
    required this.state,
    required this.pendingCount,
    this.station,
    this.earliestDeparture,
  });

  const StationGate.notAtStation()
    : state = StationGateState.notAtStation,
      pendingCount = 0,
      station = null,
      earliestDeparture = null;

  final StationGateState state;

  /// The station the vehicle is standing at, null when it is between stations.
  final TripStation? station;

  /// Riders still expected to board here.
  final int pendingCount;

  /// When the vehicle becomes free to leave; null when no time gates it.
  final DateTime? earliestDeparture;

  bool get canDepart => state == StationGateState.ready;

  /// How long until [earliestDeparture]; null when nothing is being waited on.
  Duration? countdown(DateTime now) {
    final target = earliestDeparture;
    if (target == null || !target.isAfter(now)) return null;
    return target.difference(now);
  }
}

/// A per-station arrival estimate, carrying where it came from so no surface
/// can present a guess as a measurement.
class StationEta {
  const StationEta({
    required this.station,
    this.at,
    this.confidence = EtaConfidence.none,
  });

  final TripStation station;

  /// The estimate; null when the stop has no planned time to project from, and
  /// for stations the vehicle has already left.
  final DateTime? at;

  final EtaConfidence confidence;
}

/// The trip's stations in route order, plus everything derived from them.
///
/// Pure Dart and clock-injected: every method takes `now`, so the Captain App's
/// countdown, the Client's ETA list and the tests all agree by construction.
class StationBoard {
  const StationBoard(this.stations);

  const StationBoard.empty() : stations = const [];

  /// Ordered by `sequence`. The data layer sorts; nothing here re-sorts, so a
  /// mis-ordered board is a mapping bug rather than a silently different route.
  final List<TripStation> stations;

  bool get isEmpty => stations.isEmpty;
  bool get isNotEmpty => stations.isNotEmpty;

  /// The station the vehicle is standing at, if any.
  TripStation? get currentStation {
    for (final station in stations) {
      if (station.isCurrent) return station;
    }
    return null;
  }

  /// The station being driven towards — the first one not yet reached.
  TripStation? get nextStation {
    for (final station in stations) {
      if (!station.hasArrived) return station;
    }
    return null;
  }

  /// The station the captain is working right now: the one they are standing at,
  /// or the one they are driving to.
  TripStation? get focusStation => currentStation ?? nextStation;

  int get departedCount => stations.where((s) => s.hasDeparted).length;

  int get remainingCount => stations.length - departedCount;

  /// Stations the vehicle has yet to leave, in order.
  List<TripStation> get remaining =>
      stations.where((s) => !s.hasDeparted).toList(growable: false);

  TripStation? stationById(String id) {
    for (final station in stations) {
      if (station.id == id) return station;
    }
    return null;
  }

  /// The station a manifest pickup point resolves to. Matched on the route point
  /// id, falling back to the name for trips whose points predate that id being
  /// recorded — the same two-step match the database makes.
  TripStation? stationForPickup({String? routePointId, String? name}) {
    if (routePointId != null && routePointId.isNotEmpty) {
      for (final station in stations) {
        if (station.routePointId == routePointId) return station;
      }
    }
    final target = name?.trim();
    if (target == null || target.isEmpty) return null;
    for (final station in stations) {
      if (station.name.trim() == target) return station;
    }
    return null;
  }

  /// How far behind (or ahead of) plan the trip is running.
  ///
  /// Taken from the last station with both a planned and a real arrival, then
  /// extended if the vehicle is still standing somewhere it was already due to
  /// leave — a bus held ten minutes past its departure is ten minutes later than
  /// its last arrival said.
  Duration delayAt(DateTime now) {
    var delay = Duration.zero;
    for (final station in stations) {
      final actual = station.actualArrivalAt;
      final expected = station.expectedArrivalAt;
      if (actual != null && expected != null) {
        delay = actual.difference(expected);
      }
    }

    final current = currentStation;
    final due = current?.expectedDepartureAt;
    if (due != null) {
      final overrun = now.difference(due.add(delay));
      if (overrun > Duration.zero) delay += overrun;
    }
    return delay;
  }

  /// Whether any real arrival has been observed yet. Below that, every estimate
  /// is the published schedule and is labelled as such.
  bool get hasObservedProgress =>
      stations.any((s) => s.actualArrivalAt != null && s.expectedArrivalAt != null);

  /// An estimate for every station the vehicle has not left yet.
  ///
  /// Deliberately a projection of the plan rather than a GPS extrapolation: this
  /// is the estimate a rider who has already boarded receives, and they are no
  /// longer allowed to know where the vehicle is. Riders still waiting get the
  /// sharper GPS-derived numbers from `RouteProgressEngine` on top.
  List<StationEta> etas(DateTime now) {
    final delay = delayAt(now);
    final observed = hasObservedProgress;

    return [
      for (final station in stations)
        StationEta(
          station: station,
          at: station.hasDeparted || station.expectedArrivalAt == null
              ? null
              : _notBefore(station.expectedArrivalAt!.add(delay), station, now),
          confidence: station.hasDeparted
              ? EtaConfidence.none
              : station.expectedArrivalAt == null
              ? EtaConfidence.none
              : observed
              ? EtaConfidence.estimated
              : EtaConfidence.scheduled,
        ),
    ];
  }

  /// A station the vehicle is already standing at has arrived; projecting it
  /// into the future would be a lie. Everything else is at least "now".
  DateTime _notBefore(DateTime projected, TripStation station, DateTime now) {
    if (station.actualArrivalAt != null) return station.actualArrivalAt!;
    return projected.isBefore(now) ? now : projected;
  }

  /// The two-condition departure gate, evaluated for the station the vehicle is
  /// standing at.
  StationGate gateAt(DateTime now) {
    final station = currentStation;
    if (station == null) return const StationGate.notAtStation();

    final earliest = station.earliestDeparture;

    if (!station.boardingResolved) {
      return StationGate(
        state: StationGateState.waitingForPassengers,
        station: station,
        pendingCount: station.pendingCount,
        earliestDeparture: earliest,
      );
    }

    if (earliest != null && earliest.isAfter(now)) {
      return StationGate(
        state: StationGateState.waitingForDepartureTime,
        station: station,
        pendingCount: 0,
        earliestDeparture: earliest,
      );
    }

    return StationGate(
      state: StationGateState.ready,
      station: station,
      pendingCount: 0,
      earliestDeparture: earliest,
    );
  }
}
