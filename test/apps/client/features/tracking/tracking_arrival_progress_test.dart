import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/core/tracking/progress/route_stop.dart';
import 'package:bmt_app/core/tracking/progress/stop_progress.dart';
import 'package:bmt_app/apps/client/features/tracking/data/datasources/supabase_tracking_datasource.dart';
import 'package:bmt_app/apps/client/features/tracking/data/models/tracking_trip_model.dart';
import 'package:bmt_app/apps/client/features/tracking/data/repositories/tracking_repository_impl.dart';
import 'package:bmt_app/apps/client/features/tracking/domain/entities/tracking_trip.dart';
import 'package:bmt_app/apps/client/features/tracking/domain/usecases/get_tracking_title_usecase.dart';
import 'package:bmt_app/apps/client/features/tracking/domain/usecases/get_tracking_trip_usecase.dart';
import 'package:bmt_app/apps/client/features/tracking/domain/usecases/watch_tracking_trip_usecase.dart';
import 'package:bmt_app/apps/client/features/tracking/domain/usecases/watch_vehicle_position_usecase.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/cubit/tracking_cubit.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/cubit/tracking_state.dart';

/// Proves the captain->client propagation gap described in the bug report:
/// the client's `RouteProgressEngine` must be seeded with the same
/// `trip_events` arrival-floor the Dashboard uses, not just GPS fixes, so a
/// captain-reported station arrival shows up in the rider's stop timeline
/// with no GPS fix required.
void main() {
  test(
    'seeds the route progress engine from the captain-reported arrival '
    'count, marking leading stations departed/arrived with no GPS fix',
    () async {
      final repository = TrackingRepositoryImpl(
        _FakeTrackingDatasource(arrivalEventCount: 2),
      );
      final cubit = TrackingCubit(
        getTrackingTrip: GetTrackingTripUseCase(repository),
        getTrackingTitle: const GetTrackingTitleUseCase(),
        watchVehiclePosition: WatchVehiclePositionUseCase(repository),
        watchTrackingTrip: WatchTrackingTripUseCase(repository),
      );

      await cubit.load();

      final state = cubit.state as TrackingLoaded;
      final stops = state.progress!.stops;

      expect(stops[0].status, StopVisitStatus.departed);
      expect(stops[1].status, StopVisitStatus.arrived);
      expect(stops[2].status, StopVisitStatus.next);
      expect(stops[3].status, StopVisitStatus.upcoming);

      await cubit.close();
    },
  );

  test(
    'a station arrival count of 0 leaves every stop upcoming/next '
    '(no false progress before the captain reports anything)',
    () async {
      final repository = TrackingRepositoryImpl(
        _FakeTrackingDatasource(arrivalEventCount: 0),
      );
      final cubit = TrackingCubit(
        getTrackingTrip: GetTrackingTripUseCase(repository),
        getTrackingTitle: const GetTrackingTitleUseCase(),
        watchVehiclePosition: WatchVehiclePositionUseCase(repository),
        watchTrackingTrip: WatchTrackingTripUseCase(repository),
      );

      await cubit.load();

      final state = cubit.state as TrackingLoaded;
      final stops = state.progress!.stops;

      expect(stops[0].status, StopVisitStatus.next);
      expect(stops.every((s) => s.status != StopVisitStatus.arrived), isTrue);
      expect(
        stops.every((s) => s.status != StopVisitStatus.departed),
        isTrue,
      );

      await cubit.close();
    },
  );
}

class _FakeTrackingDatasource implements TrackingDatasource {
  _FakeTrackingDatasource({required this.arrivalEventCount});

  final int arrivalEventCount;

  static const _routeStops = [
    RouteStop(id: 's1', name: 'Banha', latitude: 30.10, longitude: 31.10, order: 0),
    RouteStop(id: 's2', name: 'Shubra', latitude: 30.20, longitude: 31.20, order: 1),
    RouteStop(id: 's3', name: 'Ramsis', latitude: 30.30, longitude: 31.30, order: 2),
    RouteStop(id: 's4', name: 'Nasr City', latitude: 30.40, longitude: 31.40, order: 3),
  ];

  @override
  Future<TrackingTripDataModel> getTrackingTrip({
    String? bookingId,
    String? tripId,
  }) async {
    return TrackingTripDataModel(
      routePoints: const [
        TrackingPointModel(latitude: 30.10, longitude: 31.10),
        TrackingPointModel(latitude: 30.40, longitude: 31.40),
      ],
      timelineSteps: const ['Booking Confirmed', 'Trip Started'],
      stops: _routeStops.map((s) => s.name).toList(),
      tripState: TrackingTripState.inProgress,
      routeStops: _routeStops,
      arrivalEventCount: arrivalEventCount,
      tripId: 'trip-1',
    );
  }

  @override
  Stream<TrackingPointModel> watchVehiclePosition(String tripId) =>
      const Stream.empty();

  @override
  Stream<void> watchTripChanges(String tripId) => const Stream.empty();
}
