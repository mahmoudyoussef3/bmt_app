import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/captain/features/trip_execution/domain/entities/trip_execution_state.dart';
import 'package:bmt_app/apps/captain/features/trip_execution/domain/repositories/trip_execution_repository.dart';
import 'package:bmt_app/apps/captain/features/trip_execution/domain/usecases/complete_trip_usecase.dart';
import 'package:bmt_app/apps/captain/features/trip_execution/domain/usecases/mark_station_arrived_usecase.dart';
import 'package:bmt_app/apps/captain/features/trip_execution/domain/usecases/start_boarding_usecase.dart';
import 'package:bmt_app/apps/captain/features/trip_execution/domain/usecases/start_trip_usecase.dart';
import 'package:bmt_app/apps/captain/features/trip_execution/domain/usecases/watch_trip_execution_status_usecase.dart';
import 'package:bmt_app/apps/captain/features/trip_execution/presentation/cubit/trip_execution_cubit.dart';
import 'package:bmt_app/apps/captain/features/trip_execution/presentation/cubit/trip_execution_state.dart';

void main() {
  late _FakeTripExecutionRepository repository;
  late TripExecutionCubit cubit;

  setUp(() {
    repository = _FakeTripExecutionRepository();
    cubit = TripExecutionCubit(
      startBoarding: StartBoardingUseCase(repository),
      startTrip: StartTripUseCase(repository),
      completeTrip: CompleteTripUseCase(repository),
      watchTripStatus: WatchTripExecutionStatusUseCase(repository),
      markStationArrived: MarkStationArrivedUseCase(repository),
    );
  });

  tearDown(() => cubit.close());

  test('board() transitions to boarding via the repository', () async {
    await cubit.board('trip-1');

    final state = cubit.state as TripExecutionIdle;
    expect(state.status, TripExecutionStatus.boarding);
  });

  test(
    'markStationArrived persists the arrival through the repository instead '
    'of only updating local widget state — this is the regression the '
    'original bug (a bare setState with no backend call) would have failed',
    () async {
      await cubit.markStationArrived(
        tripId: 'trip-1',
        pointId: 'point-2',
        pointName: 'محطة بنها',
      );

      expect(repository.markedTripId, 'trip-1');
      expect(repository.markedPointId, 'point-2');
      expect(repository.markedPointName, 'محطة بنها');
    },
  );

  test(
    'markStationArrived does not disturb the board/start/complete state '
    'machine — it is an independent per-stop action',
    () async {
      await cubit.board('trip-1');
      final before = cubit.state;

      await cubit.markStationArrived(
        tripId: 'trip-1',
        pointId: 'point-1',
        pointName: 'محطة',
      );

      expect(cubit.state, same(before));
    },
  );

  test('markStationArrived rethrows repository failures to the caller', () {
    repository.failure = Exception('فشل الاتصال');

    expect(
      () => cubit.markStationArrived(
        tripId: 'trip-1',
        pointId: 'point-1',
        pointName: 'محطة',
      ),
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
  Future<TripExecutionStateData> startBoarding(String tripId) async {
    return TripExecutionStateData(
      tripId: tripId,
      status: TripExecutionStatus.boarding,
    );
  }

  @override
  Future<TripExecutionStateData> startTrip(String tripId) async {
    return TripExecutionStateData(
      tripId: tripId,
      status: TripExecutionStatus.inProgress,
    );
  }

  @override
  Future<TripExecutionStateData> completeTrip(String tripId) async {
    return TripExecutionStateData(
      tripId: tripId,
      status: TripExecutionStatus.completed,
    );
  }

  @override
  Stream<TripExecutionStatus> watchTripStatus(String tripId) =>
      const Stream.empty();
}
