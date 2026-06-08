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
  final double fiveDaysPrice;
  final double tenDaysPrice;
  final double monthlyPrice;
  final double threeMonthsPrice;
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
    required this.fiveDaysPrice,
    required this.tenDaysPrice,
    required this.monthlyPrice,
    required this.threeMonthsPrice,
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
    double? fiveDaysPrice,
    double? tenDaysPrice,
    double? monthlyPrice,
    double? threeMonthsPrice,
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
      fiveDaysPrice: fiveDaysPrice ?? this.fiveDaysPrice,
      tenDaysPrice: tenDaysPrice ?? this.tenDaysPrice,
      monthlyPrice: monthlyPrice ?? this.monthlyPrice,
      threeMonthsPrice: threeMonthsPrice ?? this.threeMonthsPrice,
      currency: currency ?? this.currency,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
