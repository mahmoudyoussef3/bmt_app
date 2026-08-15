import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/trip_incident.dart';
import '../../domain/usecases/live_ops_usecases.dart';
import 'live_ops_state.dart';

/// Drives the Live Operations Center.
///
/// Freshness comes from two independent sources, matching the resilient pattern
/// the client tracking layer uses:
///  - a realtime trigger ([WatchLiveOpsUseCase]) that refreshes the instant a
///    trip status flips or an incident is filed, and
///  - a steady poll ([pollInterval]) that both catches anything the socket
///    missed and re-stamps the snapshot clock so tracking-health badges age
///    correctly even when nothing else changes.
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
  static const Duration pollInterval = Duration(seconds: 15);

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
