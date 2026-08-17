import 'package:bmt_app/core/tracking/link_health.dart';

import 'live_ops_snapshot.dart';

/// One thing happening on the office's fleet position feed.
///
/// The dashboard's feed differs from the client's in exactly one way: it is
/// **fleet-wide**. A rider watches one vehicle and subscribes to one trip; an
/// operator watches every vehicle the office has on the road, and subscribing per
/// trip would mean N sockets that churn every time a trip starts or ends. So one
/// subscription carries positions for every trip, and each event names its trip.
///
/// Positions and link health travel on a single stream for the same reason they do
/// on the client's: they come from one channel, and splitting them would cost a
/// second socket to express something the transport already knows in one place.
sealed class FleetFeedEvent {
  const FleetFeedEvent();
}

/// A position landed for [tripId].
class FleetFixReported extends FleetFeedEvent {
  const FleetFixReported({required this.tripId, required this.fix});

  final String tripId;
  final LiveFix fix;
}

/// The transport reporting on itself.
class FleetLinkChanged extends FleetFeedEvent {
  const FleetLinkChanged(this.link);

  final TrackingLink link;
}

/// One vehicle's live position as the board currently believes it.
///
/// [receivedAt] is when *this desk* accepted the fix, and freshness is measured
/// from it rather than from [LiveFix.recordedAt] — the same rule the client
/// applies, for the same reason: a captain's device with a skewed clock could
/// otherwise stamp a fix into the future and keep a dead feed looking alive
/// indefinitely.
class TrackedVehicle {
  const TrackedVehicle({required this.fix, required this.receivedAt});

  final LiveFix fix;
  final DateTime receivedAt;

  /// Health of this vehicle's feed at [now].
  ///
  /// Measured against [receivedAt], so a backfilled fix that was already old when
  /// the board loaded is not laundered into a fresh one. The seed path passes the
  /// fix's own recorded time as [receivedAt] precisely so this stays honest.
  TrackingHealth healthAt(DateTime now) {
    final age = now.difference(receivedAt);
    return TrackingHealth.fromFixAge(age.isNegative ? Duration.zero : age);
  }
}
