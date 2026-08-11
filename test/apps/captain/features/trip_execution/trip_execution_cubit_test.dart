import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/captain/features/trip_execution/domain/entities/trip_execution_state.dart';
import 'package:bmt_app/apps/captain/features/trip_execution/domain/repositories/trip_execution_repository.dart';
import 'package:bmt_app/apps/captain/features/trip_execution/domain/usecases/complete_trip_usecase.dart';
import 'package:bmt_app/apps/captain/features/trip_execution/domain/usecases/mark_station_arrived_usecase.dart';
import 'package:bmt_app/apps/captain/features/trip_execution/domain/usecases/start_boarding_usecase.dart';
import 'package:bmt_app/apps/captain/features/trip_execution/domain/usecases/start_trip_usecase.dart';
import 'package:bmt_app/apps/captain/features/trip_execution/domain/usecases/watch_trip_execution_snapshot_usecase.dart';
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
      watchTripSnapshot: WatchTripExecutionSnapshotUseCase(repository),
      markStationArrived: MarkStationArrivedUseCase(repository),
    );
  });

  tearDown(() => cubit.close());

  test('board() transitions to boarding via the repository', () async {
    await cubit.board('trip-1');

    final state = cubit.state as TripExecutionIdle;
    expect(state.snapshot.status, TripExecutionStatus.boarding);
  });

  test(
    'markStationArrived persists the arrival through the repository instead '
    'of only updating local widget state — this is the regression the '
    'original bug (a bare setState with no backend call) would have failed',
    () async {
      await cubit.markStationArrived('trip-1');

      expect(repository.markedTripId, 'trip-1');
    },
  );

  test('markStationArrived does not disturb the board/start/complete state '
      'machine — it is an independent per-stop action', () async {
    await cubit.board('trip-1');
    final before = cubit.state;

    await cubit.markStationArrived('trip-1');

    expect(cubit.state, same(before));
  });

  test('markStationArrived rethrows repository failures to the caller', () {
    repository.failure = Exception('فشل الاتصال');

    expect(
      () => cubit.markStationArrived('trip-1'),
      throwsA(isA<Exception>()),
    );
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
  Stream<TripExecutionSnapshot> watchTripSnapshot({
    required String tripId,
    required int routePointCount,
  }) => const Stream.empty();
}
