import '../../../shared/domain/entities/operation_trip.dart';
import '../../../shared/domain/entities/trip_pricing.dart';
import '../../../trip_management/domain/repositories/trips_repository.dart';

class CreateTripUseCase {
  final TripsRepository _repository;

  const CreateTripUseCase(this._repository);

  Future<OperationTrip> call(
    CreateTripInput input,
    List<TripPricing> pricing,
  ) async {
    final trip = await _repository.createTrip(input);
    final pricingRows = pricing.isNotEmpty
        ? pricing
        : _standardPricingFromTrip(trip, input.ticketPrice, input.currency);
    for (final p in pricingRows) {
      await _repository.upsertTripPricing(p.copyWith(tripId: trip.id));
    }
    return _repository.getTripById(trip.id);
  }

  List<TripPricing> _standardPricingFromTrip(
    OperationTrip trip,
    double ticketPrice,
    String currency,
  ) {
    final points = trip.routePoints;
    final now = DateTime.now();
    final rows = <TripPricing>[];
    for (var i = 0; i < points.length; i++) {
      for (var j = i + 1; j < points.length; j++) {
        rows.add(
          TripPricing(
            id: '',
            tripId: trip.id,
            fromPointId: points[i].id,
            toPointId: points[j].id,
            fromPointName: points[i].name,
            toPointName: points[j].name,
            fromPointOrder: points[i].order,
            toPointOrder: points[j].order,
            oneTimePrice: ticketPrice,
            fiveDaysPrice: ticketPrice,
            tenDaysPrice: ticketPrice,
            monthlyPrice: ticketPrice,
            threeMonthsPrice: ticketPrice,
            currency: currency,
            isActive: true,
            createdAt: now,
            updatedAt: now,
          ),
        );
      }
    }
    return rows;
  }
}

class GetActiveRoutesUseCase {
  final TripsRepository _repository;

  const GetActiveRoutesUseCase(this._repository);

  Future<List<Map<String, dynamic>>> call() {
    return _repository.getActiveRoutes();
  }
}

class GetActiveDriversUseCase {
  final TripsRepository _repository;

  const GetActiveDriversUseCase(this._repository);

  Future<List<Map<String, dynamic>>> call() {
    return _repository.getActiveDrivers();
  }
}

class GetActiveVehiclesUseCase {
  final TripsRepository _repository;

  const GetActiveVehiclesUseCase(this._repository);

  Future<List<Map<String, dynamic>>> call() {
    return _repository.getActiveVehicles();
  }
}
