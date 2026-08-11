import 'station_board.dart';
import 'stop_progress.dart';

/// Lays the server's station board over the GPS-inferred stop timeline.
///
/// The two describe the same stops from different angles, and neither alone is
/// enough:
///
///   * `RouteProgressEngine` infers state from where the vehicle *is*. It is
///     sharp while GPS is flowing, and it is the only source of a live ETA — but
///     it is inference, and a rider who has boarded is no longer allowed to see
///     the positions it runs on.
///   * `trip_station_progress` records what the captain actually did. It is fact
///     rather than inference, it survives the rider losing GPS access, and it is
///     the same record the captain is looking at.
///
/// So: **fact wins over inference for state**, and **live wins over projected
/// for ETA, when the rider is still allowed a live one**. A stop the captain has
/// marked departed reads as departed even if no fix ever put the bus near it; a
/// stop the engine thinks was passed but the board says is still ahead reads as
/// ahead, because the captain has not left it.
///
/// Pure, and clock-injected, so the merge is testable without either engine.
List<StopProgress> overlayStationBoard({
  required List<StopProgress> inferred,
  required StationBoard board,
  required DateTime now,
  bool preferLiveEta = true,
}) {
  if (board.isEmpty || inferred.isEmpty) return inferred;

  final etas = {for (final eta in board.etas(now)) eta.station.id: eta};
  final merged = <StopProgress>[];

  for (var index = 0; index < inferred.length; index++) {
    final stop = inferred[index];
    final station = _match(board, stop, index);

    if (station == null) {
      merged.add(stop);
      continue;
    }

    final status = _statusFor(station, stop.status);
    final projected = etas[station.id];

    // A visited stop has no ETA — it has a time it happened, which the timeline
    // shows separately. Clearing it here stops "arriving at 08:42" surviving on
    // a stop the bus left twenty minutes ago.
    final visited =
        status == StopVisitStatus.departed || status == StopVisitStatus.arrived;

    merged.add(
      StopProgress(
        stop: stop.stop,
        status: status,
        remainingMeters: visited ? null : stop.remainingMeters,
        eta: visited
            ? null
            : _eta(stop: stop, projected: projected, preferLive: preferLiveEta),
        etaConfidence: visited
            ? EtaConfidence.none
            : _confidence(
                stop: stop,
                projected: projected,
                preferLive: preferLiveEta,
              ),
      ),
    );
  }

  return merged;
}

/// Board rows and inferred stops are both in route order, so position is the
/// primary match. The id and name are checked as a guard: a trip whose points
/// were re-sequenced after the board was built would otherwise silently pair a
/// stop with the wrong station, which is worse than not overlaying at all.
TripStation? _match(StationBoard board, StopProgress stop, int index) {
  if (index >= board.stations.length) return null;
  final candidate = board.stations[index];

  final stopId = stop.stop.id;
  if (stopId != null && candidate.routePointId != null) {
    if (candidate.routePointId == stopId) return candidate;
  }
  if (candidate.name.trim() == stop.stop.name.trim()) return candidate;

  return board.stationForPickup(name: stop.stop.name);
}

/// The board is authoritative about arrival and departure. `next` stays a
/// derived, presentational notion and is left to the engine.
StopVisitStatus _statusFor(TripStation station, StopVisitStatus inferred) {
  if (station.hasDeparted) return StopVisitStatus.departed;
  if (station.hasArrived) return StopVisitStatus.arrived;
  if (station.status == TripStationStatus.arriving) return StopVisitStatus.next;
  return inferred == StopVisitStatus.departed ||
          inferred == StopVisitStatus.arrived
      // The engine thinks the bus has been here; the captain says otherwise, and
      // the captain is the one who was there.
      ? StopVisitStatus.next
      : inferred;
}

DateTime? _eta({
  required StopProgress stop,
  required StationEta? projected,
  required bool preferLive,
}) {
  if (preferLive && stop.eta != null && stop.etaConfidence != EtaConfidence.none) {
    return stop.eta;
  }
  return projected?.at ?? stop.eta;
}

EtaConfidence _confidence({
  required StopProgress stop,
  required StationEta? projected,
  required bool preferLive,
}) {
  if (preferLive && stop.eta != null && stop.etaConfidence != EtaConfidence.none) {
    return stop.etaConfidence;
  }
  return projected?.confidence ?? stop.etaConfidence;
}
