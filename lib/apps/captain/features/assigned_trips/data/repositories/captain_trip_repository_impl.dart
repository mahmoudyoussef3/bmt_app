import '../../domain/entities/assigned_trip.dart';
import '../../domain/repositories/captain_trip_repository.dart';
import '../datasources/captain_trip_remote_datasource.dart';

class CaptainTripRepositoryImpl implements CaptainTripRepository {
  const CaptainTripRepositoryImpl(this._dataSource);

  final CaptainTripRemoteDataSource _dataSource;

  @override
  Future<List<AssignedTrip>> getAssignedTrips() async {
    final models = await _dataSource.getAssignedTrips();
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Stream<void> watchTripUpdates() => _dataSource.watchTripUpdates();
}
