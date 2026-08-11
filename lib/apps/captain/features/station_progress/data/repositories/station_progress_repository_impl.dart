import 'package:bmt_app/core/tracking/progress/station_board.dart';

import '../../domain/entities/station_passenger.dart';
import '../../domain/repositories/station_progress_repository.dart';
import '../datasources/station_progress_datasource.dart';

class StationProgressRepositoryImpl implements StationProgressRepository {
  const StationProgressRepositoryImpl(this._dataSource);

  final StationProgressDataSource _dataSource;

  @override
  Stream<StationBoard> watchBoard(String tripId) =>
      _dataSource.watchBoard(tripId);

  @override
  Future<void> arriveAtStation(String tripId) =>
      _dataSource.arriveAtStation(tripId);

  @override
  Future<void> departStation(String tripId) =>
      _dataSource.departStation(tripId);

  @override
  Future<void> resolveNoShow({
    required String passengerId,
    required NoShowReason reason,
    String? note,
  }) => _dataSource.resolveNoShow(
    passengerId: passengerId,
    reason: reason,
    note: note,
  );

  @override
  Future<List<StationPassenger>> passengersAt({
    required String tripId,
    String? routePointId,
    required String pointName,
  }) => _dataSource.passengersAt(
    tripId: tripId,
    routePointId: routePointId,
    pointName: pointName,
  );
}
