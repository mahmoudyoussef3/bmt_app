import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/captain/features/trip_execution/domain/entities/trip_execution_state.dart';
import 'package:bmt_app/apps/captain/features/trip_execution/domain/repositories/trip_execution_repository.dart';
import 'package:bmt_app/apps/captain/features/trip_execution/domain/usecases/mark_station_arrived_usecase.dart';

void main() {
  test('delegates the arrival to the repository with the right arguments', () async {
    final repository = _FakeTripExecutionRepository();
    final useCase = MarkStationArrivedUseCase(repository);

    await useCase(tripId: 'trip-1', pointId: 'point-2', pointName: 'محطة بنها');

    expect(repository.markedTripId, 'trip-1');
    expect(repository.markedPointId, 'point-2');
    expect(repository.markedPointName, 'محطة بنها');
  });

  test('propagates repository failures instead of swallowing them', () {
    final repository = _FakeTripExecutionRepository()
      ..failure = Exception('تعذر الاتصال');
    final useCase = MarkStationArrivedUseCase(repository);

    expect(
      () => useCase(tripId: 'trip-1', pointId: 'point-2', pointName: 'محطة'),
      throwsA(isA<Exception>()),
    );
  });
}

class _FakeTripExecutionRepository implements TripExecutionRepository {
  String? markedTripId;
  String? markedPointId;
  String? markedPointName;
  Object? failure;

  @override
  Future<void> markStationArrived({
    required String tripId,
    required String pointId,
    required String pointName,
  }) async {
    if (failure case final error?) throw error;
    markedTripId = tripId;
    markedPointId = pointId;
    markedPointName = pointName;
  }

  @override
  Future<TripExecutionStateData> startBoarding(String tripId) =>
      throw UnimplementedError();

  @override
  Future<TripExecutionStateData> startTrip(String tripId) =>
      throw UnimplementedError();

  @override
  Future<TripExecutionStateData> completeTrip(String tripId) =>
      throw UnimplementedError();

  @override
  Stream<TripExecutionStatus> watchTripStatus(String tripId) =>
      throw UnimplementedError();
}
