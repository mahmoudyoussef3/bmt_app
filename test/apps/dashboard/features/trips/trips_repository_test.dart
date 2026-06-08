import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/features/trips/data/datasources/mock_trips_datasource.dart';
import 'package:bmt_app/apps/dashboard/features/trips/data/models/operation_trip_model.dart';
import 'package:bmt_app/apps/dashboard/features/trips/data/models/trip_pricing_model.dart';
import 'package:bmt_app/apps/dashboard/features/trips/data/repositories/trips_repository_impl.dart';
import 'package:bmt_app/apps/dashboard/features/trips/domain/entities/operation_trip.dart';
import 'package:bmt_app/apps/dashboard/features/trips/domain/entities/trip_pricing.dart';
import 'package:bmt_app/apps/dashboard/features/trips/domain/usecases/get_operation_trips_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/trips/domain/usecases/trip_operations_usecases.dart';
import 'package:bmt_app/apps/dashboard/features/trips/domain/usecases/trip_pricing_usecases.dart';
import 'package:bmt_app/apps/dashboard/features/trips/domain/usecases/update_trip_seat_state_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/trips/domain/usecases/update_trip_status_usecase.dart';

void main() {
  group('Trips clean architecture chain', () {
    test('loads complete operations trips data', () async {
      final repository = TripsRepositoryImpl(MockTripsDatasource());
      final getTrips = GetOperationTripsUseCase(repository);

      final trips = await getTrips();

      expect(trips, hasLength(50));
      expect(trips.every((trip) => trip.driver.isNotEmpty), isTrue);
      expect(trips.every((trip) => trip.vehicle.isNotEmpty), isTrue);
      expect(trips.every((trip) => trip.routeStops.isNotEmpty), isTrue);
      expect(trips.every((trip) => trip.routePoints.isNotEmpty), isTrue);
      expect(trips.first.routePoints.first.order, 1);
      expect(
        trips.map((trip) => trip.status),
        contains(OperationTripStatus.inProgress),
      );
      expect(
        trips.first.events.map((event) => event.title),
        contains('تم إنشاء الرحلة'),
      );
      expect(trips.first.passengers, isNotEmpty);
      expect(trips.first.seats, isNotEmpty);
      expect(trips.first.capacity, trips.first.seats.length);
      expect(trips.first.availableSeats, greaterThan(0));
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

    test(
      'creates trip only when route driver vehicle and capacity exist',
      () async {
        final repository = TripsRepositoryImpl(MockTripsDatasource());
        final createTrip = CreateOperationTripUseCase(repository);

        final created = await createTrip(
          const CreateTripInput(
            route: 'بنها - القرية الذكية',
            driver: 'أحمد عبد الرازق',
            vehicle: 'كوستر ٣٣٤٥ ق ل',
            date: '٨ يونيو ٢٠٢٦',
            departure: '٩:٠٠',
            capacity: 14,
          ),
        );

        expect(created.id, isNotEmpty);
        expect(created.routeStops, isNotEmpty);
        expect(created.driver, isNotEmpty);
        expect(created.vehicle, isNotEmpty);

        expect(
          () => createTrip(
            const CreateTripInput(
              route: '',
              driver: '',
              vehicle: '',
              date: '٨ يونيو ٢٠٢٦',
              departure: '٩:٠٠',
              capacity: 0,
            ),
          ),
          throwsA(isA<Exception>()),
        );
      },
    );

    test('updates a trip seat state locally', () async {
      final repository = TripsRepositoryImpl(MockTripsDatasource());
      final getTrips = GetOperationTripsUseCase(repository);
      final updateSeat = UpdateTripSeatStateUseCase(repository);

      final trip = (await getTrips()).first;
      final seat = trip.seats.firstWhere(
        (item) => item.state == TripSeatState.available,
      );

      final updated = await updateSeat(trip.id, seat.id, TripSeatState.blocked);

      final updatedSeat = updated.seats.firstWhere(
        (item) => item.id == seat.id,
      );
      expect(updatedSeat.state, TripSeatState.blocked);
      expect(updated.events.first.description, contains(updatedSeat.label));
      expect(updated.blockedSeats, trip.blockedSeats + 1);
    });

    test('edits cancels and moves passengers inside trip workspace', () async {
      final repository = TripsRepositoryImpl(MockTripsDatasource());
      final getTrips = GetOperationTripsUseCase(repository);
      final updatePassenger = UpdateTripPassengerUseCase(repository);
      final cancelPassenger = CancelTripPassengerUseCase(repository);
      final movePassenger = MoveTripPassengerUseCase(repository);

      final trip = (await getTrips()).first;
      final passenger = trip.passengers.first;
      final edited = await updatePassenger(
        trip.id,
        passenger.copyWith(phone: '01000000000'),
      );
      expect(
        edited.passengers.firstWhere((item) => item.id == passenger.id).phone,
        '01000000000',
      );

      final targetSeat = edited.seats.firstWhere(
        (seat) => seat.state == TripSeatState.available,
      );
      final moved = await movePassenger(
        trip.id,
        passenger.id,
        targetSeat.label,
      );
      expect(
        moved.passengers.firstWhere((item) => item.id == passenger.id).seat,
        targetSeat.label,
      );

      final cancelled = await cancelPassenger(trip.id, passenger.id);
      expect(
        cancelled.passengers
            .firstWhere((item) => item.id == passenger.id)
            .status,
        'ملغي',
      );
    });

    test('loads and saves trip-scoped segment pricing', () async {
      final repository = TripsRepositoryImpl(MockTripsDatasource());
      final getTrips = GetOperationTripsUseCase(repository);
      final getPricing = GetTripPricingUseCase(repository);
      final validatePricing = ValidateTripPricingUseCase();
      final savePricing = SaveTripSegmentPricingUseCase(
        repository,
        validatePricing,
      );

      final trip = (await getTrips()).first;
      final pricing = await getPricing(trip.id);

      expect(pricing, isNotEmpty);
      expect(pricing.every((item) => item.tripId == trip.id), isTrue);
      expect(
        pricing.first.fromPointOrder,
        lessThan(pricing.first.toPointOrder),
      );

      final from = trip.routePoints.first;
      final to = trip.routePoints.last;
      final saved = await savePricing(
        TripPricing(
          id: '',
          tripId: trip.id,
          fromPointId: from.id,
          toPointId: to.id,
          fromPointName: from.name,
          toPointName: to.name,
          fromPointOrder: from.order,
          toPointOrder: to.order,
          oneTimePrice: 130,
          fiveDaysPrice: 610,
          tenDaysPrice: 1150,
          monthlyPrice: 2100,
          threeMonthsPrice: 5800,
          currency: 'ج.م',
          isActive: true,
          createdAt: DateTime(2026, 6, 9),
          updatedAt: DateTime(2026, 6, 9),
        ),
      );

      expect(saved.id, isNotEmpty);
      expect(saved.oneTimePrice, 130);
      expect(
        (await getPricing(trip.id)).map((item) => item.id),
        contains(saved.id),
      );
    });

    test('rejects invalid trip pricing before repository save', () async {
      final repository = TripsRepositoryImpl(MockTripsDatasource());
      final getTrips = GetOperationTripsUseCase(repository);
      final validatePricing = ValidateTripPricingUseCase();
      final savePricing = SaveTripSegmentPricingUseCase(
        repository,
        validatePricing,
      );
      final trip = (await getTrips()).first;
      final from = trip.routePoints[2];
      final to = trip.routePoints[1];

      expect(
        () => savePricing(
          TripPricing(
            id: '',
            tripId: trip.id,
            fromPointId: from.id,
            toPointId: to.id,
            fromPointName: from.name,
            toPointName: to.name,
            fromPointOrder: from.order,
            toPointOrder: to.order,
            oneTimePrice: 0,
            fiveDaysPrice: 100,
            tenDaysPrice: 200,
            monthlyPrice: 300,
            threeMonthsPrice: 400,
            currency: 'ج.م',
            isActive: true,
            createdAt: DateTime(2026, 6, 9),
            updatedAt: DateTime(2026, 6, 9),
          ),
        ),
        throwsA(isA<ArgumentError>()),
      );
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

  @override
  Future<OperationTripModel> updateSeatState(
    String tripId,
    String seatId,
    TripSeatState state,
  ) {
    throw StateError('failure');
  }

  @override
  Future<OperationTripModel> cancelPassenger(
    String tripId,
    String passengerId,
  ) {
    throw StateError('failure');
  }

  @override
  Future<OperationTripModel> createTrip(CreateTripInput input) {
    throw StateError('failure');
  }

  @override
  Future<OperationTripModel> movePassenger(
    String tripId,
    String passengerId,
    String seatLabel,
  ) {
    throw StateError('failure');
  }

  @override
  Future<OperationTripModel> updatePassenger(
    String tripId,
    TripPassenger passenger,
  ) {
    throw StateError('failure');
  }

  @override
  Future<OperationTripModel> updateTripInfo(OperationTrip trip) {
    throw StateError('failure');
  }

  @override
  Future<List<TripPricingModel>> fetchTripPricing(String tripId) {
    throw StateError('failure');
  }

  @override
  Future<TripPricingModel> toggleTripPricingStatus(
    String pricingId,
    bool isActive,
  ) {
    throw StateError('failure');
  }

  @override
  Future<TripPricingModel> upsertTripPricing(TripPricing pricing) {
    throw StateError('failure');
  }
}
