import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/tracking/data/datasources/mock_tracking_datasource.dart';
import 'package:bmt_app/apps/client/features/tracking/data/repositories/tracking_repository_impl.dart';
import 'package:bmt_app/apps/client/features/tracking/domain/entities/tracking_trip.dart';
import 'package:bmt_app/apps/client/features/tracking/domain/usecases/get_tracking_title_usecase.dart';
import 'package:bmt_app/apps/client/features/tracking/domain/usecases/get_tracking_trip_usecase.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/cubit/tracking_cubit.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/cubit/tracking_state.dart';

void main() {
  group('Client tracking', () {
    late TrackingRepositoryImpl repository;

    setUp(() {
      repository = const TrackingRepositoryImpl(MockTrackingDatasource());
    });

    test('returns tracking route points and timeline data', () async {
      final data = await GetTrackingTripUseCase(repository)();

      expect(data.routePoints, hasLength(9));
      expect(data.routePoints.first.x, 0.15);
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
