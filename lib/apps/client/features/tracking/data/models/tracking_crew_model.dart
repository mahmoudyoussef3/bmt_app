import '../../domain/entities/tracking_crew.dart';

/// Maps the joined `drivers` / `vehicles` rows, including the real service
/// ratings the `trip_reviews` triggers maintain on those tables.
abstract final class TrackingCrewModel {
  static TrackingCaptain captain(Map<String, dynamic>? row) {
    if (row == null) return const TrackingCaptain();
    return TrackingCaptain(
      name: _text(row['full_name']),
      phone: _text(row['phone']),
      rating: (row['rating'] as num?)?.toDouble(),
      ratingCount: (row['rating_count'] as num?)?.toInt() ?? 0,
    );
  }

  static TrackingVehicle vehicle(Map<String, dynamic>? row) {
    if (row == null) return const TrackingVehicle();
    return TrackingVehicle(
      brand: _text(row['brand']),
      model: _text(row['model']),
      type: _text(row['vehicle_type']),
      plate: _text(row['plate_number']),
      rating: (row['rating'] as num?)?.toDouble(),
      ratingCount: (row['rating_count'] as num?)?.toInt() ?? 0,
    );
  }

  static String? _text(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }
}
