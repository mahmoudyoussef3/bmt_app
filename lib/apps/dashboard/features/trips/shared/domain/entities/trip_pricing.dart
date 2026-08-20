class TripPricing {
  final String id;
  final String tripId;
  final String fromPointId;
  final String toPointId;
  final String fromPointName;
  final String toPointName;
  final int fromPointOrder;
  final int toPointOrder;
  final double oneTimePrice;

  /// This stop pair's price for each of the office's multi-ride packages,
  /// keyed by `transport_packages.id`. Backs `trip_package_prices` — see
  /// `20260815091000_per_package_trip_pricing.sql`. A package with no entry
  /// here has not been priced for this pair yet.
  final Map<String, double> packagePrices;

  /// The operator's optional note for each of those packages on this trip,
  /// keyed by `transport_packages.id`. Backs `trip_package_prices.note` — see
  /// `20260820100000_trip_scoped_packages.sql`. The planner writes the same
  /// note to every stop pair of a trip, exactly as it does the price.
  final Map<String, String> packageNotes;
  final String currency;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TripPricing({
    required this.id,
    required this.tripId,
    required this.fromPointId,
    required this.toPointId,
    required this.fromPointName,
    required this.toPointName,
    required this.fromPointOrder,
    required this.toPointOrder,
    required this.oneTimePrice,
    this.packagePrices = const {},
    this.packageNotes = const {},
    required this.currency,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  TripPricing copyWith({
    String? id,
    String? tripId,
    String? fromPointId,
    String? toPointId,
    String? fromPointName,
    String? toPointName,
    int? fromPointOrder,
    int? toPointOrder,
    double? oneTimePrice,
    Map<String, double>? packagePrices,
    Map<String, String>? packageNotes,
    String? currency,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TripPricing(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      fromPointId: fromPointId ?? this.fromPointId,
      toPointId: toPointId ?? this.toPointId,
      fromPointName: fromPointName ?? this.fromPointName,
      toPointName: toPointName ?? this.toPointName,
      fromPointOrder: fromPointOrder ?? this.fromPointOrder,
      toPointOrder: toPointOrder ?? this.toPointOrder,
      oneTimePrice: oneTimePrice ?? this.oneTimePrice,
      packagePrices: packagePrices ?? this.packagePrices,
      packageNotes: packageNotes ?? this.packageNotes,
      currency: currency ?? this.currency,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
