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
    super.packagePrices,
    super.packageNotes,
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
      packagePrices: pricing.packagePrices,
      packageNotes: pricing.packageNotes,
      currency: pricing.currency,
      isActive: pricing.isActive,
      createdAt: pricing.createdAt,
      updatedAt: pricing.updatedAt,
    );
  }

  /// [json] is a `trip_pricing` row optionally carrying its nested
  /// `trip_package_prices(package_id, price, note)` join rows (see
  /// `SupabaseTripsDatasource._pricingSelect`). Missing/empty when the
  /// caller didn't request the nested select.
  factory TripPricingModel.fromJson(Map<String, dynamic> json) {
    final packageRows = json['trip_package_prices'] as List? ?? const [];
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
      packagePrices: {
        for (final row in packageRows.whereType<Map<String, dynamic>>())
          if (row['package_id'] != null)
            row['package_id'].toString(): (row['price'] as num).toDouble(),
      },
      packageNotes: {
        for (final row in packageRows.whereType<Map<String, dynamic>>())
          if (row['package_id'] != null &&
              (row['note']?.toString().trim().isNotEmpty ?? false))
            row['package_id'].toString(): row['note'].toString(),
      },
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

  /// The `trip_pricing` row alone — `packagePrices`/`packageNotes` are
  /// written separately to `trip_package_prices` by the datasource, not
  /// through this row's json.
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
      'currency': currency,
      'is_active': isActive,
    };
  }
}
