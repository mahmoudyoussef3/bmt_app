import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/trips/data/datasources/mock_trips_datasource.dart';
import 'package:bmt_app/apps/client/features/trips/data/repositories/trips_repository_impl.dart';
import 'package:bmt_app/apps/client/features/trips/domain/entities/trip.dart';
import 'package:bmt_app/apps/client/features/trips/domain/usecases/get_trip_details_usecase.dart';
import 'package:bmt_app/apps/client/features/trips/domain/usecases/get_trips_usecase.dart';

void main() {
  group('Client trips repository', () {
    late TripsRepositoryImpl repository;
    late GetTripsUseCase getTrips;
    late GetTripDetailsUseCase getTripDetails;

    setUp(() {
      repository = const TripsRepositoryImpl(MockTripsDatasource());
      getTrips = GetTripsUseCase(repository);
      getTripDetails = GetTripDetailsUseCase(repository);
    });

    test('returns the client trips from the mock data source', () async {
      final trips = await getTrips();

      expect(trips, hasLength(6));
      expect(trips.first.reference, 'BMT-8K4P2N7Q');
      expect(trips.first.status, TripStatus.upcoming);
      expect(trips.first.paymentStatus, PaymentStatus.paid);
    });

    test('returns a selected trip by id', () async {
      final trip = await getTripDetails('T3');

      expect(trip, isNotNull);
      expect(trip!.id, 'T3');
      expect(trip.status, TripStatus.inProgress);
      expect(trip.routeLine, 'Banha Downtown → Mohandessin');
    });

    test('returns null when the selected trip does not exist', () async {
      final trip = await getTripDetails('missing-trip');

      expect(trip, isNull);
    });
  });
}
