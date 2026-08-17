import '../../domain/entities/live_ops_snapshot.dart';

/// Parses a `trip_live_locations` row into a [LiveFix].
///
/// Extracted so the two paths that produce positions — the backfill RPC and the
/// realtime INSERT stream — cannot come to read the same row differently. They
/// carry identical column names, and the speed unit conversion in particular is
/// the kind of detail that gets fixed in one place and forgotten in the other.
class LiveFixModel {
  const LiveFixModel._();

  /// Returns `null` for any row missing the three fields a position cannot be
  /// drawn without. A malformed row is skipped, never guessed at.
  static LiveFix? fromRow(Map<String, dynamic>? row) {
    if (row == null) return null;

    final lat = (row['latitude'] as num?)?.toDouble();
    final lng = (row['longitude'] as num?)?.toDouble();
    final recordedAt = DateTime.tryParse(row['recorded_at'] as String? ?? '');
    if (lat == null || lng == null || recordedAt == null) return null;

    // The column is metres per second; the desk reads km/h.
    final speedMs = (row['speed'] as num?)?.toDouble();

    return LiveFix(
      latitude: lat,
      longitude: lng,
      recordedAt: recordedAt.toLocal(),
      heading: (row['heading'] as num?)?.toDouble(),
      speedKph: speedMs == null ? null : speedMs * 3.6,
    );
  }
}
