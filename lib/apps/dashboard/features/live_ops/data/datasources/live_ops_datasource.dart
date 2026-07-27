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
  Stream<void> watchChanges();

  /// Writes an incident's new lifecycle state, stamping the acting operator and
  /// the appropriate timestamp for [next].
  Future<void> updateIncidentStatus({
    required String incidentId,
    required IncidentStatus next,
    String? note,
  });
}
