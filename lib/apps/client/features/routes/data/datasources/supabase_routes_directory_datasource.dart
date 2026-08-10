import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/route_details_model.dart';
import '../models/route_stop_model.dart';
import '../models/route_summary_model.dart';
import 'routes_directory_datasource.dart';

class SupabaseRoutesDirectoryDatasource implements RoutesDirectoryDatasource {
  const SupabaseRoutesDirectoryDatasource(this._supabase);

  final SupabaseClient _supabase;

  /// Every active route, across every active office — the marketplace RLS
  /// policy on `operation_routes` already constrains anon/client reads this
  /// way; the filter here mirrors it rather than relaxes it.
  @override
  Future<List<RouteSummaryModel>> fetchRoutes() async {
    final rows = await _supabase
        .from('operation_routes')
        .select(
          'id, name, start_city, end_city, distance, duration, '
          'office:public_offices(id, name, logo_url)',
        )
        .eq('status', 'active')
        .order('name', ascending: true);

    return rows
        .map((row) => RouteSummaryModel.fromJson(row))
        .toList(growable: false);
  }

  /// One route's full record plus its ordered stops. Two calls rather than a
  /// single embedded query: `route_stations` is ordered independently and
  /// kept as its own model list for the detail screen's timeline.
  @override
  Future<RouteDetailsModel> fetchRouteDetails(String routeId) async {
    final route = await _supabase
        .from('operation_routes')
        .select('*, office:public_offices(*)')
        .eq('id', routeId)
        .eq('status', 'active')
        .single();

    final stationRows = await _supabase
        .from('route_stations')
        .select()
        .eq('route_id', routeId)
        .order('sort_order', ascending: true);

    final stops = stationRows
        .map((row) => RouteStopModel.fromJson(row))
        .toList(growable: false);

    return RouteDetailsModel.fromJson(route, stops: stops);
  }
}
