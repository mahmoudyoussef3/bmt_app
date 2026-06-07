import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/features/trips/data/datasources/mock_trips_datasource.dart';
import 'package:bmt_app/apps/dashboard/features/trips/data/models/operation_trip_model.dart';
import 'package:bmt_app/apps/dashboard/features/trips/data/repositories/trips_repository_impl.dart';
import 'package:bmt_app/apps/dashboard/features/trips/domain/entities/operation_trip.dart';
import 'package:bmt_app/apps/dashboard/features/trips/domain/usecases/get_operation_trips_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/trips/domain/usecases/update_trip_status_usecase.dart';

void main() {
  group('Trips clean architecture chain', () {
    test('loads operation trips for Kanban board', () async {
      final repository = TripsRepositoryImpl(MockTripsDatasource());
      final getTrips = GetOperationTripsUseCase(repository);

      final trips = await getTrips();

      expect(trips, isNotEmpty);
      expect(
        trips.map((trip) => trip.status),
        contains(OperationTripStatus.inProgress),
      );
      expect(
        trips.first.events.map((event) => event.title),
        contains('Created'),
      );
      expect(trips.first.passengers, isNotEmpty);
    });

    test('moves trip between statuses locally', () async {
      final repository = TripsRepositoryImpl(MockTripsDatasource());
      final getTrips = GetOperationTripsUseCase(repository);
      final updateStatus = UpdateTripStatusUseCase(repository);

      final trip = (await getTrips()).first;
      final updated = await updateStatus(
        trip.id,
        OperationTripStatus.completed,
      );

      expect(updated.status, OperationTripStatus.completed);
      expect(updated.events.first.description, contains('مكتملة'));
    });

    test('maps datasource failures to Arabic repository error', () {
      final repository = TripsRepositoryImpl(_FailingTripsDatasource());
      final getTrips = GetOperationTripsUseCase(repository);

      expect(
        getTrips.call,
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('تعذر تحميل الرحلات'),
          ),
        ),
      );
    });
  });
}

class _FailingTripsDatasource implements TripsDatasource {
  @override
  Future<List<OperationTripModel>> fetchTrips() {
    throw StateError('failure');
  }

  @override
  Future<OperationTripModel> updateTripStatus(
    String tripId,
    OperationTripStatus status,
  ) {
    throw StateError('failure');
  }
}
