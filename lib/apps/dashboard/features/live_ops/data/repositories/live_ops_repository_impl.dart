import '../../domain/entities/live_ops_snapshot.dart';
import '../../domain/entities/trip_incident.dart';
import '../../domain/repositories/live_ops_repository.dart';
import '../datasources/live_ops_datasource.dart';

class LiveOpsRepositoryImpl implements LiveOpsRepository {
  final LiveOpsDatasource _datasource;

  const LiveOpsRepositoryImpl(this._datasource);

  @override
  Future<LiveOpsSnapshot> getSnapshot() async {
    
    final results = await Future.wait([
      _datasource.fetchActiveTrips(),
      _datasource.fetchOpenIncidents(),
    ]);

    return LiveOpsSnapshot(
      activeTrips: results[0] as List<LiveTrip>,
      incidents: results[1] as List<TripIncident>,
      generatedAt: DateTime.now(),
    );
  }

  @override
  Stream<void> watchChanges() => _datasource.watchChanges();

  @override
  Future<void> updateIncidentStatus({
    required String incidentId,
    required IncidentStatus next,
    String? note,
  }) => _datasource.updateIncidentStatus(
    incidentId: incidentId,
    next: next,
    note: note,
  );
}
