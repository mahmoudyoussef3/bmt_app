import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/features/live_trips/data/datasources/mock_live_trips_datasource.dart';
import 'package:bmt_app/apps/dashboard/features/live_trips/data/models/live_trip_model.dart';
import 'package:bmt_app/apps/dashboard/features/live_trips/data/repositories/live_trips_repository_impl.dart';
import 'package:bmt_app/apps/dashboard/features/live_trips/domain/entities/live_trip.dart';
import 'package:bmt_app/apps/dashboard/features/live_trips/domain/usecases/get_live_trips_usecase.dart';

void main() {
  group('Live trips clean architecture chain', () {
    test('loads active trips with monitoring data', () async {
      final repository = LiveTripsRepositoryImpl(MockLiveTripsDatasource());
      final getLiveTrips = GetLiveTripsUseCase(repository);

      final trips = await getLiveTrips();

      expect(trips, isNotEmpty);
      expect(trips.first.driver, 'كريم حسن');
      expect(trips.first.progress, greaterThan(0));
      expect(trips.first.timeline, isNotEmpty);
    });

    test('includes required alert types in dummy data', () async {
      final repository = LiveTripsRepositoryImpl(MockLiveTripsDatasource());
      final getLiveTrips = GetLiveTripsUseCase(repository);

      final alerts = (await getLiveTrips()).expand((trip) => trip.alerts);

      expect(
        alerts.map((alert) => alert.type),
        contains(LiveTripAlertType.delay),
      );
      expect(
        alerts.map((alert) => alert.type),
        contains(LiveTripAlertType.suddenStop),
      );
      expect(
        alerts.map((alert) => alert.type),
        contains(LiveTripAlertType.complaint),
      );
      expect(
        alerts.map((alert) => alert.type),
        contains(LiveTripAlertType.routeDeviation),
      );
    });

    test('maps datasource failures to Arabic repository error', () {
      final repository = LiveTripsRepositoryImpl(_FailingLiveTripsDatasource());
      final getLiveTrips = GetLiveTripsUseCase(repository);

      expect(
        getLiveTrips.call,
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('تعذر تحميل الرحلات المباشرة'),
          ),
        ),
      );
    });
  });
}

class _FailingLiveTripsDatasource implements LiveTripsDatasource {
  @override
  Future<List<LiveTripModel>> fetchLiveTrips() {
    throw StateError('failure');
  }
}
