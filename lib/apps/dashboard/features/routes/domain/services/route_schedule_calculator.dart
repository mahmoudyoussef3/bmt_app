import 'package:bmt_app/core/geo/geo_models.dart';

/// Auto-computed arrival/departure offsets for one stop, expressed as "HH:MM"
/// durations from the route's start (route start = 00:00). The actual clock
/// time is resolved per-trip when a departure time is chosen.
class StopSchedule {
  final String arrivalOffset;
  final String departureOffset;

  const StopSchedule({
    required this.arrivalOffset,
    required this.departureOffset,
  });
}

/// Pure, framework-free schedule math. Given the per-leg driving durations from
/// the geo provider and a dwell time per intermediate stop, it derives each
/// stop's arrival/departure offset and formats the route totals.
///
/// Points are ordered [start, stop0, stop1, ..., stopN-1, end]; therefore
/// `legs.length == stops + 1` (a final leg from the last stop to the end).
class RouteScheduleCalculator {
  const RouteScheduleCalculator._();

  static List<StopSchedule> computeStopOffsets({
    required List<RouteLeg> legs,
    required List<int> dwellMinutes,
  }) {
    final stops = dwellMinutes.length;
    final result = <StopSchedule>[];
    var previousDeparture = 0.0;

    for (var i = 0; i < stops; i++) {
      
      final travel = (i > 0 && i - 1 < legs.length)
          ? legs[i - 1].durationSeconds
          : 0;
      final arrival = i == 0 ? 0.0 : previousDeparture + travel;
      final departure = arrival + dwellMinutes[i] * 60;
      result.add(
        StopSchedule(
          arrivalOffset: _hhmm(arrival),
          departureOffset: _hhmm(departure),
        ),
      );
      previousDeparture = departure;
    }
    return result;
  }

  /// e.g. "42 كم" / "8.4 كم".
  static String formatDistance(double meters) {
    final km = meters / 1000;
    return '${km.toStringAsFixed(km < 10 ? 1 : 0)} كم';
  }

  /// e.g. "1 س 10 د" / "45 د".
  static String formatDuration(double seconds) {
    final totalMinutes = (seconds / 60).round();
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    if (h > 0) return '$h س $m د';
    return '$m د';
  }

  static String _hhmm(double seconds) {
    final totalMinutes = (seconds / 60).round();
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }
}
