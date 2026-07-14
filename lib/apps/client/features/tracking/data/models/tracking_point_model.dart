import '../../domain/entities/tracking_point.dart';

/// Maps a `trip_live_locations` row — the captain's reported GPS fix.
abstract final class TrackingPointModel {
  static TrackingPoint fromRow(Map<String, dynamic> row) {
    return TrackingPoint(
      latitude: (row['latitude'] as num).toDouble(),
      longitude: (row['longitude'] as num).toDouble(),
      recordedAt: _time(row['recorded_at']),
      heading: (row['heading'] as num?)?.toDouble(),
      speed: (row['speed'] as num?)?.toDouble(),
      accuracy: (row['accuracy'] as num?)?.toDouble(),
    );
  }

  /// Null-safe variant for the "latest fix" query, which legitimately returns
  /// no row until the captain's device reports for the first time.
  static TrackingPoint? fromNullableRow(Map<String, dynamic>? row) {
    if (row == null || row['latitude'] == null || row['longitude'] == null) {
      return null;
    }
    return fromRow(row);
  }

  static DateTime? _time(Object? value) =>
      value == null ? null : DateTime.tryParse(value.toString())?.toLocal();
}
