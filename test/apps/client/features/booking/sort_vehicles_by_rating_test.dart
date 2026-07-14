import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/booking/domain/entities/vehicle_detail.dart';
import 'package:bmt_app/apps/client/features/booking/domain/usecases/sort_vehicles_usecase.dart';

VehicleDetailData _vehicle({
  required String id,
  double driverRating = 0,
  int driverRatingCount = 0,
  double vehicleRating = 0,
  int vehicleRatingCount = 0,
  int availableSeats = 10,
}) {
  return VehicleDetailData(
    id: id,
    name: 'Coach $id',
    model: 'Model',
    vehicleType: 'Bus',
    imageLabels: const [],
    hasAirConditioning: true,
    seatType: 'Standard',
    driverName: 'Driver $id',
    price: 'EGP 100',
    capacity: 14,
    availableSeats: availableSeats,
    estimatedArrival: '10:00',
    routeDuration: '2h',
    departureTime: '08:00',
    driverRating: driverRating,
    driverRatingCount: driverRatingCount,
    vehicleRating: vehicleRating,
    vehicleRatingCount: vehicleRatingCount,
  );
}

void main() {
  const sort = SortVehiclesUseCase();

  group('SortVehiclesUseCase rating', () {
    test('ranks the best-reviewed captain and vehicle first', () {
      final sorted = sort(
        [
          _vehicle(
            id: 'ok',
            driverRating: 3.5,
            driverRatingCount: 4,
            vehicleRating: 3.5,
            vehicleRatingCount: 4,
          ),
          _vehicle(
            id: 'great',
            driverRating: 4.9,
            driverRatingCount: 10,
            vehicleRating: 4.7,
            vehicleRatingCount: 10,
          ),
        ],
        VehicleSortOption.rating,
      );

      expect(sorted.map((v) => v.id), ['great', 'ok']);
    });

    test('sorts an unrated trip last — no rating is not a perfect one', () {
      final sorted = sort(
        [
          // Plenty of free seats, but nobody has reviewed it. It used to top
          // this list, because "sort by rating" secretly sorted by seats.
          _vehicle(id: 'unrated', availableSeats: 14),
          _vehicle(
            id: 'rated',
            driverRating: 4.2,
            driverRatingCount: 6,
            availableSeats: 2,
          ),
        ],
        VehicleSortOption.rating,
      );

      expect(sorted.map((v) => v.id), ['rated', 'unrated']);
    });

    test('averages captain and vehicle when both have been reviewed', () {
      final vehicle = _vehicle(
        id: 'v',
        driverRating: 5,
        driverRatingCount: 3,
        vehicleRating: 3,
        vehicleRatingCount: 3,
      );

      expect(vehicle.combinedRating, 4.0);
    });

    test('a captain-only rating stands on its own', () {
      final vehicle = _vehicle(
        id: 'v',
        driverRating: 4.5,
        driverRatingCount: 2,
      );

      expect(vehicle.hasVehicleRating, isFalse);
      expect(vehicle.combinedRating, 4.5);
    });
  });
}
