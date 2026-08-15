import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/features/trips/shared/domain/entities/operation_trip.dart';
import 'package:bmt_app/apps/dashboard/features/trips/shared/domain/entities/trip_lifecycle.dart';
import 'package:bmt_app/apps/dashboard/features/trips/shared/domain/entities/trip_pricable_package.dart';
import 'package:bmt_app/apps/dashboard/features/trips/shared/domain/entities/trip_pricing.dart';
import 'package:bmt_app/apps/dashboard/features/trips/shared/data/models/operation_trip_model.dart';
import 'package:bmt_app/apps/dashboard/features/trips/shared/data/models/trip_pricing_model.dart';
import 'package:bmt_app/apps/dashboard/features/trips/trip_management/domain/repositories/trips_repository.dart';
import 'package:bmt_app/apps/dashboard/features/trips/trip_management/data/repositories/trips_repository_impl.dart';
import 'package:bmt_app/apps/dashboard/features/trips/trip_management/data/datasources/trips_datasource.dart';
import 'package:bmt_app/apps/dashboard/features/trips/trip_management/domain/usecases/trip_management_usecases.dart';
import 'package:bmt_app/apps/dashboard/features/trips/trip_creation/domain/entities/trip_driver_option.dart';
import 'package:bmt_app/apps/dashboard/features/trips/trip_creation/domain/usecases/trip_creation_usecases.dart';
import 'package:bmt_app/apps/dashboard/features/trips/trip_seats/domain/usecases/trip_seats_usecases.dart';
import 'package:bmt_app/apps/dashboard/features/trips/trip_passengers/domain/usecases/trip_passengers_usecases.dart';
import 'package:bmt_app/apps/dashboard/features/trips/trip_pricing/domain/usecases/trip_pricing_usecases.dart';

/// A complete, valid plan. Only the driver and the route vary between cases — there is
/// nothing else about the trip's resources for a caller to get wrong.
CreateTripInput _input({required String driverId, String routeId = 'route-1'}) {
  return CreateTripInput(
    routeId: routeId,
    route: 'بنها - القرية الذكية',
    driverId: driverId,
    driver: 'أحمد حسن',
    date: '2026-06-12',
    departure: '09:00',
    arrival: '10:30',
    ticketPrice: 75,
  );
}

void main() {
  group('Trips clean architecture chain', () {
    late _MockTripsDatasource datasource;
    late TripsRepository repository;

    setUp(() {
      datasource = _MockTripsDatasource();
      repository = TripsRepositoryImpl(datasource);
    });

    test('loads complete operations trips data', () async {
      final getTrips = GetOperationTripsUseCase(repository);
      final trips = await getTrips();

      expect(trips, hasLength(2));
      expect(trips.first.driver, 'أحمد حسن');
      expect(trips.first.vehicle, 'ق س أ 1234');
      expect(trips.first.routeStops, ['بنها', 'شبرا', 'القرية الذكية']);
      expect(trips.first.capacity, 14);
      expect(trips.first.availableSeats, 1);
    });

    test('moves trip status', () async {
      final updateStatus = UpdateTripStatusUseCase(repository);
      final updated = await updateStatus(
        'trip-1',
        OperationTripStatus.openForBooking,
      );

      expect(updated.status, OperationTripStatus.openForBooking);
    });

    test(
      'rejects backwards trip status transitions before datasource update',
      () {
        final updateStatus = UpdateTripStatusUseCase(repository);

        expect(
          () => updateStatus('trip-2', OperationTripStatus.openForBooking),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('لا يمكن نقل الرحلة من "جارية" إلى "مفتوحة للحجز"'),
            ),
          ),
        );
      },
    );

    // The cases below replace an older set that passed a `vehicleId` and a `capacity`
    // alongside the driver and asserted on a client-side duplicate check. Both encoded
    // the model 20260731090000_driver_vehicle_authority removed: a trip's vehicle is
    // the one its driver is assigned to, and overlap is the server's exclusion
    // constraints to judge, not an exact date + departure-time match here.
    test('a driver with an assigned vehicle can be scheduled', () async {
      final createTrip = CreateTripUseCase(repository);

      final created = await createTrip(_input(driverId: 'driver-active'), [], []);

      expect(created.id, isNotEmpty);
      expect(created.driver, 'أحمد حسن');
      expect(created.vehicle, 'ق س أ 1234');
      expect(created.capacity, 14);
      expect(created.seats, hasLength(14));
    });

    test(
      'the vehicle and capacity come from the fleet, not from the planner',
      () async {
        final createTrip = CreateTripUseCase(repository);
        final created = await createTrip(_input(driverId: 'driver-active'), [], []);

        // `CreateTripInput` has no vehicle or capacity field to carry — that is enforced
        // by the compiler. What this asserts is the consequence: the trip still comes
        // back with the assigned bus and its seat count.
        expect(datasource.lastCreateInput?.driverId, 'driver-active');
        expect(created.vehicleId, 'vehicle-active');
        expect(created.capacity, 14);
      },
    );

    test('a driver with no assigned vehicle is blocked, in Arabic', () {
      final createTrip = CreateTripUseCase(repository);

      expect(
        () => createTrip(_input(driverId: 'driver-no-vehicle'), [], []),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('هذا السائق غير مرتبط بسيارة حالياً'),
          ),
        ),
      );
    });

    test('a driver whose vehicle is out of service is blocked', () {
      final createTrip = CreateTripUseCase(repository);

      expect(
        () => createTrip(_input(driverId: 'driver-vehicle-maintenance'), [], []),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            allOf(contains('غير متاحة للتشغيل'), contains('ق س أ 9999')),
          ),
        ),
      );
    });

    test('a driver outside the office is rejected', () {
      final createTrip = CreateTripUseCase(repository);

      expect(
        () => createTrip(_input(driverId: 'driver-other-office'), [], []),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('لا يتبع مكتبك'),
          ),
        ),
      );
    });

    test('an archived route is still refused', () {
      final createTrip = CreateTripUseCase(repository);

      expect(
        () => createTrip(
          _input(driverId: 'driver-active', routeId: 'route-archived'),
          [],
          [],
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('لا يمكن جدولة رحلة لمسار مؤرشف'),
          ),
        ),
      );
    });

    test('updates a trip seat state', () async {
      final updateSeat = UpdateSeatStateUseCase(repository);
      final updated = await updateSeat(
        'trip-1',
        'seat-1',
        TripSeatState.blocked,
      );

      final updatedSeat = updated.seats.firstWhere((s) => s.id == 'seat-1');
      expect(updatedSeat.state, TripSeatState.blocked);
    });

    test('passenger actions: update, cancel, move', () async {
      final updatePassenger = UpdatePassengerUseCase(repository);
      final cancelPassenger = CancelPassengerUseCase(repository);
      final movePassenger = MovePassengerUseCase(repository);

      // Edit passenger phone
      final passenger = const TripPassenger(
        id: 'pass-1',
        name: 'محمد علي',
        phone: '01000000000',
        seat: 'A3',
        pickup: 'بنها',
        dropoff: 'القرية الذكية',
        paymentMethod: 'cash',
        status: 'reserved',
      );
      final edited = await updatePassenger('trip-1', passenger);
      expect(
        edited.passengers.firstWhere((p) => p.id == 'pass-1').phone,
        '01000000000',
      );

      // Move passenger seat
      final moved = await movePassenger('trip-1', 'pass-1', 'A2');
      expect(moved.passengers.firstWhere((p) => p.id == 'pass-1').seat, 'A2');

      // Cancel passenger
      final cancelled = await cancelPassenger('trip-1', 'pass-1');
      expect(
        cancelled.passengers.firstWhere((p) => p.id == 'pass-1').status,
        'ملغي',
      );
    });

    test('saves pricing configurations with validations', () async {
      final savePricing = SaveTripPricingUseCase(repository);

      // Valid pricing upsert
      final pricing = TripPricing(
        id: 'pricing-1',
        tripId: 'trip-1',
        fromPointId: 'st-1',
        toPointId: 'st-2',
        fromPointName: 'بنها',
        toPointName: 'شبرا',
        fromPointOrder: 1,
        toPointOrder: 2,
        oneTimePrice: 50.0,
        packagePrices: const {'pkg-1': 220.0, 'pkg-2': 400.0},
        currency: 'ج.م',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final saved = await savePricing(pricing);
      expect(saved.id, 'pricing-1');
      expect(saved.oneTimePrice, 50.0);

      // Invalid pricing - same point
      final samePointPricing = pricing.copyWith(toPointId: 'st-1');
      expect(
        () => savePricing(samePointPricing),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('يجب أن تكون نقطتا البداية والنهاية مختلفتين'),
          ),
        ),
      );

      // Invalid pricing - from order >= to order
      final wrongOrderPricing = pricing.copyWith(
        fromPointOrder: 2,
        toPointOrder: 1,
      );
      expect(
        () => savePricing(wrongOrderPricing),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('نقطة البداية يجب أن تسبق'),
          ),
        ),
      );

      // Invalid pricing - negative or zero price
      final zeroPricePricing = pricing.copyWith(oneTimePrice: 0.0);
      expect(
        () => savePricing(zeroPricePricing),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('يجب أن يكون سعر التذكرة والعملة صالحين'),
          ),
        ),
      );
    });

    test('handles datasource failures', () async {
      final failDatasource = _FailingTripsDatasource();
      final failRepo = TripsRepositoryImpl(failDatasource);
      final getTrips = GetOperationTripsUseCase(failRepo);

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

class _MockTripsDatasource implements TripsDatasource {
  final List<OperationTripModel> _trips = [];
  final List<TripPricingModel> _pricings = [];

  /// The office's fleet as the pairing model sees it: a driver either holds a bus or
  /// does not, and the bus is either in service or not. `driver-active` is the happy
  /// path; the other three are the states trip creation must refuse.
  final Map<String, TripDriverOption> _drivers = {
    'driver-active': const TripDriverOption(
      id: 'driver-active',
      name: 'أحمد حسن',
      phone: '01000000001',
      assignedVehicle: AssignedVehicle(
        id: 'vehicle-active',
        plateNumber: 'ق س أ 1234',
        vehicleCode: 'V-1',
        vehicleType: 'Hiace',
        brand: 'Toyota',
        model: 'Hiace',
        capacity: 14,
        status: 'active',
      ),
    ),
    'driver-no-vehicle': const TripDriverOption(
      id: 'driver-no-vehicle',
      name: 'سائق بلا مركبة',
      phone: '01000000002',
    ),
    'driver-vehicle-maintenance': const TripDriverOption(
      id: 'driver-vehicle-maintenance',
      name: 'سائق مركبته في الصيانة',
      phone: '01000000003',
      assignedVehicle: AssignedVehicle(
        id: 'vehicle-maintenance',
        plateNumber: 'ق س أ 9999',
        vehicleCode: 'V-2',
        vehicleType: 'Hiace',
        brand: 'Toyota',
        model: 'Hiace',
        capacity: 14,
        status: 'maintenance',
      ),
    ),
  };

  /// The last input handed to [createTrip], so a test can assert what the planner
  /// actually sends to the server.
  CreateTripInput? lastCreateInput;

  _MockTripsDatasource() {
    _trips.add(
      OperationTripModel(
        id: 'trip-1',
        routeId: 'route-1',
        route: 'بنها - القرية الذكية',
        routePoints: const [
          TripRoutePoint(id: 'st-1', name: 'بنها', order: 1),
          TripRoutePoint(id: 'st-2', name: 'شبرا', order: 2),
          TripRoutePoint(id: 'st-3', name: 'القرية الذكية', order: 3),
        ],
        driverId: 'driver-active',
        driver: 'أحمد حسن',
        vehicleId: 'vehicle-active',
        vehicle: 'ق س أ 1234',
        // Dated far ahead so this fixture stays publishable as the clock moves. The
        // publish gate added in 20260727160000 refuses a trip whose departure day has
        // already passed, which pinned the old fixed 2026-06-12 to a date that
        // eventually became the past.
        date: '2099-01-01',
        departure: '09:00',
        arrival: '10:30',
        status: OperationTripStatus.scheduled,
        capacity: 14,
        seats: [
          const TripSeat(
            id: 'seat-1',
            label: 'A1',
            row: 1,
            column: 1,
            state: TripSeatState.available,
          ),
          const TripSeat(
            id: 'seat-2',
            label: 'A2',
            row: 1,
            column: 2,
            state: TripSeatState.blocked,
          ),
          const TripSeat(
            id: 'seat-3',
            label: 'A3',
            row: 2,
            column: 1,
            state: TripSeatState.reserved,
            passengerId: 'pass-1',
          ),
        ],
        passengers: [
          const TripPassenger(
            id: 'pass-1',
            name: 'محمد علي',
            phone: '01234567890',
            seat: 'A3',
            pickup: 'بنها',
            dropoff: 'القرية الذكية',
            paymentMethod: 'cash',
            status: 'reserved',
          ),
        ],
        events: const [],
        notes: const [],
      ),
    );

    _trips.add(
      OperationTripModel(
        id: 'trip-2',
        routeId: 'route-1',
        route: 'بنها - القرية الذكية',
        routePoints: const [],
        driverId: 'driver-active',
        driver: 'أحمد حسن',
        vehicleId: 'vehicle-active',
        vehicle: 'ق س أ 1234',
        date: '2026-06-12',
        departure: '12:00',
        arrival: '',
        status: OperationTripStatus.inProgress,
        capacity: 14,
        seats: const [],
        passengers: const [],
        events: const [],
        notes: const [],
      ),
    );
  }

  @override
  Future<List<OperationTripModel>> fetchTrips() async {
    return _trips;
  }

  @override
  Future<OperationTripModel> fetchTripById(String tripId) async {
    return _trips.firstWhere((t) => t.id == tripId);
  }

  /// Stands in for `office_create_trip`: the vehicle, the capacity and the seat map all
  /// come from the driver's assignment, never from the caller.
  @override
  Future<OperationTripModel> createTrip(CreateTripInput input) async {
    lastCreateInput = input;
    final vehicle = _drivers[input.driverId]?.assignedVehicle;
    if (vehicle == null) {
      throw Exception('driver_has_no_vehicle');
    }
    final newTrip = OperationTripModel(
      id: 'trip-new',
      routeId: input.routeId,
      route: input.route,
      routePoints: const [],
      driverId: input.driverId,
      driver: input.driver,
      vehicleId: vehicle.id,
      vehicle: vehicle.plateNumber,
      date: input.date,
      departure: input.departure,
      arrival: input.arrival,
      ticketPrice: input.ticketPrice,
      currency: input.currency,
      status: OperationTripStatus.scheduled,
      capacity: vehicle.capacity,
      seats: List.generate(
        vehicle.capacity,
        (i) => TripSeat(
          id: 'seat-new-$i',
          label: 'S${i + 1}',
          row: (i ~/ 2) + 1,
          column: (i % 2) + 1,
          state: TripSeatState.available,
        ),
      ),
      passengers: const [],
      events: const [],
      notes: const [],
    );
    _trips.add(newTrip);
    return newTrip;
  }

  @override
  Future<OperationTripModel> updateTripInfo(OperationTrip trip) async {
    final idx = _trips.indexWhere((t) => t.id == trip.id);
    if (idx != -1) {
      _trips[idx] = OperationTripModel.fromEntity(trip);
      return _trips[idx];
    }
    throw Exception('Trip not found');
  }

  @override
  Future<void> deleteTrip(String tripId) async {
    _trips.removeWhere((trip) => trip.id == tripId);
  }

  @override
  Future<OperationTripModel> updateTripStatus(
    String tripId,
    OperationTripStatus status, {
    String? reason,
  }) async {
    final idx = _trips.indexWhere((t) => t.id == tripId);
    if (idx != -1) {
      final trip = _trips[idx];
      _trips[idx] = OperationTripModel.fromEntity(
        trip.copyWith(status: status),
      );
      return _trips[idx];
    }
    throw Exception('Trip not found');
  }

  String? lastCancelReason;
  StaleTripOutcome? lastStaleOutcome;

  @override
  Future<OperationTripModel> cancelTrip(String tripId, String reason) async {
    lastCancelReason = reason;
    return updateTripStatus(tripId, OperationTripStatus.cancelled);
  }

  @override
  Future<OperationTripModel> closeStaleTrip(
    String tripId,
    StaleTripOutcome outcome, {
    String? reason,
  }) async {
    lastStaleOutcome = outcome;
    return updateTripStatus(
      tripId,
      outcome == StaleTripOutcome.operated
          ? OperationTripStatus.completed
          : OperationTripStatus.cancelled,
    );
  }

  @override
  Future<OperationTripModel> updateSeatState(
    String tripId,
    String seatId,
    TripSeatState state,
  ) async {
    final idx = _trips.indexWhere((t) => t.id == tripId);
    if (idx != -1) {
      final trip = _trips[idx];
      final newSeats = trip.seats
          .map((s) => s.id == seatId ? s.copyWith(state: state) : s)
          .toList();
      _trips[idx] = OperationTripModel.fromEntity(
        trip.copyWith(seats: newSeats),
      );
      return _trips[idx];
    }
    throw Exception('Trip not found');
  }

  @override
  Future<OperationTripModel> updatePassenger(
    String tripId,
    TripPassenger passenger,
  ) async {
    final idx = _trips.indexWhere((t) => t.id == tripId);
    if (idx != -1) {
      final trip = _trips[idx];
      final newPassengers = trip.passengers
          .map((p) => p.id == passenger.id ? passenger : p)
          .toList();
      _trips[idx] = OperationTripModel.fromEntity(
        trip.copyWith(passengers: newPassengers),
      );
      return _trips[idx];
    }
    throw Exception('Trip not found');
  }

  @override
  Future<OperationTripModel> cancelPassenger(
    String tripId,
    String passengerId,
  ) async {
    final idx = _trips.indexWhere((t) => t.id == tripId);
    if (idx != -1) {
      final trip = _trips[idx];
      final newPassengers = trip.passengers
          .map((p) => p.id == passengerId ? p.copyWith(status: 'ملغي') : p)
          .toList();
      _trips[idx] = OperationTripModel.fromEntity(
        trip.copyWith(passengers: newPassengers),
      );
      return _trips[idx];
    }
    throw Exception('Trip not found');
  }

  @override
  Future<OperationTripModel> movePassenger(
    String tripId,
    String passengerId,
    String seatLabel,
  ) async {
    final idx = _trips.indexWhere((t) => t.id == tripId);
    if (idx != -1) {
      final trip = _trips[idx];
      final newPassengers = trip.passengers
          .map((p) => p.id == passengerId ? p.copyWith(seat: seatLabel) : p)
          .toList();
      _trips[idx] = OperationTripModel.fromEntity(
        trip.copyWith(passengers: newPassengers),
      );
      return _trips[idx];
    }
    throw Exception('Trip not found');
  }

  @override
  Future<List<TripPricingModel>> fetchTripPricing(String tripId) async {
    return _pricings.where((p) => p.tripId == tripId).toList();
  }

  @override
  Future<TripPricingModel> upsertTripPricing(TripPricing pricing) async {
    final model = TripPricingModel.fromEntity(pricing);
    final idx = _pricings.indexWhere((p) => p.id == pricing.id);
    if (idx != -1) {
      _pricings[idx] = model;
    } else {
      _pricings.add(model);
    }
    return model;
  }

  @override
  Future<TripPricingModel> toggleTripPricingStatus(
    String pricingId,
    bool isActive,
  ) async {
    final idx = _pricings.indexWhere((p) => p.id == pricingId);
    if (idx != -1) {
      _pricings[idx] = TripPricingModel.fromEntity(
        _pricings[idx].copyWith(isActive: isActive),
      );
      return _pricings[idx];
    }
    throw Exception('Pricing not found');
  }

  @override
  Future<List<TripEventModel>> fetchTripEvents(String tripId) async {
    return const [];
  }

  @override
  Future<List<TripDriverOption>> fetchActiveDrivers() async {
    return _drivers.values.toList();
  }

  @override
  Future<TripDriverOption?> fetchDriverAssignment(String driverId) async {
    return _drivers[driverId];
  }

  @override
  Future<List<Map<String, dynamic>>> fetchActiveRoutes() async {
    return [];
  }

  @override
  Future<List<Map<String, dynamic>>> fetchResourceConflicts({
    required String date,
    required String departureTime,
    required String arrivalTime,
  }) async {
    return [];
  }

  @override
  Future<String> getRouteStatus(String routeId) async {
    if (routeId == 'route-archived') return 'archived';
    return 'active';
  }

  @override
  Stream<void> watchTripsChanges() => const Stream.empty();

  @override
  Stream<void> watchTripChanges(String tripId) => const Stream.empty();

  @override
  Future<List<TripPricablePackage>> fetchOfficePricablePackages() async {
    return const [];
  }
}

class _FailingTripsDatasource implements TripsDatasource {
  @override
  Future<List<OperationTripModel>> fetchTrips() {
    throw StateError('failure');
  }

  @override
  Future<OperationTripModel> updateTripStatus(
    String tripId,
    OperationTripStatus status, {
    String? reason,
  }) {
    throw StateError('failure');
  }

  @override
  Future<OperationTripModel> cancelTrip(String tripId, String reason) {
    throw StateError('failure');
  }

  @override
  Future<OperationTripModel> closeStaleTrip(
    String tripId,
    StaleTripOutcome outcome, {
    String? reason,
  }) {
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
  Future<void> deleteTrip(String tripId) {
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

  @override
  Future<List<TripEventModel>> fetchTripEvents(String tripId) {
    throw StateError('failure');
  }

  @override
  Future<List<TripDriverOption>> fetchActiveDrivers() {
    throw StateError('failure');
  }

  @override
  Future<TripDriverOption?> fetchDriverAssignment(String driverId) {
    throw StateError('failure');
  }

  @override
  Future<List<Map<String, dynamic>>> fetchActiveRoutes() {
    throw StateError('failure');
  }

  @override
  Future<List<Map<String, dynamic>>> fetchResourceConflicts({
    required String date,
    required String departureTime,
    required String arrivalTime,
  }) {
    throw StateError('failure');
  }

  @override
  Future<String> getRouteStatus(String routeId) {
    throw StateError('failure');
  }

  @override
  Future<OperationTripModel> fetchTripById(String tripId) {
    throw StateError('failure');
  }

  @override
  Stream<void> watchTripsChanges() {
    throw StateError('failure');
  }

  @override
  Stream<void> watchTripChanges(String tripId) {
    throw StateError('failure');
  }

  @override
  Future<List<TripPricablePackage>> fetchOfficePricablePackages() {
    throw StateError('failure');
  }
}
