import '../../domain/entities/route_summary.dart';
import 'route_stop_model.dart';

/// Wire shape of an `operation_routes` row joined with its `public_offices`
/// operator, as read for the routes catalog list.
class RouteSummaryModel extends RouteSummary {
  const RouteSummaryModel({
    required super.id,
    required super.name,
    required super.startCity,
    required super.endCity,
    super.distance,
    super.duration,
    super.officeId,
    super.officeName,
    super.officeLogoUrl,
    super.stops,
  });

  /// Supabase returns an embedded to-one relation as a `Map`, but older
  /// query shapes can still come back as a single-element `List` — handled
  /// the same way `SupabaseBookingSearchDatasource._officeOf` does.
  static Map<String, dynamic>? _officeOf(dynamic raw) {
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is List && raw.isNotEmpty && raw.first is Map) {
      return Map<String, dynamic>.from(raw.first as Map);
    }
    return null;
  }

  /// The embedded `route_stations` rows, in running order.
  ///
  /// Sorted here rather than by the query so a route whose stations come back
  /// unordered — or with holes in `sort_order` — still reads as a corridor.
  /// Unnamed rows are dropped: they can match nothing and would only take a
  /// slot at the ends of the list, where "terminal stop" is decided.
  static List<RouteStopModel> _stopsOf(dynamic raw) {
    if (raw is! List) return const [];
    final stops =
        raw
            .whereType<Map>()
            .map(
              (row) => RouteStopModel.fromJson(Map<String, dynamic>.from(row)),
            )
            .where((stop) => stop.name.trim().isNotEmpty)
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));
    return List.unmodifiable(stops);
  }

  factory RouteSummaryModel.fromJson(Map<String, dynamic> json) {
    final office = _officeOf(json['office']);
    return RouteSummaryModel(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      startCity: (json['start_city'] as String?) ?? '',
      endCity: (json['end_city'] as String?) ?? '',
      distance: (json['distance'] as String?) ?? '',
      duration: (json['duration'] as String?) ?? '',
      officeId: (office?['id'] as String?) ?? '',
      officeName: (office?['name'] as String?) ?? '',
      officeLogoUrl: office?['logo_url'] as String?,
      stops: _stopsOf(json['stops']),
    );
  }
}
