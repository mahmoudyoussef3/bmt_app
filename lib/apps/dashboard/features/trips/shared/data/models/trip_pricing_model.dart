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

  factory TripPricingModel.fromJson(Map<String, dynamic> json) {
    return TripPricingModel(
      id: json['id'] as String? ?? '',
      tripId: json['trip_id'] as String? ?? '',
      fromPointId: json['from_point_id'] as String? ?? '',
      toPointId: json['to_point_id'] as String? ?? '',
      fromPointName: json['from_point_name'] as String? ?? '',
      toPointName: json['to_point_name'] as String? ?? '',
      fromPointOrder: json['from_point_order'] as int? ?? 0,
      toPointOrder: json['to_point_order'] as int? ?? 0,
      oneTimePrice: (json['one_time_price'] as num? ?? 0).toDouble(),
      fiveDaysPrice: (json['five_days_price'] as num? ?? 0).toDouble(),
      tenDaysPrice: (json['ten_days_price'] as num? ?? 0).toDouble(),
      monthlyPrice: (json['monthly_price'] as num? ?? 0).toDouble(),
      threeMonthsPrice: (json['three_months_price'] as num? ?? 0).toDouble(),
      currency: json['currency'] as String? ?? 'ج.م',
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String).toLocal()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String).toLocal()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'trip_id': tripId,
      'from_point_id': fromPointId,
      'to_point_id': toPointId,
      'from_point_name': fromPointName,
      'to_point_name': toPointName,
      'from_point_order': fromPointOrder,
      'to_point_order': toPointOrder,
      'one_time_price': oneTimePrice,
      'five_days_price': fiveDaysPrice,
      'ten_days_price': tenDaysPrice,
      'monthly_price': monthlyPrice,
      'three_months_price': threeMonthsPrice,
      'currency': currency,
      'is_active': isActive,
    };
  }
}
