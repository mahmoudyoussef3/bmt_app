// Money formatting for every Client surface that prices a trip. Supabase stores
// amounts as bare numerics, and a missing or zero amount means "not priced yet"
// — which the UI says out loud rather than rendering as a fake `EGP 0`.

/// The cheapest published fare on a trip row, e.g. `EGP 100`. Empty when the
/// dashboard has not priced the trip.
String tripFareLabel(Map<String, dynamic> trip) {
  final fallbackCurrency = trip['currency']?.toString() ?? 'EGP';
  var best = <String, dynamic>{};
  double? bestAmount;

  void offer(num? amount, String currency) {
    final value = amount?.toDouble();
    if (value == null || value <= 0) return;
    if (bestAmount != null && value >= bestAmount!) return;
    bestAmount = value;
    best = {'amount': value, 'currency': currency};
  }

  final pricingRows = trip['trip_pricing'];
  if (pricingRows is List) {
    for (final row in pricingRows) {
      if (row is! Map<String, dynamic>) continue;
      if (!(row['is_active'] as bool? ?? true)) continue;
      offer(
        row['one_time_price'] as num?,
        row['currency']?.toString() ?? fallbackCurrency,
      );
    }
  }
  offer(trip['ticket_price'] as num?, fallbackCurrency);

  if (bestAmount == null) return '';
  return moneyLabel(best['amount'] as double, best['currency'] as String);
}

/// An amount with its currency, e.g. `EGP 100`. Empty when there is nothing to
/// show.
String moneyLabel(num? amount, [String currency = 'EGP']) {
  final value = amount?.toDouble();
  if (value == null || value <= 0) return '';
  final formatted = value == value.roundToDouble()
      ? value.round().toString()
      : value.toStringAsFixed(2);
  return '$currency $formatted';
}
