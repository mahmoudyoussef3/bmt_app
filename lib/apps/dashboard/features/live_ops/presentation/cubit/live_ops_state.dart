import '../../domain/entities/live_ops_snapshot.dart';

sealed class LiveOpsState {
  const LiveOpsState();
}

class LiveOpsLoading extends LiveOpsState {
  const LiveOpsLoading();
}

class LiveOpsError extends LiveOpsState {
  final String message;
  const LiveOpsError(this.message);
}

class LiveOpsLoaded extends LiveOpsState {
  final LiveOpsSnapshot snapshot;

  /// Non-fatal action feedback (e.g. a failed "resolve") surfaced without
  /// blanking the live picture.
  final String? actionError;

  /// The trip the operator is focused on — highlighted on the map and in the
  /// list, and the target of the map's follow camera. `null` means "show
  /// everything", the default the screen returns to when a selected trip ends.
  final String? selectedTripId;

  const LiveOpsLoaded({
    required this.snapshot,
    this.actionError,
    this.selectedTripId,
  });

  /// The selected trip, or `null` when nothing is selected *or* the selected
  /// trip has left the active set (it completed, or the operator's office
  /// changed). Resolving through the snapshot rather than trusting the stored id
  /// is what keeps a stale selection from surviving a refresh.
  LiveTrip? get selectedTrip {
    final id = selectedTripId;
    if (id == null) return null;
    for (final trip in snapshot.activeTrips) {
      if (trip.id == id) return trip;
    }
    return null;
  }

  /// [actionError] is deliberately *not* carried forward when omitted: it is a
  /// one-shot message, and a sticky one would re-fire the snackbar on every
  /// poll. [selectedTripId] is carried forward, because the operator's focus
  /// must survive a background refresh.
  LiveOpsLoaded copyWith({
    LiveOpsSnapshot? snapshot,
    String? actionError,
    String? selectedTripId,
    bool clearSelection = false,
  }) {
    return LiveOpsLoaded(
      snapshot: snapshot ?? this.snapshot,
      actionError: actionError,
      selectedTripId: clearSelection
          ? null
          : (selectedTripId ?? this.selectedTripId),
    );
  }
}
