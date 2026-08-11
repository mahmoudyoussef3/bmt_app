import 'package:bmt_app/core/tracking/progress/station_board.dart';

/// The single action the captain may take right now, and — when it is
/// unavailable — the reason, so the screen never shows a dead button with no
/// explanation.
///
/// Resolved by [resolveStationAction], which is a pure function of the board and
/// the clock. That is deliberate: it makes "can I leave?" a testable question
/// with no widget, no cubit and no network in the way, and it is the same
/// question `captain_depart_station` answers server-side.
sealed class StationAction {
  const StationAction();
}

/// The vehicle is driving to [station]; the captain reports reaching it.
class StationArriveAction extends StationAction {
  const StationArriveAction(this.station);

  final TripStation station;
}

/// The vehicle is standing at [station]. [gate] says whether it may leave and
/// what is holding it.
class StationDepartAction extends StationAction {
  const StationDepartAction({required this.station, required this.gate});

  final TripStation station;
  final StationGate gate;

  bool get isEnabled => gate.canDepart;
}

/// Every station has been left; what remains is ending the trip.
class StationFinishAction extends StationAction {
  const StationFinishAction();
}

/// This trip has no station board — it was created without route points, or the
/// board has not been built yet. The screen falls back to the trip-level
/// controls rather than trapping the captain behind a gate that cannot open.
class StationBoardUnavailable extends StationAction {
  const StationBoardUnavailable();
}

/// Which of the four situations the captain is in.
StationAction resolveStationAction(StationBoard board, DateTime now) {
  if (board.isEmpty) return const StationBoardUnavailable();

  final current = board.currentStation;
  if (current != null) {
    return StationDepartAction(station: current, gate: board.gateAt(now));
  }

  final next = board.nextStation;
  if (next != null) return StationArriveAction(next);

  return const StationFinishAction();
}
