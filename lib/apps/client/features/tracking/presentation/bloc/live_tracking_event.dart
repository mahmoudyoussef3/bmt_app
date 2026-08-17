import 'package:equatable/equatable.dart';

import '../../domain/entities/tracking_trip.dart';

/// What can happen to a live tracking session.
///
/// Each of these is a genuine occurrence with its own consequence, not a setter
/// with a verb in front of it: opening a feed, losing a socket, a position
/// landing, a position going stale, and a trip ending are five different things
/// that arrive from five different places (the screen, the transport, the
/// captain, a timer, the operation) and interleave in orders nobody chooses.
/// That is the reason this feature is a Bloc and the rest of the app is not — a
/// method call cannot express "these arrive concurrently and must be ordered".
sealed class LiveTrackingEvent extends Equatable {
  const LiveTrackingEvent();

  @override
  List<Object?> get props => const [];
}

/// Open (or re-target) the feed for a trip.
///
/// Carries the trip because the route progress engine is built from it — stops,
/// schedule, the captain's confirmed arrivals, and whether this rider is still
/// entitled to watch. Re-dispatching it for the same trip after a refetch
/// updates the engine's phase and arrival floor without rebuilding it, so a stop
/// already marked passed can never flicker back to upcoming.
class TrackingRequested extends LiveTrackingEvent {
  const TrackingRequested(this.trip);

  final TrackingTripData trip;

  @override
  List<Object?> get props => [trip.tripId, trip.tripState, trip.stops.length];
}

/// Release the feed — the rider left the screen, or boarded.
class TrackingStopped extends LiveTrackingEvent {
  const TrackingStopped();
}

/// A position arrived. The high-frequency one.
class VehicleFixReceived extends LiveTrackingEvent {
  const VehicleFixReceived(this.fix);

  final TrackingPoint fix;

  @override
  List<Object?> get props => [fix.latitude, fix.longitude, fix.recordedAt];
}

/// The transport reported on itself: socket up, degraded to catch-up polling, or
/// gone. Separate from a fix because a healthy link with no movement and a dead
/// link are different facts, and only one of them is the rider's problem.
class TrackingLinkReported extends LiveTrackingEvent {
  const TrackingLinkReported(this.link);

  final TrackingLink link;

  @override
  List<Object?> get props => [link];
}

/// Time passed; re-decide whether the last position can still be believed.
///
/// Exists as an event rather than a computed getter because going stale is a
/// *transition* the rider must be told about. Derived from receipt time, it
/// would otherwise only be noticed when some unrelated rebuild happened to
/// recompute it.
class TrackingFreshnessEvaluated extends LiveTrackingEvent {
  const TrackingFreshnessEvaluated();
}

/// The rider asking for another attempt after a failure.
class TrackingRetryRequested extends LiveTrackingEvent {
  const TrackingRetryRequested();
}

/// The trip ended. Terminal: there are no more positions to come, so holding the
/// feed open would cost a connection for nothing.
class TrackingFinished extends LiveTrackingEvent {
  const TrackingFinished();
}

/// The feed itself failed.
class TrackingFeedFailed extends LiveTrackingEvent {
  const TrackingFeedFailed(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
