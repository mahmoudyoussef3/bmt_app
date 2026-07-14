import 'package:bmt_app/core/tracking/progress/route_stop.dart';

/// Maps `trip_route_points` rows into the trip's ordered stop list.
abstract final class TrackingStopsModel {
  /// Builds the stops in route order.
  ///
  /// The rows are sorted by `point_order` here rather than trusting the order
  /// Postgres happened to return them in: every downstream consumer (the map
  /// polyline, the progress engine's along-route projection, the rider's
  /// timeline) treats index order as route order, so one mis-ordered row
  /// silently corrupts distances, ETAs and stop states alike.
  static List<RouteStop> fromRows(
    List<Map<String, dynamic>> rows, {
    String? tripDate,
    DateTime? departureAt,
  }) {
    final ordered = [...rows]
      ..sort((a, b) => _order(a).compareTo(_order(b)));

    return [
      for (final row in ordered)
        RouteStop(
          id: row['id']?.toString(),
          name: (row['point_name'] as String? ?? '').trim(),
          latitude: (row['latitude'] as num?)?.toDouble() ?? 0,
          longitude: (row['longitude'] as num?)?.toDouble() ?? 0,
          order: _order(row),
          plannedArrival: stopTime(
            tripDate,
            row['arrival_offset']?.toString(),
            departureAt,
          ),
          plannedDeparture: stopTime(
            tripDate,
            row['departure_offset']?.toString(),
            departureAt,
          ),
        ),
    ];
  }

  static int _order(Map<String, dynamic> row) =>
      (row['point_order'] as num?)?.toInt() ?? 0;

  /// Resolves a stop's "HH:mm" clock time against the trip date. A time more
  /// than six hours *before* departure belongs to a run that crosses midnight,
  /// so it rolls forward a day.
  static DateTime? stopTime(
    String? date,
    String? clockTime,
    DateTime? departureAt,
  ) {
    final parsed = combineDateAndTime(date, clockTime);
    if (parsed == null || departureAt == null) return parsed;
    return departureAt.difference(parsed).inHours >= 6
        ? parsed.add(const Duration(days: 1))
        : parsed;
  }

  static DateTime? combineDateAndTime(String? date, String? time) {
    if (date == null || date.isEmpty || time == null || time.isEmpty) {
      return null;
    }
    return DateTime.tryParse('${date}T$time')?.toLocal();
  }
}
