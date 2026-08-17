import '../entities/fleet_feed.dart';
import '../entities/live_ops_snapshot.dart';
import '../entities/trip_incident.dart';

/// Read/act contract for the Live Operations Center. Office scoping is enforced
/// by RLS on the underlying tables, so callers never pass an office id.
abstract class LiveOpsRepository {
  /// Reads the current picture: trips on the road plus the open incident queue.
  Future<LiveOpsSnapshot> getSnapshot();

  /// Fires (with no payload) whenever operational data that affects the live
  /// picture changes — trip status flips or an incident is filed/updated. The
  /// cubit reacts by re-reading a fresh [getSnapshot]; the stream is a trigger,
  /// not a data source, mirroring the trips feature's `watchTripsChanges`.
  Stream<void> watchChanges();

  /// Live positions for the office's fleet, as values on one stream.
  ///
  /// Distinct from [watchChanges] on purpose: that one is a *trigger* saying the
  /// joined roster is stale, this one *carries* the data. A position must never
  /// cause a roster refetch — the roster does not change because a bus moved.
  Stream<FleetFeedEvent> watchFleetFixes();

  /// Latest position per active trip. Backfills the first paint and serves the
  /// catch-up poll that runs only while the realtime link is unhealthy.
  Future<Map<String, LiveFix>> fetchLatestFixes();

  /// Moves an incident to [next], optionally recording the operator's account
  /// of what was done. The legality of the move is decided in the domain
  /// ([IncidentStatus.canTransitionTo]) before this is ever called.
  Future<void> updateIncidentStatus({
    required String incidentId,
    required IncidentStatus next,
    String? note,
  });
}
