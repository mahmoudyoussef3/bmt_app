import '../../domain/entities/trip_execution_state.dart';
import '../../domain/repositories/trip_execution_repository.dart';
import '../datasources/trip_execution_datasource.dart';

class TripExecutionRepositoryImpl implements TripExecutionRepository {
  const TripExecutionRepositoryImpl(this._dataSource);

  final TripExecutionDataSource _dataSource;

  @override
  Future<TripExecutionStateData> startBoarding(String tripId) async {
    return (await _dataSource.startBoarding(tripId)).toEntity();
  }

  @override
  Future<TripExecutionStateData> startTrip(String tripId) async {
    return (await _dataSource.startTrip(tripId)).toEntity();
  }

  @override
  Future<TripExecutionStateData> completeTrip(String tripId) async {
    return (await _dataSource.completeTrip(tripId)).toEntity();
  }

  @override
  Stream<TripExecutionSnapshot> watchTripSnapshot({
    required String tripId,
    required int routePointCount,
  }) => _dataSource.watchSnapshot(
    tripId: tripId,
    routePointCount: routePointCount,
  );

  @override
  Future<void> markStationArrived({
    required String tripId,
    required String pointId,
    required String pointName,
  }) => _dataSource.markStationArrived(
    tripId: tripId,
    pointId: pointId,
    pointName: pointName,
  );
}
