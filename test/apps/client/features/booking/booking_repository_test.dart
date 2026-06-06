import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/booking/data/datasources/mock_booking_search_datasource.dart';
import 'package:bmt_app/apps/client/features/booking/data/datasources/mock_daily_booking_datasource.dart';
import 'package:bmt_app/apps/client/features/booking/data/datasources/mock_vehicle_booking_datasource.dart';
import 'package:bmt_app/apps/client/features/booking/data/repositories/booking_repository_impl.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_search_query.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/vehicle_detail.dart';
import 'package:bmt_app/apps/client/features/booking/domain/usecases/get_booking_hub_data_usecase.dart';
import 'package:bmt_app/apps/client/features/booking/domain/usecases/get_booking_routes_usecase.dart';
import 'package:bmt_app/apps/client/features/booking/domain/usecases/get_daily_booking_data_usecase.dart';
import 'package:bmt_app/apps/client/features/booking/domain/usecases/get_map_pins_usecase.dart';
import 'package:bmt_app/apps/client/features/booking/domain/usecases/get_vehicle_details_usecase.dart';
import 'package:bmt_app/apps/client/features/booking/domain/usecases/get_vehicles_usecase.dart';
import 'package:bmt_app/apps/client/features/booking/domain/usecases/sort_vehicles_usecase.dart';

void main() {
  group('Client booking repository', () {
    late BookingRepositoryImpl repository;

    setUp(() {
      repository = const BookingRepositoryImpl(
        searchDatasource: MockBookingSearchDatasource(),
        dailyBookingDatasource: MockDailyBookingDatasource(),
        vehicleDatasource: MockVehicleBookingDatasource(),
      );
    });

    test('returns booking hub summary through use case', () async {
      final data = await GetBookingHubDataUseCase(repository)();

      expect(data.todayRoutes, '3 routes');
      expect(data.monthPlans, '2 plans');
      expect(data.activeTrips, '3');
      expect(data.reservedSeats, '27');
    });

    test('returns daily booking flow data through use case', () async {
      final data = await GetDailyBookingDataUseCase(repository)();

      expect(data.pickupPoints.first, 'Banha Station');
      expect(data.destinations, contains('Smart Village'));
      expect(data.arrivalTimes, hasLength(4));
      expect(data.vehicles.first.id, 'MT-2847');
      expect(data.vehicles.last.seatsLeft, 6);
    });

    test('returns route options for the current search query', () async {
      final getRoutes = GetBookingRoutesUseCase(repository);
      final routes = await getRoutes(
        const BookingSearchQuery(
          pickup: 'Banha Station',
          destination: 'Nasr City',
        ),
      );

      expect(routes, hasLength(3));
      expect(routes.first.pickup, 'Banha Station');
      expect(routes.first.destination, 'Nasr City');
      expect(routes.first.isFastest, isTrue);
    });

    test('returns map pins without presentation dependencies', () async {
      final getMapPins = GetMapPinsUseCase(repository);
      final pins = await getMapPins();

      expect(pins.pickup.first.label, 'Banha Center');
      expect(pins.pickup.first.x, 0.28);
      expect(pins.destination.first.label, 'Smart Village');
      expect(pins.destination.first.y, 0.32);
    });

    test('returns and sorts vehicles through use cases', () async {
      final vehicles = await GetVehiclesUseCase(repository)();
      final sorted = const SortVehiclesUseCase()(
        vehicles,
        VehicleSortOption.priceLow,
      );

      expect(vehicles, hasLength(4));
      expect(sorted.first.id, 'MB-22-1093');
      expect(sorted.first.price, 'EGP 78');
    });

    test('returns selected vehicle details by id', () async {
      final vehicle = await GetVehicleDetailsUseCase(repository)('MB-31-4450');

      expect(vehicle, isNotNull);
      expect(vehicle!.name, 'Executive Van Plus');
      expect(vehicle.driverInitials, 'OF');
    });
  });
}
