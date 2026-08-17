import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/trip_incident.dart';
import '../../domain/usecases/live_ops_usecases.dart';
import 'live_ops_state.dart';

/// Drives the Live Operations Center's **roster**: which trips are on the road,
/// and the open incident queue.
///
/// It deliberately does *not* own positions. Those live in [FleetTrackingBloc],
/// which receives them as values over one realtime subscription. Until that split
/// this cubit refetched the entire snapshot — two joined queries plus the fixes
/// RPC — every 15 seconds, because moving a marker was the only way to move a
/// marker. Every one of those refetches also replaced the whole state object, so
/// a bus travelling 200 metres rebuilt the incident queue.
///
/// What is left here is genuinely request/response work, which is why it stays a
/// Cubit while the feed is a Bloc:
///  - a realtime trigger ([WatchLiveOpsUseCase]) that refreshes the instant a
///    trip status flips or an incident is filed — this is what makes the roster
///    feel immediate, and
///  - a slow poll ([pollInterval]) that is now purely a safety net for anything
///    the socket missed, no longer the mechanism that animates the board.
///
/// Neither path ever blanks a good screen: a failed refresh keeps the last
/// snapshot on screen. Only the very first load can surface a full error state.
class LiveOpsCubit extends Cubit<LiveOpsState> {
  final GetLiveOpsSnapshotUseCase _getSnapshot;
  final WatchLiveOpsUseCase _watch;
  final UpdateIncidentStatusUseCase _updateIncident;

  StreamSubscription<void>? _sub;
  Timer? _poll;
  bool _refreshing = false;

  LiveOpsCubit({
    required GetLiveOpsSnapshotUseCase getSnapshot,
    required WatchLiveOpsUseCase watch,
    required UpdateIncidentStatusUseCase updateIncident,
  }) : _getSnapshot = getSnapshot,
       _watch = watch,
       _updateIncident = updateIncident,
       super(const LiveOpsLoading());

  /// Public so the screen can *state* the cadence it refreshes at instead of
  /// repeating the number in a string that would quietly drift from the timer.
  ///
  /// Two minutes, not the 15 seconds this was when the same timer also had to
  /// fetch positions. Roster changes already arrive over realtime the moment they
  /// happen; this is the backstop for a missed socket message, and at 15s it was
  /// re-running two joined queries per desk 240 times an hour to learn nothing.
  static const Duration pollInterval = Duration(minutes: 2);

  Future<void> startWatching() async {
    await load();
    _sub?.cancel();
    _sub = _watch().listen((_) => _refresh(), onError: (_) {});
    _poll?.cancel();
    _poll = Timer.periodic(pollInterval, (_) => _refresh());
  }

  Future<void> load() async {
    emit(const LiveOpsLoading());
    try {
      emit(LiveOpsLoaded(snapshot: await _getSnapshot()));
    } catch (e) {
      emit(LiveOpsError(_clean(e)));
    }
  }

  /// Operator-triggered refresh from the header. Silent by design — it reuses
  /// the background path so a manual tap never blanks the screen with a spinner.
  Future<void> refresh() => _refresh();

  /// Silent background refresh. A transient failure is swallowed so a dropped
  /// socket or a single failed poll never tears down a working screen.
  Future<void> _refresh() async {
    if (_refreshing || isClosed) return;
    _refreshing = true;
    try {
      final snapshot = await _getSnapshot();
      if (!isClosed) {
        final current = state;
        emit(
          LiveOpsLoaded(
            snapshot: snapshot,

            selectedTripId: current is LiveOpsLoaded
                ? current.selectedTripId
                : null,
          ),
        );
      }
    } catch (_) {
    } finally {
      _refreshing = false;
    }
  }

  /// Focuses a trip on the map, or clears the focus when [tripId] is null or
  /// already selected (tapping the same trip twice zooms back out).
  void selectTrip(String? tripId) {
    final current = state;
    if (current is! LiveOpsLoaded) return;

    final next = (tripId == null || tripId == current.selectedTripId)
        ? null
        : tripId;
    if (next == current.selectedTripId) return;

    emit(
      next == null
          ? current.copyWith(clearSelection: true)
          : current.copyWith(selectedTripId: next),
    );
  }

  /// Moves an incident through its lifecycle. Returns an error message on
  /// failure, or `null` on success.
  ///
  /// Illegal transitions are rejected by the use case before any write, which is
  /// what protects a shared desk: if a colleague resolved the report while this
  /// operator's queue was stale, the second action fails with an explanation
  /// instead of silently overwriting the first.
  Future<String?> updateIncident(
    TripIncident incident,
    IncidentStatus next, {
    String? note,
  }) async {
    try {
      await _updateIncident(incident: incident, next: next, note: note);
      await _refresh();
      return null;
    } catch (e) {
      final message = _clean(e);
      final current = state;
      if (current is LiveOpsLoaded) {
        emit(current.copyWith(actionError: message));
      }
      return message;
    }
  }

  String _clean(Object e) => e.toString().replaceAll('Exception: ', '');

  @override
  Future<void> close() {
    _sub?.cancel();
    _poll?.cancel();
    return super.close();
  }
}
