import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/features/trips/shared/domain/entities/operation_trip.dart';
import 'package:bmt_app/apps/dashboard/features/trips/shared/domain/entities/trip_lifecycle.dart';
import 'package:bmt_app/apps/dashboard/features/trips/shared/domain/entities/trip_pricing.dart';
import 'package:bmt_app/apps/dashboard/features/trips/trip_creation/domain/entities/trip_driver_option.dart';
import 'package:bmt_app/apps/dashboard/features/trips/trip_management/domain/repositories/trips_repository.dart';
import 'package:bmt_app/apps/dashboard/features/trips/trip_management/domain/usecases/trip_management_usecases.dart';
import 'package:bmt_app/apps/dashboard/features/trips/trip_management/presentation/cubit/trips_list_cubit.dart';

// Regression coverage for the "captain actions don't reach the dashboard
// Trips screen" bug: TripsListCubit.load() used to be a one-shot fetch with
// no realtime subscription, so operators only saw a captain's status/seat/
// passenger changes after manually leaving and re-entering the screen.

OperationTrip _trip(
  String id, {
  OperationTripStatus status = OperationTripStatus.scheduled,
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
    passengers: const [],
    events: const [],
    notes: const [],
  );
}

class _FakeRepo implements TripsRepository {
  _FakeRepo(this.trips);

  List<OperationTrip> trips;
  int fetchCount = 0;
  final _changes = StreamController<void>.broadcast();

  void emitChange() => _changes.add(null);

  @override
  Future<List<OperationTrip>> getTrips() async {
    fetchCount++;
    return trips;
  }

  @override
  Future<void> deleteTrip(String tripId) async {
    trips = trips.where((t) => t.id != tripId).toList();
  }

  @override
  Stream<void> watchTripsChanges() => _changes.stream;

  @override
  Stream<void> watchTripChanges(String tripId) => const Stream.empty();

  @override
  Future<OperationTrip> getTripById(String tripId) =>
      throw UnimplementedError();

  @override
  Future<OperationTrip> updateTripStatus(
    String tripId,
    OperationTripStatus status, {
    String? reason,
  }) => throw UnimplementedError();

  @override
  Future<OperationTrip> cancelTrip(String tripId, String reason) =>
      throw UnimplementedError();

  @override
  Future<OperationTrip> closeStaleTrip(
    String tripId,
    StaleTripOutcome outcome, {
    String? reason,
  }) => throw UnimplementedError();

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
  Future<OperationTrip> updateTripInfo(OperationTrip trip) =>
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
}

TripsListCubit _cubit(_FakeRepo repo) {
  return TripsListCubit(
    GetOperationTripsUseCase(repo),
    DeleteTripUseCase(repo),
    WatchOperationTripsUseCase(repo),
  );
}

void main() {
  group('TripsListCubit realtime sync', () {
    test('load() fetches trips once and subscribes to changes', () async {
      final repo = _FakeRepo([_trip('trip-1')]);
      final cubit = _cubit(repo);

      await cubit.load();

      expect(repo.fetchCount, 1);
      expect((cubit.state as TripsListLoaded).trips.single.id, 'trip-1');
      await cubit.close();
    });

    test(
      'a realtime change (e.g. captain updates trip status) triggers a '
      'debounced refetch that updates the list without a manual reload',
      () async {
        final repo = _FakeRepo([_trip('trip-1')]);
        final cubit = _cubit(repo);
        await cubit.load();
        expect(repo.fetchCount, 1);

        // Simulate the captain app flipping the trip to in_progress via the
        // update_trip_status RPC — Supabase broadcasts this as a Postgres
        // change on operation_trips.
        repo.trips = [_trip('trip-1', status: OperationTripStatus.inProgress)];
        repo.emitChange();

        // The cubit debounces realtime bursts by 250ms before refetching.
        await Future<void>.delayed(const Duration(milliseconds: 400));

        expect(repo.fetchCount, 2);
        final state = cubit.state as TripsListLoaded;
        expect(state.trips.single.status, OperationTripStatus.inProgress);
        await cubit.close();
      },
    );

    test(
      'rapid bursts of changes only cause a single refetch (debounced)',
      () async {
        final repo = _FakeRepo([_trip('trip-1')]);
        final cubit = _cubit(repo);
        await cubit.load();
        expect(repo.fetchCount, 1);

        repo.emitChange();
        repo.emitChange();
        repo.emitChange();
        await Future<void>.delayed(const Duration(milliseconds: 400));

        expect(repo.fetchCount, 2);
        await cubit.close();
      },
    );

    test('preserves existing filters when a realtime refresh lands', () async {
      final repo = _FakeRepo([_trip('trip-1'), _trip('trip-2')]);
      final cubit = _cubit(repo);
      await cubit.load();

      cubit.filterQuick('today');
      repo.emitChange();
      await Future<void>.delayed(const Duration(milliseconds: 400));

      final state = cubit.state as TripsListLoaded;
      expect(state.quickFilter, 'today');
      await cubit.close();
    });

    test('close() cancels the realtime subscription and timers', () async {
      final repo = _FakeRepo([_trip('trip-1')]);
      final cubit = _cubit(repo);
      await cubit.load();
      await cubit.close();

      repo.emitChange();
      await Future<void>.delayed(const Duration(milliseconds: 400));

      // No further fetch after close(); still just the initial load.
      expect(repo.fetchCount, 1);
    });
  });
}
