import '../../../shared/domain/entities/operation_trip.dart';
import '../../../shared/domain/entities/trip_pricing.dart';
import '../../../trip_management/domain/repositories/trips_repository.dart';

class CreateTripUseCase {
  final TripsRepository _repository;

  const CreateTripUseCase(this._repository);

  Future<OperationTrip> call(CreateTripInput input, List<TripPricing> pricing) async {
    final trip = await _repository.createTrip(input);
    for (final p in pricing) {
      await _repository.upsertTripPricing(p.copyWith(tripId: trip.id));
    }
    return _repository.getTripById(trip.id);
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
