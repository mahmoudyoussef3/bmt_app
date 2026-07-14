import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/tracking/data/datasources/tracking_datasource.dart';
import 'package:bmt_app/apps/client/features/tracking/data/repositories/tracking_repository_impl.dart';
import 'package:bmt_app/apps/client/features/tracking/domain/entities/tracking_trip.dart';
import 'package:bmt_app/apps/client/features/tracking/domain/usecases/get_tracking_trip_usecase.dart';
import 'package:bmt_app/apps/client/features/tracking/domain/usecases/watch_tracking_trip_usecase.dart';
import 'package:bmt_app/apps/client/features/tracking/domain/usecases/watch_vehicle_position_usecase.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/cubit/tracking_cubit.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/cubit/tracking_state.dart';
import 'package:bmt_app/core/tracking/progress/route_stop.dart';
import 'package:bmt_app/core/tracking/progress/stop_progress.dart';

void main() {
  group('TrackingCubit', () {
    test('emits empty — not a placeholder trip — when nothing is trackable', () async {
      final cubit = _cubit(_FakeDatasource(trip: const TrackingTripData.none()));

      await cubit.load();

      expect(cubit.state, isA<TrackingEmpty>());
      await cubit.close();
    });

    test('surfaces the real trip state from the operation', () async {
      final cubit = _cubit(
        _FakeDatasource(trip: _trip(state: TrackingTripState.inProgress)),
      );

      await cubit.load();

      expect((cubit.state as TrackingLoaded).tripState,
          TrackingTripState.inProgress);
      await cubit.close();
    });

    test(
      'seeds the progress engine from the captain-reported arrival count, so '
      'a confirmed station arrival shows up with no GPS fix at all',
      () async {
        final cubit = _cubit(
          _FakeDatasource(
            trip: _trip(
              state: TrackingTripState.inProgress,
              arrivalEventCount: 2,
            ),
          ),
        );

        await cubit.load();
        final progress = (cubit.state as TrackingLoaded).progress!;

        expect(progress.hasVehicleFix, isFalse);
        expect(progress.stops[0].status, StopVisitStatus.departed);
        expect(progress.stops[1].status, StopVisitStatus.arrived);
        expect(progress.stops[2].isVisited, isFalse);
        await cubit.close();
      },
    );

    test('a live fix promotes a not-started trip to driver-on-way', () async {
      final positions = StreamController<TrackingPoint>();
      final cubit = _cubit(
        _FakeDatasource(
          trip: _trip(state: TrackingTripState.notStarted),
          positions: positions.stream,
        ),
      );

      await cubit.load();
      expect((cubit.state as TrackingLoaded).tripState,
          TrackingTripState.notStarted);

      positions.add(
        TrackingPoint(
          latitude: 30.0,
          longitude: 31.0,
          recordedAt: DateTime.now(),
        ),
      );
      await Future<void>.delayed(Duration.zero);

      final loaded = cubit.state as TrackingLoaded;
      expect(loaded.tripState, TrackingTripState.driverOnWay);
      expect(loaded.data.vehicleFix, isNotNull);

      await positions.close();
      await cubit.close();
    });

    test('a failed refresh keeps the trip on screen instead of erroring out',
        () async {
      final datasource = _FakeDatasource(
        trip: _trip(state: TrackingTripState.inProgress),
      );
      final cubit = _cubit(datasource);

      await cubit.load();
      datasource.failNext = true;
      await cubit.refresh();

      // The rider is mid-journey: a transient fetch failure must not wipe the
      // route, the stops and the captain off their screen.
      expect(cubit.state, isA<TrackingLoaded>());
      expect((cubit.state as TrackingLoaded).isRefreshing, isFalse);
      await cubit.close();
    });

    test('reports an error when the very first load fails', () async {
      final datasource = _FakeDatasource(trip: const TrackingTripData.none())
        ..failNext = true;
      final cubit = _cubit(datasource);

      await cubit.load();

      expect(cubit.state, isA<TrackingError>());
      await cubit.close();
    });
  });
}

TrackingCubit _cubit(TrackingDatasource datasource) {
  final repository = TrackingRepositoryImpl(datasource);
  return TrackingCubit(
    getTrackingTrip: GetTrackingTripUseCase(repository),
    watchVehiclePosition: WatchVehiclePositionUseCase(repository),
    watchTrackingTrip: WatchTrackingTripUseCase(repository),
  );
}

TrackingTripData _trip({
  required TrackingTripState state,
  int arrivalEventCount = 0,
}) {
  return TrackingTripData(
    tripId: 'trip-1',
    bookingId: 'booking-1',
    tripState: state,
    arrivalEventCount: arrivalEventCount,
    stops: const [
      RouteStop(name: 'Banha', latitude: 30.46, longitude: 31.18, order: 0),
      RouteStop(name: 'Nasr City', latitude: 30.06, longitude: 31.34, order: 1),
      RouteStop(name: 'Smart Village', latitude: 30.07, longitude: 31.01, order: 2),
    ],
    captain: const TrackingCaptain(name: 'Mahmoud', rating: 4.8, ratingCount: 32),
  );
}

class _FakeDatasource implements TrackingDatasource {
  _FakeDatasource({required this.trip, Stream<TrackingPoint>? positions})
      : positions = positions ?? const Stream.empty();

  final TrackingTripData trip;
  final Stream<TrackingPoint> positions;
  bool failNext = false;

  @override
  Future<TrackingTripData> getTrackingTrip({
    String? bookingId,
    String? tripId,
  }) async {
    if (failNext) {
      failNext = false;
      throw Exception('network down');
    }
    return trip;
  }

  @override
  Stream<TrackingPoint> watchVehiclePosition(String tripId) => positions;

  @override
  Stream<void> watchTripChanges(String tripId) => const Stream.empty();
}
