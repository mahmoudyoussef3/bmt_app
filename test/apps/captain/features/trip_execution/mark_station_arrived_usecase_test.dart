import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/captain/features/trip_execution/domain/entities/trip_execution_state.dart';
import 'package:bmt_app/apps/captain/features/trip_execution/domain/repositories/trip_execution_repository.dart';
import 'package:bmt_app/apps/captain/features/trip_execution/domain/usecases/mark_station_arrived_usecase.dart';

void main() {
  test('delegates the arrival to the repository, naming only the trip', () async {
    final repository = _FakeTripExecutionRepository();
    final useCase = MarkStationArrivedUseCase(repository);

    await useCase('trip-1');

    expect(repository.markedTripId, 'trip-1');
  });

  test('propagates repository failures instead of swallowing them', () {
    final repository = _FakeTripExecutionRepository()
      ..failure = Exception('تعذر الاتصال');
    final useCase = MarkStationArrivedUseCase(repository);

    expect(() => useCase('trip-1'), throwsA(isA<Exception>()));
  });
}

class _FakeTripExecutionRepository implements TripExecutionRepository {
  String? markedTripId;
  Object? failure;

  @override
  Future<void> markStationArrived(String tripId) async {
    if (failure case final error?) throw error;
    markedTripId = tripId;
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
  Stream<TripExecutionSnapshot> watchTripSnapshot({
    required String tripId,
    required int routePointCount,
  }) => throw UnimplementedError();
}
