import 'trip_stop_pair_price.dart';

/// Builds [TripStopPairPrice] rows from a raw Supabase `trip_pricing(*)`
/// join result (a `List` of row maps). Shared by every datasource that
/// joins `operation_trips` to `trip_pricing` so they all parse the same
/// from_point_id/to_point_id + tier columns the same way — see CLAUDE.md
/// section 6 (shared logic belongs in `core/`).
List<TripStopPairPrice> tripStopPairPricesFromJson(dynamic rows) {
  if (rows is! List) return const [];
  return rows
      .whereType<Map<String, dynamic>>()
      .map(
        (row) => TripStopPairPrice(
          fromPointId: row['from_point_id']?.toString() ?? '',
          toPointId: row['to_point_id']?.toString() ?? '',
          oneTimePrice: (row['one_time_price'] as num?)?.toDouble() ?? 0,
          fiveDaysPrice: (row['five_days_price'] as num?)?.toDouble() ?? 0,
          tenDaysPrice: (row['ten_days_price'] as num?)?.toDouble() ?? 0,
          monthlyPrice: (row['monthly_price'] as num?)?.toDouble() ?? 0,
          threeMonthsPrice:
              (row['three_months_price'] as num?)?.toDouble() ?? 0,
          currency: row['currency']?.toString() ?? 'EGP',
          isActive: row['is_active'] as bool? ?? true,
        ),
      )
      .where((row) => row.fromPointId.isNotEmpty && row.toPointId.isNotEmpty)
      .toList();
}
