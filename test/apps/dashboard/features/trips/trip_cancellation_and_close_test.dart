import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/features/trips/shared/data/models/operation_trip_model.dart';
import 'package:bmt_app/apps/dashboard/features/trips/shared/data/models/trip_pricing_model.dart';
import 'package:bmt_app/apps/dashboard/features/trips/shared/domain/entities/operation_trip.dart';
import 'package:bmt_app/apps/dashboard/features/trips/shared/domain/entities/trip_lifecycle.dart';
import 'package:bmt_app/apps/dashboard/features/trips/shared/domain/entities/trip_pricing.dart';
import 'package:bmt_app/apps/dashboard/features/trips/trip_management/data/datasources/trips_datasource.dart';
import 'package:bmt_app/apps/dashboard/features/trips/trip_management/data/repositories/trips_repository_impl.dart';
import 'package:bmt_app/apps/dashboard/features/trips/trip_management/domain/repositories/trips_repository.dart';
import 'package:bmt_app/apps/dashboard/features/trips/trip_management/domain/usecases/trip_management_usecases.dart';
import 'package:bmt_app/apps/dashboard/features/trips/trip_management/presentation/cubit/trip_details_cubit.dart';

/// Phase 3 behaviours: cancellation carries a reason, a stale trip has two honest
/// outcomes, publishing is gated, deletion is refused where it would orphan a booking,
/// and every refusal reaches the operator with its actual cause.
void main() {
  late _Datasource datasource;
  late TripsRepository repository;

  setUp(() {
    datasource = _Datasource();
    repository = TripsRepositoryImpl(datasource);
  });

  group('cancellation', () {
    test('goes through the cancel RPC, never the generic status setter', () async {
      datasource.seed(_trip(status: OperationTripStatus.openForBooking));

      final updated = await repository.cancelTrip('trip-1', 'عطل بالمركبة');

      expect(updated.status, OperationTripStatus.cancelled);
      expect(datasource.cancelReasons, ['عطل بالمركبة']);
      expect(datasource.statusCalls, isEmpty);
    });

    test('an empty reason never reaches the server', () async {
      datasource.seed(_trip(status: OperationTripStatus.boarding));

      await expectLater(
        repository.cancelTrip('trip-1', '   '),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('يجب تحديد سبب إلغاء الرحلة'),
          ),
        ),
      );
      expect(datasource.cancelReasons, isEmpty);
    });

    test('reasons are trimmed before they are recorded', () async {
      datasource.seed(_trip(status: OperationTripStatus.openForBooking));

      await repository.cancelTrip('trip-1', '  عطل  ');

      expect(datasource.cancelReasons, ['عطل']);
    });

    test(
      'updateTripStatus(cancelled) is routed to the cancel RPC so a reason is always carried',
      () async {
        datasource.seed(_trip(status: OperationTripStatus.inProgress));

        await repository.updateTripStatus(
          'trip-1',
          OperationTripStatus.cancelled,
          reason: 'حادث',
        );

        expect(datasource.cancelReasons, ['حادث']);
        expect(datasource.statusCalls, isEmpty);
      },
    );

    test('cancelling from every non-terminal state is permitted', () async {
      for (final status in const [
        OperationTripStatus.scheduled,
        OperationTripStatus.openForBooking,
        OperationTripStatus.boarding,
        OperationTripStatus.inProgress,
      ]) {
        datasource = _Datasource()..seed(_trip(status: status));
        repository = TripsRepositoryImpl(datasource);

        final updated = await repository.cancelTrip('trip-1', 'سبب');
        expect(updated.status, OperationTripStatus.cancelled, reason: status.name);
      }
    });
  });

  group('publish gate', () {
    test('a trip with no driver is refused before the round trip', () async {
      datasource.seed(_trip().copyWith(driverId: ''));

      await expectLater(
        repository.updateTripStatus(
          'trip-1',
          OperationTripStatus.openForBooking,
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('لا يوجد سائق'),
          ),
        ),
      );
      expect(datasource.statusCalls, isEmpty);
    });

    test('a past-dated trip is refused', () async {
      datasource.seed(_trip().copyWith(date: '2020-01-01'));

      await expectLater(
        repository.updateTripStatus(
          'trip-1',
          OperationTripStatus.openForBooking,
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('تاريخ الرحلة قد فات'),
          ),
        ),
      );
      expect(datasource.statusCalls, isEmpty);
    });

    test('a ready trip publishes', () async {
      datasource.seed(_trip());

      final updated = await repository.updateTripStatus(
        'trip-1',
        OperationTripStatus.openForBooking,
      );

      expect(updated.status, OperationTripStatus.openForBooking);
      expect(datasource.statusCalls, [OperationTripStatus.openForBooking]);
    });
  });

  group('stale trip close', () {
    test('operated walks the trip to completed', () async {
      datasource.seed(
        _trip(status: OperationTripStatus.openForBooking).copyWith(
          date: '2020-01-01',
        ),
      );

      final updated = await repository.closeStaleTrip(
        'trip-1',
        StaleTripOutcome.operated,
      );

      expect(updated.status, OperationTripStatus.completed);
      expect(datasource.staleOutcomes, [StaleTripOutcome.operated]);
    });

    test('cancelled closes it as cancelled', () async {
      datasource.seed(
        _trip(status: OperationTripStatus.openForBooking).copyWith(
          date: '2020-01-01',
        ),
      );

      final updated = await repository.closeStaleTrip(
        'trip-1',
        StaleTripOutcome.cancelled,
        reason: 'لم تنطلق',
      );

      expect(updated.status, OperationTripStatus.cancelled);
      expect(datasource.staleReasons, ['لم تنطلق']);
    });

    test('a blank reason is sent as null rather than as an empty string', () async {
      datasource.seed(_trip(status: OperationTripStatus.openForBooking));

      await repository.closeStaleTrip(
        'trip-1',
        StaleTripOutcome.cancelled,
        reason: '   ',
      );

      expect(datasource.staleReasons, [null]);
    });
  });

  group('delete guard', () {
    test('an unpublished, unbooked trip is deletable', () async {
      datasource.seed(_trip());

      await repository.deleteTrip('trip-1');

      expect(datasource.deleted, ['trip-1']);
    });

    test('a published trip is refused with an instruction to cancel', () async {
      datasource.seed(_trip(status: OperationTripStatus.openForBooking));

      await expectLater(
        repository.deleteTrip('trip-1'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('ألغِها بدلاً من ذلك'),
          ),
        ),
      );
      expect(datasource.deleted, isEmpty);
    });

    test('a trip carrying passengers is refused', () async {
      datasource.seed(_trip(passengers: [_passenger()]));

      await expectLater(
        repository.deleteTrip('trip-1'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('عليها ركاب'),
          ),
        ),
      );
      expect(datasource.deleted, isEmpty);
    });
  });

  group('TripDetailsCubit', () {
    test('cancelTrip replaces the loaded trip and clears saving', () async {
      datasource.seed(_trip(status: OperationTripStatus.openForBooking));
      final cubit = _cubit(repository);
      await cubit.showDetails(datasource.current);

      final updated = await cubit.cancelTrip('عطل');

      expect(updated?.status, OperationTripStatus.cancelled);
      final state = cubit.state as TripDetailsLoaded;
      expect(state.trip.status, OperationTripStatus.cancelled);
      expect(state.isSaving, isFalse);
      expect(state.lastError, isNull);
      await cubit.close();
    });

    test('closeStaleTrip completes an operated trip', () async {
      datasource.seed(
        _trip(status: OperationTripStatus.openForBooking).copyWith(
          date: '2020-01-01',
        ),
      );
      final cubit = _cubit(repository);
      await cubit.showDetails(datasource.current);

      final updated = await cubit.closeStaleTrip(StaleTripOutcome.operated);

      expect(updated?.status, OperationTripStatus.completed);
      await cubit.close();
    });

    test(
      'a failure keeps the trip on screen and carries the real reason, not a fixed string',
      () async {
        datasource.seed(_trip().copyWith(driverId: ''));
        final cubit = _cubit(repository);
        await cubit.showDetails(datasource.current);

        final result = await cubit.updateStatus(
          OperationTripStatus.openForBooking,
        );

        expect(result, isNull);
        final state = cubit.state as TripDetailsLoaded;
        expect(state.trip.status, OperationTripStatus.scheduled);
        expect(state.isSaving, isFalse);
        expect(state.lastError, contains('لا يوجد سائق'));
        // The 'Exception: ' prefix is stripped so the snackbar reads as a sentence.
        expect(state.lastError, isNot(startsWith('Exception')));
        await cubit.close();
      },
    );

    test('a server refusal of a cancel is surfaced too', () async {
      datasource.seed(_trip(status: OperationTripStatus.boarding));
      datasource.failCancelWith = 'cancellation_reason_required';
      final cubit = _cubit(repository);
      await cubit.showDetails(datasource.current);

      final result = await cubit.cancelTrip('سبب');

      expect(result, isNull);
      final state = cubit.state as TripDetailsLoaded;
      expect(state.lastError, contains('cancellation_reason_required'));
      await cubit.close();
    });
  });
}

TripDetailsCubit _cubit(TripsRepository repo) => TripDetailsCubit(
  getTripDetails: GetTripDetailsUseCase(repo),
  updateTripStatus: UpdateTripStatusUseCase(repo),
  updateTripInfo: UpdateTripInfoUseCase(repo),
  cancelTrip: CancelTripUseCase(repo),
  closeStaleTrip: CloseStaleTripUseCase(repo),
  watchTripDetails: WatchTripDetailsUseCase(repo),
);

OperationTrip _trip({
  OperationTripStatus status = OperationTripStatus.scheduled,
  List<TripPassenger> passengers = const [],
}) {
  return OperationTrip(
    id: 'trip-1',
    routeId: 'route-1',
    route: 'بنها - القرية الذكية',
    routePoints: const [],
    driverId: 'driver-1',
    driver: 'أحمد حسن',
    vehicleId: 'vehicle-1',
    vehicle: 'ق س أ 1234',
    date: '2099-01-01',
    departure: '09:00',
    arrival: '10:30',
    status: status,
    capacity: 14,
    ticketPrice: 50,
    seats: const [
      TripSeat(
        id: 'seat-1',
        label: '1',
        row: 1,
        column: 1,
        state: TripSeatState.available,
      ),
    ],
    passengers: passengers,
    events: const [],
    notes: const [],
  );
}

TripPassenger _passenger() => const TripPassenger(
  id: 'pass-1',
  name: 'محمد علي',
  phone: '01000000000',
  seat: '1',
  pickup: 'بنها',
  dropoff: 'القرية الذكية',
  paymentMethod: 'instapay',
  status: 'confirmed',
);

class _Datasource implements TripsDatasource {
  late OperationTripModel _trip;

  final List<OperationTripStatus> statusCalls = [];
  final List<String> cancelReasons = [];
  final List<StaleTripOutcome> staleOutcomes = [];
  final List<String?> staleReasons = [];
  final List<String> deleted = [];
  String? failCancelWith;

  void seed(OperationTrip trip) {
    _trip = OperationTripModel.fromEntity(trip);
  }

  OperationTrip get current => _trip;

  void _set(OperationTripStatus status) {
    _trip = OperationTripModel.fromEntity(_trip.copyWith(status: status));
  }

  @override
  Future<OperationTripModel> fetchTripById(String tripId) async => _trip;

  @override
  Future<OperationTripModel> updateTripStatus(
    String tripId,
    OperationTripStatus status, {
    String? reason,
  }) async {
    statusCalls.add(status);
    _set(status);
    return _trip;
  }

  @override
  Future<OperationTripModel> cancelTrip(String tripId, String reason) async {
    if (failCancelWith != null) throw Exception(failCancelWith);
    cancelReasons.add(reason);
    _set(OperationTripStatus.cancelled);
    return _trip;
  }

  @override
  Future<OperationTripModel> closeStaleTrip(
    String tripId,
    StaleTripOutcome outcome, {
    String? reason,
  }) async {
    staleOutcomes.add(outcome);
    staleReasons.add(reason);
    _set(
      outcome == StaleTripOutcome.operated
          ? OperationTripStatus.completed
          : OperationTripStatus.cancelled,
    );
    return _trip;
  }

  @override
  Future<void> deleteTrip(String tripId) async => deleted.add(tripId);

  @override
  Stream<void> watchTripChanges(String tripId) => const Stream.empty();

  @override
  Stream<void> watchTripsChanges() => const Stream.empty();

  // ── unused by these tests ────────────────────────────────────────────────────
  @override
  Future<List<OperationTripModel>> fetchTrips() => throw UnimplementedError();

  @override
  Future<OperationTripModel> createTrip(CreateTripInput input) =>
      throw UnimplementedError();

  @override
  Future<OperationTripModel> updateTripInfo(OperationTrip trip) =>
      throw UnimplementedError();

  @override
  Future<OperationTripModel> updateSeatState(
    String tripId,
    String seatId,
    TripSeatState state,
  ) => throw UnimplementedError();

  @override
  Future<OperationTripModel> updatePassenger(
    String tripId,
    TripPassenger passenger,
  ) => throw UnimplementedError();

  @override
  Future<OperationTripModel> cancelPassenger(
    String tripId,
    String passengerId,
  ) => throw UnimplementedError();

  @override
  Future<OperationTripModel> movePassenger(
    String tripId,
    String passengerId,
    String seatLabel,
  ) => throw UnimplementedError();

  @override
  Future<List<TripPricingModel>> fetchTripPricing(String tripId) =>
      throw UnimplementedError();

  @override
  Future<TripPricingModel> upsertTripPricing(TripPricing pricing) =>
      throw UnimplementedError();

  @override
  Future<TripPricingModel> toggleTripPricingStatus(
    String pricingId,
    bool isActive,
  ) => throw UnimplementedError();

  @override
  Future<List<TripEventModel>> fetchTripEvents(String tripId) =>
      throw UnimplementedError();

  @override
  Future<List<Map<String, dynamic>>> fetchActiveDrivers() =>
      throw UnimplementedError();

  @override
  Future<List<Map<String, dynamic>>> fetchActiveVehicles() =>
      throw UnimplementedError();

  @override
  Future<List<Map<String, dynamic>>> fetchActiveRoutes() =>
      throw UnimplementedError();

  @override
  Future<List<Map<String, dynamic>>> fetchResourceConflicts({
    required String date,
    required String departureTime,
    required String arrivalTime,
  }) => throw UnimplementedError();

  @override
  Future<bool> checkDuplicateTrip(
    String vehicleId,
    String date,
    String departureTime,
  ) => throw UnimplementedError();

  @override
  Future<bool> checkDriverTripConflict(
    String driverId,
    String date,
    String departureTime,
  ) => throw UnimplementedError();

  @override
  Future<String> getDriverStatus(String driverId) => throw UnimplementedError();

  @override
  Future<String> getVehicleStatus(String vehicleId) =>
      throw UnimplementedError();

  @override
  Future<String> getRouteStatus(String routeId) => throw UnimplementedError();
}
