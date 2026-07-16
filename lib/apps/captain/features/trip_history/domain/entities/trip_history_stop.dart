/// A route station as scheduled for a completed trip — the real, saved
/// `trip_route_points` row, used to render the trip detail's timeline.
class TripHistoryStop {
  const TripHistoryStop({
    required this.name,
    required this.order,
    this.scheduledTime,
  });

  final String name;
  final int order;

  /// The station's scheduled arrival/departure offset (`HH:mm`), if the
  /// route recorded one. Not the trip's actual arrival time — that isn't
  /// tracked per station for a finished trip, only whether it was reported
  /// arrived at all.
  final String? scheduledTime;
}
