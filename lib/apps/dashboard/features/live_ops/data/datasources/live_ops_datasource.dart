import '../../domain/entities/fleet_feed.dart';
import '../../domain/entities/live_ops_snapshot.dart';
import '../../domain/entities/trip_incident.dart';
import '../models/live_trip_model.dart';
import '../models/trip_incident_model.dart';

abstract class LiveOpsDatasource {
  /// Trips currently `boarding` or `in_progress` for the signed-in office, each
  /// carrying its latest live fix (or none).
  Future<List<LiveTripModel>> fetchActiveTrips();

  /// Incident reports on this office's trips that have not been closed —
  /// `pending` and `acknowledged` alike, so a report stays visible while it is
  /// being worked.
  Future<List<TripIncidentModel>> fetchOpenIncidents();

  /// Trigger stream that fires when trip status or incidents change.
  ///
  /// Deliberately does **not** fire on position rows: those arrive on
  /// [watchFleetFixes] as values, not as a hint to refetch. Waking the whole
  /// roster query every time a bus moved is what made the board expensive.
  Stream<void> watchChanges();

  /// Live positions for every trip this office may watch, on one subscription.
  ///
  /// Fleet-wide rather than per-trip: an operator watches the whole road at once,
  /// and a socket per trip would churn on every departure and arrival.
  Stream<FleetFeedEvent> watchFleetFixes();

  /// Latest position per active trip, keyed by trip id.
  ///
  /// Two callers: the board's initial paint (so vehicles are on the map before
  /// the next INSERT rather than after it) and the catch-up poll that runs only
  /// while the socket is unhealthy.
  Future<Map<String, LiveFix>> fetchLatestFixes();

  /// Writes an incident's new lifecycle state, stamping the acting operator and
  /// the appropriate timestamp for [next].
  Future<void> updateIncidentStatus({
    required String incidentId,
    required IncidentStatus next,
    String? note,
  });
}
