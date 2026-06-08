import '../../domain/entities/trip_pricing.dart';

class TripPricingModel extends TripPricing {
  const TripPricingModel({
    required super.id,
    required super.tripId,
    required super.fromPointId,
    required super.toPointId,
    required super.fromPointName,
    required super.toPointName,
    required super.fromPointOrder,
    required super.toPointOrder,
    required super.oneTimePrice,
    required super.fiveDaysPrice,
    required super.tenDaysPrice,
    required super.monthlyPrice,
    required super.threeMonthsPrice,
    required super.currency,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
  });

  factory TripPricingModel.fromEntity(TripPricing pricing) {
    return TripPricingModel(
      id: pricing.id,
      tripId: pricing.tripId,
      fromPointId: pricing.fromPointId,
      toPointId: pricing.toPointId,
      fromPointName: pricing.fromPointName,
      toPointName: pricing.toPointName,
      fromPointOrder: pricing.fromPointOrder,
      toPointOrder: pricing.toPointOrder,
      oneTimePrice: pricing.oneTimePrice,
      fiveDaysPrice: pricing.fiveDaysPrice,
      tenDaysPrice: pricing.tenDaysPrice,
      monthlyPrice: pricing.monthlyPrice,
      threeMonthsPrice: pricing.threeMonthsPrice,
      currency: pricing.currency,
      isActive: pricing.isActive,
      createdAt: pricing.createdAt,
      updatedAt: pricing.updatedAt,
    );
  }
}
