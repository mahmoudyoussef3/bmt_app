import '../../../shared/domain/entities/trip_pricing.dart';
import '../../../trip_management/domain/repositories/trips_repository.dart';

class GetTripPricingUseCase {
  final TripsRepository _repository;

  const GetTripPricingUseCase(this._repository);

  Future<List<TripPricing>> call(String tripId) {
    return _repository.getTripPricing(tripId);
  }
}

class SaveTripPricingUseCase {
  final TripsRepository _repository;

  const SaveTripPricingUseCase(this._repository);

  Future<TripPricing> call(TripPricing pricing) {
    return _repository.upsertTripPricing(pricing);
  }
}

class ToggleTripPricingUseCase {
  final TripsRepository _repository;

  const ToggleTripPricingUseCase(this._repository);

  Future<TripPricing> call(String pricingId, bool isActive) {
    return _repository.toggleTripPricingStatus(pricingId, isActive);
  }
}
