import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/features/trips/shared/domain/entities/operation_trip.dart';
import 'package:bmt_app/apps/dashboard/features/trips/shared/domain/entities/trip_lifecycle.dart';
import 'package:bmt_app/apps/dashboard/features/trips/shared/domain/entities/trip_pricable_package.dart';
import 'package:bmt_app/apps/dashboard/features/trips/shared/domain/entities/trip_pricing.dart';
import 'package:bmt_app/apps/dashboard/features/trips/trip_creation/domain/entities/trip_driver_option.dart';
import 'package:bmt_app/apps/dashboard/features/trips/trip_management/domain/repositories/trips_repository.dart';
import 'package:bmt_app/apps/dashboard/features/trips/trip_management/domain/usecases/trip_management_usecases.dart';
import 'package:bmt_app/apps/dashboard/features/trips/trip_management/presentation/cubit/trip_details_cubit.dart';

// Regression coverage: the trip details workspace (overview/passengers/
// seats/history tabs an operator opens for one trip) used to only refetch
// on an explicit action. A captain checking in a passenger or arriving at a
// station (trip_passengers / trip_events writes) never reached an already
// open dialog until it was closed and reopened.

OperationTrip _trip(
  String id, {
  OperationTripStatus status = OperationTripStatus.scheduled,
  List<TripPassenger> passengers = const [],
}) {
  return OperationTrip(
    id: id,
    routeId: 'route-1',
    route: 'بنها - القرية الذكية',
    routePoints: const [],
    driverId: 'driver-1',
    driver: 'أحمد حسن',
    vehicleId: 'vehicle-1',
    vehicle: 'ق س أ 1234',
    date: '2026-07-12',
    departure: '09:00',
    arrival: '10:30',
    status: status,
    capacity: 10,
    seats: const [],
    passengers: passengers,
    events: const [],
    notes: const [],
  );
}

class _FakeRepo implements TripsRepository {
  _FakeRepo(this.tripsById);

  Map<String, OperationTrip> tripsById;
  int fetchByIdCount = 0;
  String? lastReason;
  StaleTripOutcome? lastOutcome;
  final _changesByTrip = <String, StreamController<void>>{};

  void emitChange(String tripId) {
    _changesByTrip[tripId]?.add(null);
  }

  @override
  Future<OperationTrip> getTripById(String tripId) async {
    fetchByIdCount++;
    final trip = tripsById[tripId];
    if (trip == null) throw Exception('Trip not found');
    return trip;
  }

  @override
  Stream<void> watchTripChanges(String tripId) {
    return _changesByTrip
        .putIfAbsent(tripId, () => StreamController<void>.broadcast())
        .stream;
  }

  @override
  Future<OperationTrip> updateTripStatus(
    String tripId,
    OperationTripStatus status, {
    String? reason,
  }) async {
    lastReason = reason;
    final updated = tripsById[tripId]!.copyWith(status: status);
    tripsById[tripId] = updated;
    return updated;
  }

  @override
  Future<OperationTrip> cancelTrip(String tripId, String reason) async {
    lastReason = reason;
    final updated = tripsById[tripId]!.copyWith(
      status: OperationTripStatus.cancelled,
    );
    tripsById[tripId] = updated;
    return updated;
  }

  @override
  Future<OperationTrip> closeStaleTrip(
    String tripId,
    StaleTripOutcome outcome, {
    String? reason,
  }) async {
    lastOutcome = outcome;
    final updated = tripsById[tripId]!.copyWith(
      status: outcome == StaleTripOutcome.operated
          ? OperationTripStatus.completed
          : OperationTripStatus.cancelled,
    );
    tripsById[tripId] = updated;
    return updated;
  }

  @override
  Future<OperationTrip> updateTripInfo(OperationTrip trip) async {
    tripsById[trip.id] = trip;
    return trip;
  }

  @override
  Stream<void> watchTripsChanges() => const Stream.empty();

  @override
  Future<List<OperationTrip>> getTrips() => throw UnimplementedError();

  @override
  Future<void> deleteTrip(String tripId) => throw UnimplementedError();

  @override
  Future<OperationTrip> updateSeatState(
    String tripId,
    String seatId,
    TripSeatState state,
  ) => throw UnimplementedError();

  @override
  Future<OperationTrip> createTrip(CreateTripInput input) =>
      throw UnimplementedError();

  @override
  Future<OperationTrip> updatePassenger(
    String tripId,
    TripPassenger passenger,
  ) => throw UnimplementedError();

  @override
  Future<OperationTrip> cancelPassenger(String tripId, String passengerId) =>
      throw UnimplementedError();

  @override
  Future<OperationTrip> movePassenger(
    String tripId,
    String passengerId,
    String seatLabel,
  ) => throw UnimplementedError();

  @override
  Future<List<TripPricing>> getTripPricing(String tripId) =>
      throw UnimplementedError();

  @override
  Future<TripPricing> upsertTripPricing(TripPricing pricing) =>
      throw UnimplementedError();

  @override
  Future<TripPricing> toggleTripPricingStatus(
    String pricingId,
    bool isActive,
  ) => throw UnimplementedError();

  @override
  Future<List<TripEvent>> getTripEvents(String tripId) =>
      throw UnimplementedError();

  @override
  Future<List<TripDriverOption>> getActiveDrivers() =>
      throw UnimplementedError();

  @override
  Future<List<Map<String, dynamic>>> getActiveRoutes() =>
      throw UnimplementedError();

  @override
  Future<List<Map<String, dynamic>>> getResourceConflicts({
    required String date,
    required String departureTime,
    required String arrivalTime,
  }) => throw UnimplementedError();

  @override
  Future<List<TripPricablePackage>> getOfficePricablePackages() =>
      throw UnimplementedError();
}

TripDetailsCubit _cubit(_FakeRepo repo) {
  return TripDetailsCubit(
    getTripDetails: GetTripDetailsUseCase(repo),
    updateTripStatus: UpdateTripStatusUseCase(repo),
    updateTripInfo: UpdateTripInfoUseCase(repo),
    cancelTrip: CancelTripUseCase(repo),
    closeStaleTrip: CloseStaleTripUseCase(repo),
    watchTripDetails: WatchTripDetailsUseCase(repo),
  );
}

void main() {
  group('TripDetailsCubit realtime sync', () {
    test('showDetails() loads the trip immediately without a fetch', () async {
      final repo = _FakeRepo({'trip-1': _trip('trip-1')});
      final cubit = _cubit(repo);

      await cubit.showDetails(_trip('trip-1'));

      expect((cubit.state as TripDetailsLoaded).trip.id, 'trip-1');
      expect(repo.fetchByIdCount, 0);
      await cubit.close();
    });

    test(
      'a realtime change scoped to the open trip (e.g. captain checks in a '
      'passenger) triggers a debounced refetch that updates the workspace',
      () async {
        final repo = _FakeRepo({'trip-1': _trip('trip-1')});
        final cubit = _cubit(repo);
        await cubit.showDetails(_trip('trip-1'));

        // Simulate the captain app's passenger manifest flow writing a
        // trip_passengers status update — Supabase broadcasts a Postgres
        // change filtered by trip_id.
        repo.tripsById['trip-1'] = _trip(
          'trip-1',
          passengers: const [
            TripPassenger(
              id: 'p-1',
              name: 'راكب',
              phone: '0100',
              seat: 'A1',
              pickup: 'بنها',
              dropoff: 'القرية الذكية',
              paymentMethod: 'cash',
              status: 'confirmed',
            ),
          ],
        );
        repo.emitChange('trip-1');

        await Future<void>.delayed(const Duration(milliseconds: 400));

        expect(repo.fetchByIdCount, 1);
        final state = cubit.state as TripDetailsLoaded;
        expect(state.trip.passengers, hasLength(1));
        await cubit.close();
      },
    );

    test(
      'closeDetails() cancels the subscription for the previous trip',
      () async {
        final repo = _FakeRepo({'trip-1': _trip('trip-1')});
        final cubit = _cubit(repo);
        await cubit.showDetails(_trip('trip-1'));

        cubit.closeDetails();
        repo.emitChange('trip-1');
        await Future<void>.delayed(const Duration(milliseconds: 400));

        expect(repo.fetchByIdCount, 0);
        expect(cubit.state, isA<TripDetailsInitial>());
        await cubit.close();
      },
    );

    test(
      'switching trips resubscribes to the newly opened trip only',
      () async {
        final repo = _FakeRepo({
          'trip-1': _trip('trip-1'),
          'trip-2': _trip('trip-2'),
        });
        final cubit = _cubit(repo);
        await cubit.showDetails(_trip('trip-1'));

        // Operator closes trip-1 and opens trip-2.
        cubit.closeDetails();
        await cubit.showDetails(_trip('trip-2'));

        // A change on the previously viewed trip must not affect state.
        repo.emitChange('trip-1');
        await Future<void>.delayed(const Duration(milliseconds: 400));
        expect(repo.fetchByIdCount, 0);
        expect((cubit.state as TripDetailsLoaded).trip.id, 'trip-2');

        // A change on the currently viewed trip must refresh it.
        repo.tripsById['trip-2'] = _trip(
          'trip-2',
          status: OperationTripStatus.boarding,
        );
        repo.emitChange('trip-2');
        await Future<void>.delayed(const Duration(milliseconds: 400));

        expect(repo.fetchByIdCount, 1);
        final state = cubit.state as TripDetailsLoaded;
        expect(state.trip.status, OperationTripStatus.boarding);
        await cubit.close();
      },
    );

    test('a failed background refresh preserves the last loaded trip instead '
        'of surfacing an error screen', () async {
      final repo = _FakeRepo({'trip-1': _trip('trip-1')});
      final cubit = _cubit(repo);
      await cubit.showDetails(_trip('trip-1'));

      repo.tripsById.remove('trip-1'); // next getTripById() will throw
      repo.emitChange('trip-1');
      await Future<void>.delayed(const Duration(milliseconds: 400));

      expect(cubit.state, isA<TripDetailsLoaded>());
      expect((cubit.state as TripDetailsLoaded).trip.id, 'trip-1');
      await cubit.close();
    });
  });
}
