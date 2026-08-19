import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bmt_app/apps/client/core/utils/bookable_trip.dart';

import '../../domain/entities/route_availability.dart';
import '../models/route_availability_model.dart';
import '../models/route_details_model.dart';
import '../models/route_stop_model.dart';
import '../models/route_summary_model.dart';
import 'routes_directory_datasource.dart';

class SupabaseRoutesDirectoryDatasource implements RoutesDirectoryDatasource {
  const SupabaseRoutesDirectoryDatasource(this._supabase);

  final SupabaseClient _supabase;

  /// Ceiling on the departures read to work out which corridors are selling.
  ///
  /// The catalog needs an aggregate per route, not a timetable, and the rows
  /// are ordered soonest-first — so a marketplace that ever outgrows this cap
  /// loses only its most distant departures, on corridors that almost always
  /// have a nearer one already counted here.
  static const int _maxUpcomingTrips = 400;

  /// Every active route, across every active office — the marketplace RLS
  /// policy on `operation_routes` already constrains anon/client reads this
  /// way; the filter here mirrors it rather than relaxes it.
  ///
  /// Each row carries its stations' names, embedded the same way
  /// `SupabaseBookingSearchDatasource.getPopularRoutes` embeds them. That is
  /// what lets the catalog answer "which routes pass through Banha?" without a
  /// query per keystroke: the whole corridor list is a few dozen rows, and the
  /// station names are the only extra columns it costs.
  @override
  Future<List<RouteSummaryModel>> fetchRoutes() async {
    final rows = await _supabase
        .from('operation_routes')
        .select(
          'id, name, start_city, end_city, distance, duration, '
          'stops:route_stations(id, name, sort_order), '
          'office:public_offices(id, name, logo_url)',
        )
        .eq('status', 'active')
        .order('name', ascending: true);

    final routeIds = rows
        .map((row) => row['id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
    final availability = await _availabilityByRouteId(routeIds);

    return rows
        .map((row) {
          final id = row['id']?.toString() ?? '';
          return RouteSummaryModel.fromJson(
            row,
            availability: availability == null
                ? RouteAvailability.unknown
                : availability[id] ?? RouteAvailability.none,
          );
        })
        .toList(growable: false);
  }

  /// The booking outlook per route, or `null` when departures could not be
  /// read at all.
  ///
  /// A corridor absent from the returned map has nothing on sale; the null
  /// return is the different answer — the catalog itself loaded, so it is still
  /// worth showing, but no card may claim anything about availability. That is
  /// why this swallows its error instead of failing the whole screen.
  Future<Map<String, RouteAvailability>?> _availabilityByRouteId(
    List<String> routeIds,
  ) async {
    if (routeIds.isEmpty) return const {};

    final List<Map<String, dynamic>> rows;
    try {
      rows = await _supabase
          .from('public_trips')
          .select(
            'route_id, trip_date, departure_time, status, capacity, '
            'booked_seats, ${BookableTrip.seatsEmbed}',
          )
          .inFilter('route_id', routeIds)
          .eq('status', BookableTrip.status)
          .gte('trip_date', BookableTrip.today())
          .order('trip_date', ascending: true)
          .order('departure_time', ascending: true)
          .limit(_maxUpcomingTrips);
    } catch (_) {
      return null;
    }

    return RouteAvailabilityModel.byRouteId(rows);
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
