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
