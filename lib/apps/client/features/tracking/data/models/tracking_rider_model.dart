import '../../domain/entities/tracking_rider.dart';

/// Maps the rider's own `trip_passengers` manifest row, resolving their
/// boarding and drop-off points to positions in the trip's ordered stop list.
abstract final class TrackingRiderModel {
  /// [pointRows] must already be sorted in route order — the returned indices
  /// point into that list.
  static TrackingRider fromRows({
    required Map<String, dynamic>? passengerRow,
    required List<Map<String, dynamic>> pointRows,
    String? bookingStatus,
  }) {
    // A trip can have no readable manifest row for this rider and still have a
    // booking — the booking status is what gates tracking and the boarding
    // action, so it is carried either way.
    if (passengerRow == null) {
      return TrackingRider(bookingStatus: bookingStatus);
    }

    final boardingName = _text(passengerRow['pickup_point_name']);
    final dropoffName = _text(passengerRow['dropoff_point_name']);

    return TrackingRider(
      seatLabel: _text(passengerRow['seat_label']),
      boardingName: boardingName,
      dropoffName: dropoffName,
      boardingPointId: _text(passengerRow['pickup_point_id']),
      boardingIndex: _indexOf(
        pointRows,
        pointId: _text(passengerRow['pickup_point_id']),
        name: boardingName,
      ),
      dropoffIndex: _indexOf(
        pointRows,
        pointId: _text(passengerRow['dropoff_point_id']),
        name: dropoffName,
      ),
      status: _text(passengerRow['status']),
      bookingStatus: bookingStatus,
    );
  }

  /// Finds a manifest point among the trip's stops.
  ///
  /// The id is tried first: `trip_passengers.pickup_point_id` and
  /// `trip_route_points.route_point_id` both reference the route's master
  /// station, so that match is exact. Names are only a fallback, because two
  /// stations can legitimately share a name and an operator can rename one
  /// after the booking was made — matching on a stale name would put the
  /// rider's badge on the wrong stop, which is worse than not badging it.
  static int? _indexOf(
    List<Map<String, dynamic>> pointRows, {
    String? pointId,
    String? name,
  }) {
    if (pointId != null) {
      final byId = pointRows.indexWhere(
        (row) => _text(row['route_point_id']) == pointId,
      );
      if (byId >= 0) return byId;
    }

    if (name != null) {
      final needle = name.toLowerCase();
      final byName = pointRows.indexWhere(
        (row) => _text(row['point_name'])?.toLowerCase() == needle,
      );
      if (byName >= 0) return byName;
    }

    return null;
  }

  static String? _text(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }
}
