import '../../domain/entities/route_details.dart';
import '../../domain/entities/route_stop.dart';

/// Wire shape of one `operation_routes` row joined with its `public_offices`
/// operator, combined with its separately-fetched `route_stations`.
class RouteDetailsModel extends RouteDetails {
  const RouteDetailsModel({
    required super.id,
    required super.name,
    required super.startCity,
    required super.endCity,
    super.routeCode,
    super.distance,
    super.duration,
    super.status,
    super.officeId,
    super.officeName,
    super.officeLogoUrl,
    super.officeRating,
    super.stops,
  });

  static Map<String, dynamic>? _officeOf(dynamic raw) {
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is List && raw.isNotEmpty && raw.first is Map) {
      return Map<String, dynamic>.from(raw.first as Map);
    }
    return null;
  }

  factory RouteDetailsModel.fromJson(
    Map<String, dynamic> json, {
    required List<RouteStop> stops,
  }) {
    final office = _officeOf(json['office']);
    return RouteDetailsModel(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      startCity: (json['start_city'] as String?) ?? '',
      endCity: (json['end_city'] as String?) ?? '',
      routeCode: (json['route_code'] as String?) ?? '',
      distance: (json['distance'] as String?) ?? '',
      duration: (json['duration'] as String?) ?? '',
      status: (json['status'] as String?) ?? '',
      officeId: (office?['id'] as String?) ?? '',
      officeName: (office?['name'] as String?) ?? '',
      officeLogoUrl: office?['logo_url'] as String?,
      officeRating: (office?['rating'] as num?)?.toDouble() ?? 0,
      stops: stops,
    );
  }
}
