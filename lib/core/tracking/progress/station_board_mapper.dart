import 'station_board.dart';

/// `trip_station_progress` rows → [StationBoard].
///
/// Shared by the Captain and Client data layers rather than written twice: both
/// read the same table, and both feed the same departure gate. Two mappers that
/// disagree by one field — a dwell parsed as minutes here and seconds there —
/// would put the two apps into different answers to "can the vehicle leave?",
/// which is exactly the disagreement this feature exists to remove.
///
/// Pure Dart: it takes plain maps, so it is testable without Supabase and
/// carries no Flutter dependency.
abstract final class StationBoardMapper {
  static StationBoard fromRows(List<Map<String, dynamic>> rows) {
    final stations = [for (final row in rows) station(row)]
      ..sort((a, b) => a.sequence.compareTo(b.sequence));
    return StationBoard(List.unmodifiable(stations));
  }

  static TripStation station(Map<String, dynamic> row) {
    return TripStation(
      id: row['id']?.toString() ?? '',
      name: (row['point_name'] as String? ?? '').trim(),
      sequence: _int(row['sequence']),
      status: tripStationStatusFrom(row['status']?.toString()),
      routePointId: row['route_point_id']?.toString(),
      expectedArrivalAt: _time(row['expected_arrival_at']),
      expectedDepartureAt: _time(row['expected_departure_at']),
      minDwell: Duration(seconds: _int(row['min_dwell_seconds'])),
      actualArrivalAt: _time(row['actual_arrival_at']),
      actualDepartureAt: _time(row['actual_departure_at']),
      expectedBoardings: _int(row['expected_boardings']),
      boardedCount: _int(row['boarded_count']),
      pendingCount: _int(row['pending_count']),
      noShowCount: _int(row['no_show_count']),
    );
  }

  /// The columns every consumer needs, in one place so a Postgrest select and
  /// this mapper cannot drift apart.
  static const columns =
      'id, trip_id, route_point_id, point_name, sequence, '
      'expected_arrival_at, expected_departure_at, min_dwell_seconds, '
      'actual_arrival_at, actual_departure_at, status, '
      'expected_boardings, boarded_count, pending_count, no_show_count';

  static int _int(Object? value) => switch (value) {
    final int v => v,
    final num v => v.toInt(),
    final String v => int.tryParse(v) ?? 0,
    _ => 0,
  };

  /// Timestamps arrive as UTC ISO-8601 and every surface renders wall-clock, so
  /// they are localised once, here.
  static DateTime? _time(Object? value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString())?.toLocal();
  }
}
