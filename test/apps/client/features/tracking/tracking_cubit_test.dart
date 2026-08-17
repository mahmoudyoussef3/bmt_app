import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/tracking/domain/entities/tracking_trip.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/cubit/tracking_state.dart';
import 'package:bmt_app/core/tracking/progress/route_stop.dart';

import 'tracking_test_harness.dart';

/// `TrackingCubit` after the split: it owns the trip *document* and the boarding
/// action. Positions, freshness, link health and route progress moved to
/// `LiveTrackingBloc` — see `live_tracking_bloc_test.dart`.
void main() {
  group('TrackingCubit', () {
    test('emits empty — not a placeholder trip — when nothing is trackable', () async {
      final cubit = buildTrackingCubit(
        FakeTrackingDatasource(trip: const TrackingTripData.none()),
      );

      await cubit.load();

      expect(cubit.state, isA<TrackingEmpty>());
      await cubit.close();
    });

    test('surfaces the real trip state from the operation', () async {
      final cubit = buildTrackingCubit(
        FakeTrackingDatasource(trip: _trip(state: TrackingTripState.inProgress)),
      );

      await cubit.load();

      expect((cubit.state as TrackingLoaded).tripState,
          TrackingTripState.inProgress);
      await cubit.close();
    });

    test('a failed refresh keeps the trip on screen instead of erroring out',
        () async {
      final datasource = FakeTrackingDatasource(
        trip: _trip(state: TrackingTripState.inProgress),
      );
      final cubit = buildTrackingCubit(datasource);

      await cubit.load();
      datasource.failNextFetch = true;
      await cubit.refresh();

      // The rider is mid-journey: a transient fetch failure must not wipe the
      // route, the stops and the captain off their screen.
      expect(cubit.state, isA<TrackingLoaded>());
      expect((cubit.state as TrackingLoaded).isRefreshing, isFalse);
      await cubit.close();
    });

    test('reports an error when the very first load fails', () async {
      final datasource = FakeTrackingDatasource(
        trip: const TrackingTripData.none(),
      )..failNextFetch = true;
      final cubit = buildTrackingCubit(datasource);

      await cubit.load();

      expect(cubit.state, isA<TrackingError>());
      await cubit.close();
    });

    group('noteVehicleMoving', () {
      test('promotes a not-started trip to driver-on-way', () async {
        final cubit = buildTrackingCubit(
          FakeTrackingDatasource(
            trip: _trip(state: TrackingTripState.notStarted),
          ),
        );
        await cubit.load();

        cubit.noteVehicleMoving();

        expect(
          (cubit.state as TrackingLoaded).tripState,
          TrackingTripState.driverOnWay,
          reason:
              'the bus is demonstrably moving; telling the rider it has not set '
              'off would be worse than the record being a few minutes behind',
        );
        await cubit.close();
      });

      test('leaves a trip the operation has already advanced alone', () async {
        final cubit = buildTrackingCubit(
          FakeTrackingDatasource(
            trip: _trip(state: TrackingTripState.inProgress),
          ),
        );
        await cubit.load();

        cubit.noteVehicleMoving();

        expect(
          (cubit.state as TrackingLoaded).tripState,
          TrackingTripState.inProgress,
          reason: 'a live fix must never walk the operation\'s state backwards',
        );
        await cubit.close();
      });
    });
  });
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
