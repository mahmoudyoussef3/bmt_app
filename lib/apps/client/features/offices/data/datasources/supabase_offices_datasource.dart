import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bmt_app/apps/client/core/utils/bookable_trip.dart';
import '../models/office_route_model.dart';
import '../models/office_summary_model.dart';
import '../models/office_trip_model.dart';
import 'offices_datasource.dart';

class SupabaseOfficesDatasource implements OfficesDatasource {
  const SupabaseOfficesDatasource(this._supabase);

  final SupabaseClient _supabase;

  /// `public_offices` already excludes paused/suspended offices and every
  /// private column, so this is a straight read of the marketplace surface.
  /// Best-rated first; unrated newcomers keep a stable alphabetical order.
  @override
  Future<List<OfficeSummaryModel>> fetchOffices() async {
    final rows = await _supabase
        .from('public_offices')
        .select()
        .order('rating', ascending: false)
        .order('name', ascending: true);

    return rows
        .map((row) => OfficeSummaryModel.fromJson(row))
        .toList(growable: false);
  }

  /// Active routes of one office. The marketplace RLS policy on
  /// `operation_routes` already constrains anon/client reads to active routes
  /// of active offices; the filters here mirror it rather than relax it.
  @override
  Future<List<OfficeRouteModel>> fetchOfficeRoutes(String officeId) async {
    final rows = await _supabase
        .from('operation_routes')
        .select('id, name, start_city, end_city')
        .eq('office_id', officeId)
        .eq('status', 'active')
        .order('name', ascending: true);

    return rows
        .map((row) => OfficeRouteModel.fromJson(row))
        .toList(growable: false);
  }

  /// The seats this office is selling right now, soonest first.
  ///
  /// `public_trips` also carries this office's boarding, running and finished
  /// trips — a rider must be able to read a trip they booked while it runs —
  /// but a shop window only lists what is for sale, so this asks for exactly
  /// the status the booking RPC accepts.
  @override
  Future<List<OfficeTripModel>> fetchOfficeTrips(String officeId) async {
    final rows = await _supabase
        .from('public_trips')
        .select('''
          id, route_id, trip_date, departure_time, capacity, booked_seats,
          ticket_price, currency, status,
          route:operation_routes(id, name, start_city, end_city, duration),
          trip_pricing(one_time_price, currency, is_active),
          ${BookableTrip.seatsEmbed}
        ''')
        .eq('office_id', officeId)
        .eq('status', BookableTrip.status)
        .gte('trip_date', BookableTrip.today())
        .order('trip_date', ascending: true)
        .order('departure_time', ascending: true)
        .limit(30);

    return rows
        .where(BookableTrip.isOffered)
        .map((row) => OfficeTripModel.fromJson(row))
        .toList(growable: false);
  }
}
