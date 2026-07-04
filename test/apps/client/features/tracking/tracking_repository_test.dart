import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/tracking/data/datasources/supabase_tracking_datasource.dart';
import 'package:bmt_app/apps/client/features/tracking/data/models/tracking_trip_model.dart';
import 'package:bmt_app/apps/client/features/tracking/data/repositories/tracking_repository_impl.dart';
import 'package:bmt_app/apps/client/features/tracking/domain/entities/tracking_trip.dart';
import 'package:bmt_app/apps/client/features/tracking/domain/usecases/get_tracking_title_usecase.dart';
import 'package:bmt_app/apps/client/features/tracking/domain/usecases/get_tracking_trip_usecase.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/cubit/tracking_cubit.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/cubit/tracking_state.dart';
import 'package:bmt_app/apps/client/features/tracking/domain/usecases/watch_vehicle_position_usecase.dart';
import 'package:bmt_app/apps/client/features/tracking/domain/usecases/watch_tracking_trip_usecase.dart';

void main() {
  group('Client tracking', () {
    late TrackingRepositoryImpl repository;

    setUp(() {
      repository = const TrackingRepositoryImpl(_FakeTrackingDatasource());
    });

    test('returns tracking route points and timeline data', () async {
      final data = await GetTrackingTripUseCase(repository)();

      expect(data.routePoints, hasLength(9));
      expect(data.routePoints.first.latitude, 30.15);
      expect(data.timelineSteps, contains('Driver Assigned'));
      expect(data.stops.last, 'Smart Village');
    });

    test('maps trip states to display titles', () {
      const getTitle = GetTrackingTitleUseCase();

      expect(getTitle(TrackingTripState.notStarted), 'Trip Status');
      expect(getTitle(TrackingTripState.driverOnWay), 'Driver on the Way');
      expect(getTitle(TrackingTripState.completed), 'Trip Completed');
    });

    test('updates tracking state and ratings through cubit', () async {
      final cubit = TrackingCubit(
        getTrackingTrip: GetTrackingTripUseCase(repository),
        getTrackingTitle: const GetTrackingTitleUseCase(),
        watchVehiclePosition: WatchVehiclePositionUseCase(repository),
        watchTrackingTrip: WatchTrackingTripUseCase(repository),
      );

      await cubit.load();
      cubit.changeState(TrackingTripState.completed);
      cubit.rateDriver(5);
      cubit.rateVehicle(4);
      cubit.rateRoute(3);

      final state = cubit.state as TrackingLoaded;
      expect(state.currentState, TrackingTripState.completed);
      expect(state.title, 'Trip Completed');
      expect(state.ratings.driver, 5);
      expect(state.ratings.vehicle, 4);
      expect(state.ratings.route, 3);

      await cubit.close();
    });
  });
}

class _FakeTrackingDatasource implements TrackingDatasource {
  const _FakeTrackingDatasource();

  @override
  Future<TrackingTripDataModel> getTrackingTrip({
    String? bookingId,
    String? tripId,
  }) async {
    return const TrackingTripDataModel(
      routePoints: [
        TrackingPointModel(latitude: 30.15, longitude: 31.85),
        TrackingPointModel(latitude: 30.22, longitude: 31.72),
        TrackingPointModel(latitude: 30.35, longitude: 31.65),
        TrackingPointModel(latitude: 30.48, longitude: 31.58),
        TrackingPointModel(latitude: 30.55, longitude: 31.45),
        TrackingPointModel(latitude: 30.62, longitude: 31.38),
        TrackingPointModel(latitude: 30.72, longitude: 31.30),
        TrackingPointModel(latitude: 30.82, longitude: 31.22),
        TrackingPointModel(latitude: 30.90, longitude: 31.12),
      ],
      timelineSteps: [
        'Booking Confirmed',
        'Driver Assigned',
        'Driver Heading To Pickup',
        'Boarding Started',
        'Trip Started',
        'Trip Completed',
      ],
      stops: [
        'Banha Station',
        'Nasr City Station',
        'Heliopolis Station',
        'Smart Village',
      ],
      tripState: TrackingTripState.notStarted,
    );
  }

  @override
  Stream<TrackingPointModel> watchVehiclePosition(String tripId) {
    return const Stream.empty();
  }

  @override
  Stream<void> watchTripChanges(String tripId) => const Stream.empty();
}
