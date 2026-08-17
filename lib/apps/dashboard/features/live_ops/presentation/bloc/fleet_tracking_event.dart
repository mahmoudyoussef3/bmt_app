import 'package:equatable/equatable.dart';

import 'package:bmt_app/core/tracking/link_health.dart';

import '../../domain/entities/live_ops_snapshot.dart';

sealed class FleetTrackingEvent extends Equatable {
  const FleetTrackingEvent();

  @override
  List<Object?> get props => const [];
}

/// Open the office's position feed. Idempotent — issuing it twice does not open
/// a second subscription.
class FleetTrackingStarted extends FleetTrackingEvent {
  const FleetTrackingStarted();
}

/// The roster changed: these are the trips currently on the road.
///
/// Carries the trips rather than just their ids because it does double duty —
/// it tells the board which vehicles to draw, *and* it seeds their last known
/// positions from the snapshot's backfill so the map is populated on first paint
/// instead of empty until the next INSERT arrives.
class FleetTripsChanged extends FleetTrackingEvent {
  const FleetTripsChanged(this.trips);

  final List<LiveTrip> trips;

  @override
  List<Object?> get props => [trips.map((t) => t.id).join(',')];
}

/// A position landed — the high-frequency event.
class FleetFixReceived extends FleetTrackingEvent {
  const FleetFixReceived({required this.tripId, required this.fix});

  final String tripId;
  final LiveFix fix;

  @override
  List<Object?> get props => [
    tripId,
    fix.latitude,
    fix.longitude,
    fix.recordedAt,
  ];
}

/// The transport reporting on its own health.
class FleetLinkReported extends FleetTrackingEvent {
  const FleetLinkReported(this.link);

  final TrackingLink link;

  @override
  List<Object?> get props => [link];
}

/// Time passed: re-decide which vehicles' positions can still be believed.
class FleetFreshnessEvaluated extends FleetTrackingEvent {
  const FleetFreshnessEvaluated();
}

/// Catch-up read, issued only while the link is unhealthy.
class FleetCatchUpRequested extends FleetTrackingEvent {
  const FleetCatchUpRequested();
}

/// The feed itself fell over.
class FleetFeedFailed extends FleetTrackingEvent {
  const FleetFeedFailed(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

/// The operator asking again after a failure.
class FleetTrackingRetryRequested extends FleetTrackingEvent {
  const FleetTrackingRetryRequested();
}

/// The board closed.
class FleetTrackingStopped extends FleetTrackingEvent {
  const FleetTrackingStopped();
}
