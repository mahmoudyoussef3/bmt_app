import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/features/trips/shared/domain/entities/operation_trip.dart';
import 'package:bmt_app/apps/dashboard/features/trips/shared/domain/entities/trip_lifecycle.dart';
import 'package:bmt_app/apps/dashboard/features/trips/shared/domain/entities/trip_pricing.dart';
import 'package:bmt_app/apps/dashboard/features/trips/shared/data/models/operation_trip_model.dart';
import 'package:bmt_app/apps/dashboard/features/trips/shared/data/models/trip_pricing_model.dart';
import 'package:bmt_app/apps/dashboard/features/trips/trip_management/domain/repositories/trips_repository.dart';
import 'package:bmt_app/apps/dashboard/features/trips/trip_management/data/repositories/trips_repository_impl.dart';
import 'package:bmt_app/apps/dashboard/features/trips/trip_management/data/datasources/trips_datasource.dart';
import 'package:bmt_app/apps/dashboard/features/trips/trip_management/domain/usecases/trip_management_usecases.dart';
import 'package:bmt_app/apps/dashboard/features/trips/trip_creation/domain/usecases/trip_creation_usecases.dart';
import 'package:bmt_app/apps/dashboard/features/trips/trip_seats/domain/usecases/trip_seats_usecases.dart';
import 'package:bmt_app/apps/dashboard/features/trips/trip_passengers/domain/usecases/trip_passengers_usecases.dart';
import 'package:bmt_app/apps/dashboard/features/trips/trip_pricing/domain/usecases/trip_pricing_usecases.dart';

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

    test('creates trip with validations', () async {
      final createTrip = CreateTripUseCase(repository);

      // 1. Success case
      final input = const CreateTripInput(
        routeId: 'route-1',
        route: 'بنها - القرية الذكية',
        driverId: 'driver-active',
        driver: 'أحمد حسن',
        vehicleId: 'vehicle-active',
        vehicle: 'ق س أ 1234',
        date: '2026-06-12',
        departure: '09:00',
        arrival: '10:30',
        ticketPrice: 75,
        capacity: 14,
      );

      final created = await createTrip(input, []);
      expect(created.id, isNotEmpty);
      expect(created.driver, 'أحمد حسن');
      expect(created.vehicle, 'ق س أ 1234');

      // 2. Route archived validation
      final inputArchivedRoute = const CreateTripInput(
        routeId: 'route-archived',
        route: 'بنها - القرية الذكية',
        driverId: 'driver-active',
        driver: 'أحمد حسن',
        vehicleId: 'vehicle-active',
        vehicle: 'ق س أ 1234',
        date: '2026-06-12',
        departure: '09:00',
        arrival: '10:30',
        ticketPrice: 75,
        capacity: 14,
      );
      expect(
        () => createTrip(inputArchivedRoute, []),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('لا يمكن جدولة رحلة لمسار مؤرشف'),
          ),
        ),
      );

      // 3. Driver suspended validation
      final inputSuspendedDriver = const CreateTripInput(
        routeId: 'route-1',
        route: 'بنها - القرية الذكية',
        driverId: 'driver-suspended',
        driver: 'أحمد حسن',
        vehicleId: 'vehicle-active',
        vehicle: 'ق س أ 1234',
        date: '2026-06-12',
        departure: '09:00',
        arrival: '10:30',
        ticketPrice: 75,
        capacity: 14,
      );
      expect(
        () => createTrip(inputSuspendedDriver, []),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('السائق غير نشط'),
          ),
        ),
      );

      // 4. Vehicle maintenance validation
      final inputMaintenanceVehicle = const CreateTripInput(
        routeId: 'route-1',
        route: 'بنها - القرية الذكية',
        driverId: 'driver-active',
        driver: 'أحمد حسن',
        vehicleId: 'vehicle-maintenance',
        vehicle: 'ق س أ 1234',
        date: '2026-06-12',
        departure: '09:00',
        arrival: '10:30',
        ticketPrice: 75,
        capacity: 14,
      );
      expect(
        () => createTrip(inputMaintenanceVehicle, []),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('المركبة غير متاحة للتشغيل'),
          ),
        ),
      );

      // 5. Duplicate trip validation
      final inputDuplicate = const CreateTripInput(
        routeId: 'route-1',
        route: 'بنها - القرية الذكية',
        driverId: 'driver-active',
        driver: 'أحمد حسن',
        vehicleId: 'vehicle-active',
        vehicle: 'ق س أ 1234',
        date: '2026-06-12',
        departure: 'duplicate-time',
        arrival: '10:30',
        ticketPrice: 75,
        capacity: 14,
      );
      expect(
        () => createTrip(inputDuplicate, []),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('توجد رحلة مجدولة بالفعل'),
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
        fiveDaysPrice: 220.0,
        tenDaysPrice: 400.0,
        monthlyPrice: 1000.0,
        threeMonthsPrice: 2800.0,
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

  @override
  Future<OperationTripModel> createTrip(CreateTripInput input) async {
    final newTrip = OperationTripModel(
      id: 'trip-new',
      routeId: input.routeId,
      route: input.route,
      routePoints: const [],
      driverId: input.driverId,
      driver: input.driver,
      vehicleId: input.vehicleId,
      vehicle: input.vehicle,
      date: input.date,
      departure: input.departure,
      arrival: input.arrival,
      ticketPrice: input.ticketPrice,
      currency: input.currency,
      status: OperationTripStatus.scheduled,
      capacity: input.capacity,
      seats: List.generate(
        input.capacity,
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
  Future<List<Map<String, dynamic>>> fetchActiveDrivers() async {
    return [];
  }

  @override
  Future<List<Map<String, dynamic>>> fetchActiveVehicles() async {
    return [];
  }

  @override
  Future<List<Map<String, dynamic>>> fetchActiveRoutes() async {
    return [];
  }

  @override
  Future<bool> checkDuplicateTrip(
    String vehicleId,
    String date,
    String departureTime,
  ) async {
    return departureTime == 'duplicate-time';
  }

  @override
  Future<bool> checkDriverTripConflict(
    String driverId,
    String date,
    String departureTime,
  ) async {
    return false;
  }

  @override
  Future<String> getDriverStatus(String driverId) async {
    if (driverId == 'driver-active') return 'active';
    return 'suspended';
  }

  @override
  Future<String> getVehicleStatus(String vehicleId) async {
    if (vehicleId == 'vehicle-active') return 'active';
    return 'maintenance';
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
  Future<List<Map<String, dynamic>>> fetchActiveDrivers() {
    throw StateError('failure');
  }

  @override
  Future<List<Map<String, dynamic>>> fetchActiveVehicles() {
    throw StateError('failure');
  }

  @override
  Future<List<Map<String, dynamic>>> fetchActiveRoutes() {
    throw StateError('failure');
  }

  @override
  Future<bool> checkDuplicateTrip(
    String vehicleId,
    String date,
    String departureTime,
  ) {
    throw StateError('failure');
  }

  @override
  Future<bool> checkDriverTripConflict(
    String driverId,
    String date,
    String departureTime,
  ) {
    throw StateError('failure');
  }

  @override
  Future<String> getDriverStatus(String driverId) {
    throw StateError('failure');
  }

  @override
  Future<String> getVehicleStatus(String vehicleId) {
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
}
