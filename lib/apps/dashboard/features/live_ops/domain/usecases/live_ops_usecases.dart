import '../entities/fleet_feed.dart';
import '../entities/live_ops_snapshot.dart';
import '../entities/trip_incident.dart';
import '../repositories/live_ops_repository.dart';

class GetLiveOpsSnapshotUseCase {
  final LiveOpsRepository _repository;

  const GetLiveOpsSnapshotUseCase(this._repository);

  Future<LiveOpsSnapshot> call() => _repository.getSnapshot();
}

class WatchLiveOpsUseCase {
  final LiveOpsRepository _repository;

  const WatchLiveOpsUseCase(this._repository);

  Stream<void> call() => _repository.watchChanges();
}

/// The office's live position feed, and the health of the link carrying it.
///
/// The Bloc above this holds no Supabase client, opens no channel and names no
/// table; it receives [FleetFeedEvent]s and nothing else.
class WatchFleetFeedUseCase {
  final LiveOpsRepository _repository;

  const WatchFleetFeedUseCase(this._repository);

  Stream<FleetFeedEvent> call() => _repository.watchFleetFixes();
}

/// Latest known position per active trip.
///
/// Used to seed the board on open and to catch up while the socket is unhealthy —
/// never on a timer while it is healthy.
class GetLatestFleetFixesUseCase {
  final LiveOpsRepository _repository;

  const GetLatestFleetFixesUseCase(this._repository);

  Future<Map<String, LiveFix>> call() => _repository.fetchLatestFixes();
}

/// Thrown when a caller attempts a move the lifecycle does not allow — e.g.
/// resolving an already-dismissed report because two operators acted on the
/// same row before the queue refreshed.
class InvalidIncidentTransition implements Exception {
  final IncidentStatus from;
  final IncidentStatus to;

  const InvalidIncidentTransition(this.from, this.to);

  @override
  String toString() =>
      'لا يمكن نقل البلاغ من "${from.label}" إلى "${to.label}".';
}

/// Advances an incident through its lifecycle, refusing illegal moves.
///
/// The guard lives here rather than in the Cubit so the rule is enforced for
/// every caller, and in the domain rather than the datasource so it is testable
/// without a database. The database's CHECK constraint backs the *values*; this
/// backs the *transitions*, which SQL cannot express as cheaply.
class UpdateIncidentStatusUseCase {
  final LiveOpsRepository _repository;

  const UpdateIncidentStatusUseCase(this._repository);

  Future<void> call({
    required TripIncident incident,
    required IncidentStatus next,
    String? note,
  }) {
    if (!incident.status.canTransitionTo(next)) {
      throw InvalidIncidentTransition(incident.status, next);
    }
    return _repository.updateIncidentStatus(
      incidentId: incident.id,
      next: next,
      note: note,
    );
  }
}
