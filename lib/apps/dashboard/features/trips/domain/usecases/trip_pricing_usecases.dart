import '../entities/trip_pricing.dart';
import '../repositories/trips_repository.dart';

class GetTripPricingUseCase {
  final TripsRepository _repository;

  const GetTripPricingUseCase(this._repository);

  Future<List<TripPricing>> call(String tripId) {
    return _repository.getTripPricing(tripId);
  }
}

class SaveTripSegmentPricingUseCase {
  final TripsRepository _repository;
  final ValidateTripPricingUseCase _validate;

  const SaveTripSegmentPricingUseCase(this._repository, this._validate);

  Future<TripPricing> call(TripPricing pricing) {
    _validate(pricing);
    return _repository.upsertTripPricing(pricing);
  }
}

class ToggleTripSegmentPricingUseCase {
  final TripsRepository _repository;

  const ToggleTripSegmentPricingUseCase(this._repository);

  Future<TripPricing> call(String pricingId, bool isActive) {
    return _repository.toggleTripPricingStatus(pricingId, isActive);
  }
}

class ValidateTripPricingUseCase {
  const ValidateTripPricingUseCase();

  void call(TripPricing pricing) {
    if (pricing.tripId.trim().isEmpty) {
      throw ArgumentError('tripId is required');
    }
    if (pricing.currency.trim().isEmpty) {
      throw ArgumentError('currency is required');
    }
    if (pricing.fromPointId == pricing.toPointId) {
      throw ArgumentError('fromPoint and toPoint must be different');
    }
    if (pricing.fromPointOrder >= pricing.toPointOrder) {
      throw ArgumentError('fromPoint order must be before toPoint order');
    }
    if (pricing.oneTimePrice <= 0 ||
        pricing.fiveDaysPrice <= 0 ||
        pricing.tenDaysPrice <= 0 ||
        pricing.monthlyPrice <= 0 ||
        pricing.threeMonthsPrice <= 0) {
      throw ArgumentError('all pricing fields must be greater than zero');
    }
  }
}
