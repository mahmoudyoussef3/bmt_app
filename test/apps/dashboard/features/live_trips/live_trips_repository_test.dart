import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/features/live_trips/data/datasources/live_trips_datasource.dart';
import 'package:bmt_app/apps/dashboard/features/live_trips/data/repositories/live_trips_repository_impl.dart';
import 'package:bmt_app/apps/dashboard/features/live_trips/domain/entities/live_trip.dart';
import 'package:bmt_app/apps/dashboard/features/live_trips/domain/usecases/get_live_trips_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/live_trips/domain/usecases/toggle_passenger_checkin_usecase.dart';

import 'fake_live_trips_datasource.dart';

void main() {
  group('Live trips clean architecture chain', () {
    test('loads active trips with monitoring data', () async {
      final repository = LiveTripsRepositoryImpl(FakeLiveTripsDatasource());
      final getLiveTrips = GetLiveTripsUseCase(repository);

      final trips = await getLiveTrips();

      expect(trips, isNotEmpty);
      expect(trips.first.driverName, 'محمد أحمد');
      expect(trips.first.progressPercent, greaterThan(0));
      expect(trips.first.routePoints, isNotEmpty);
    });

    test('includes required alert types in dummy data', () async {
      final repository = LiveTripsRepositoryImpl(FakeLiveTripsDatasource());
      final getLiveTrips = GetLiveTripsUseCase(repository);

      final alerts = (await getLiveTrips()).expand((trip) => trip.alerts);

      expect(
        alerts.map((alert) => alert.type),
        contains(LiveTripAlertType.delay),
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

    test('toggles passenger checkin status and recalculates counts', () async {
      final repository = LiveTripsRepositoryImpl(FakeLiveTripsDatasource());
      final getLiveTrips = GetLiveTripsUseCase(repository);

      final trips = await getLiveTrips();
      final targetTrip = trips.first;
      final targetPassenger = targetTrip.passengers.firstWhere(
        (p) => !p.checkedIn,
      );
      final initialCheckedInCountInList = targetTrip.passengers
          .where((p) => p.checkedIn)
          .length;

      final togglePassengerCheckin = TogglePassengerCheckinUseCase(repository);
      final updatedTrip = await togglePassengerCheckin(
        targetTrip.id,
        targetPassenger.id,
      );

      final updatedPassenger = updatedTrip.passengers.firstWhere(
        (p) => p.id == targetPassenger.id,
      );
      expect(updatedPassenger.checkedIn, true);
      expect(
        updatedTrip.checkedInPassengersCount,
        initialCheckedInCountInList + 1,
      );
      expect(
        updatedTrip.missingPassengersCount,
        targetTrip.passengers.length - (initialCheckedInCountInList + 1),
      );
    });
  });
}

class _FailingLiveTripsDatasource implements LiveTripsDatasource {
  @override
  Future<List<LiveTrip>> getLiveTrips() {
    throw StateError('failure');
  }

  @override
  Future<LiveTrip> getLiveTripDetails(String tripId) =>
      throw UnimplementedError();

  @override
  Future<LiveTrip> startTrip(String tripId) => throw UnimplementedError();

  @override
  Future<LiveTrip> pauseTrip(String tripId) => throw UnimplementedError();

  @override
  Future<LiveTrip> resumeTrip(String tripId) => throw UnimplementedError();

  @override
  Future<LiveTrip> completeTrip(String tripId) => throw UnimplementedError();

  @override
  Future<LiveTrip> markPointArrived(String tripId, String pointId) =>
      throw UnimplementedError();

  @override
  Future<LiveTrip> markPointCompleted(String tripId, String pointId) =>
      throw UnimplementedError();

  @override
  Future<LiveTrip> skipPoint(String tripId, String pointId) =>
      throw UnimplementedError();

  @override
  Future<LiveTrip> resolveAlert(String tripId, String alertId) =>
      throw UnimplementedError();

  @override
  Future<LiveTrip> reportAlert({
    required String tripId,
    required LiveTripAlertType type,
    required LiveTripAlertSeverity severity,
    required String title,
    required String message,
  }) => throw UnimplementedError();

  @override
  Future<String> callDriver(String driverPhone) => throw UnimplementedError();

  @override
  Future<String> sendDriverMessage(String driverPhone, String message) =>
      throw UnimplementedError();

  @override
  Future<LiveTrip> togglePassengerCheckin(String tripId, String passengerId) =>
      throw UnimplementedError();

  @override
  Stream<VehiclePosition> watchVehiclePosition(String tripId) =>
      throw UnimplementedError();
}
