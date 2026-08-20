import 'trip_stop_pair_price.dart';

/// Builds [TripStopPairPrice] rows from a raw Supabase `trip_pricing(*)`
/// join result (a `List` of row maps). Shared by every datasource that
/// joins `operation_trips` to `trip_pricing` so they all parse the same
/// from_point_id/to_point_id + tier columns the same way — see CLAUDE.md
/// section 6 (shared logic belongs in `core/`).
///
/// `trip_pricing.from_point_id` / `to_point_id` hold **`trip_route_points`
/// ids** — the per-trip snapshot the Dashboard takes of the route's stations
/// when the trip is created — while a rider picks their pickup/dropoff from
/// `route_stations`. Those are two disjoint id spaces, so a pricing row can
/// only be matched to the rider's stop pair after translating one into the
/// other. Pass [stationIds] (from [routeStationIdsFromJson]) to get rows keyed
/// by `route_stations` ids, which is what every caller compares against.
/// A row whose points are absent from the map keeps its original ids.
List<TripStopPairPrice> tripStopPairPricesFromJson(
  dynamic rows, {
  Map<String, String> stationIds = const {},
}) {
  if (rows is! List) return const [];
  return rows
      .whereType<Map<String, dynamic>>()
      .map((row) {
        final from = row['from_point_id']?.toString() ?? '';
        final to = row['to_point_id']?.toString() ?? '';
        final packageRows = row['trip_package_prices'] as List? ?? const [];
        return TripStopPairPrice(
          fromPointId: stationIds[from] ?? from,
          toPointId: stationIds[to] ?? to,
          oneTimePrice: (row['one_time_price'] as num?)?.toDouble() ?? 0,
          packagePrices: {
            for (final packageRow
                in packageRows.whereType<Map<String, dynamic>>())
              if (packageRow['package_id'] != null)
                packageRow['package_id'].toString():
                    (packageRow['price'] as num).toDouble(),
          },
          packageNotes: {
            for (final packageRow
                in packageRows.whereType<Map<String, dynamic>>())
              if (packageRow['package_id'] != null &&
                  (packageRow['note']?.toString().trim().isNotEmpty ?? false))
                packageRow['package_id'].toString(): packageRow['note']
                    .toString(),
          },
          currency: row['currency']?.toString() ?? 'EGP',
          isActive: row['is_active'] as bool? ?? true,
        );
      })
      .where((row) => row.fromPointId.isNotEmpty && row.toPointId.isNotEmpty)
      .toList();
}

/// The `trip_route_points.id -> route_stations.id` translation for one trip,
/// built from a raw `trip_route_points(id, route_point_id)` join result.
Map<String, String> routeStationIdsFromJson(dynamic rows) {
  if (rows is! List) return const {};
  final stationIds = <String, String>{};
  for (final row in rows.whereType<Map<String, dynamic>>()) {
    final tripPointId = row['id']?.toString() ?? '';
    final stationId = row['route_point_id']?.toString() ?? '';
    if (tripPointId.isEmpty || stationId.isEmpty) continue;
    stationIds[tripPointId] = stationId;
  }
  return stationIds;
}
