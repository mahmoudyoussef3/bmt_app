import '../../domain/entities/trip_stop.dart';

/// Maps raw `trip_route_points` rows into the trip's ordered stop list, marking
/// the two stops that belong to this rider.
///
/// The rows are sorted by `point_order` here rather than trusting the order
/// Postgres returned them in: every reader downstream treats index order as
/// route order, and one mis-ordered row turns a corridor into a wrong story
/// about where the bus goes.
abstract final class TripStopMapper {
  static List<TripStop> fromRows(
    List<Map<String, dynamic>> rows, {
    String pickupPointId = '',
    String dropoffPointId = '',
    String pickupPointName = '',
    String dropoffPointName = '',
  }) {
    final ordered = [...rows]..sort((a, b) => _order(a).compareTo(_order(b)));

    final boarding = _indexOf(ordered, pickupPointId, pickupPointName);
    final dropoff = _indexOf(ordered, dropoffPointId, dropoffPointName);

    return [
      for (var i = 0; i < ordered.length; i++)
        TripStop(
          id: ordered[i]['id']?.toString() ?? '',
          stationId: ordered[i]['route_point_id']?.toString() ?? '',
          name: (ordered[i]['point_name']?.toString() ?? '').trim(),
          order: _order(ordered[i]),
          arrivalOffset: ordered[i]['arrival_offset']?.toString().trim() ?? '',
          departureOffset:
              ordered[i]['departure_offset']?.toString().trim() ?? '',
          latitude: (ordered[i]['latitude'] as num?)?.toDouble(),
          longitude: (ordered[i]['longitude'] as num?)?.toDouble(),
          isBoarding: i == boarding,
          isDropoff: i == dropoff,
        ),
    ];
  }

  /// Which stop is the rider's, or `-1`.
  ///
  /// By id first: a booking's `pickup_point_id` is a **route_stations** id and
  /// `trip_route_points.route_point_id` is the bridge back to it, so that
  /// comparison is exact even where two stations share a name. The name pass
  /// runs only when the id matched nothing — bookings written before points
  /// were recorded carry a name and nothing else, and a trip whose points were
  /// re-snapshotted no longer holds the id the booking stored.
  static int _indexOf(List<Map<String, dynamic>> rows, String id, String name) {
    if (id.trim().isNotEmpty) {
      final byId = rows.indexWhere(
        (row) => row['route_point_id']?.toString() == id.trim(),
      );
      if (byId >= 0) return byId;
    }

    final wanted = name.trim().toLowerCase();
    if (wanted.isEmpty) return -1;
    return rows.indexWhere(
      (row) =>
          (row['point_name']?.toString() ?? '').trim().toLowerCase() == wanted,
    );
  }

  static int _order(Map<String, dynamic> row) =>
      (row['point_order'] as num?)?.toInt() ?? 0;
}
